#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0
# run a snowflake sql statement end-to-end with curl + jq: submit, poll the handle until the
# statement finishes, walk every result partition, and emit the string-encoded cells as tsv or
# jsonl. generic to any snowflake account — everything instance-specific comes from env vars or
# flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  snow_query.sh [options] "SELECT ..."           # sql as a single quoted argument
  echo "SELECT ..." | snow_query.sh [options]    # sql on stdin

options:
  --warehouse NAME     warehouse to run on (required for anything that scans data)
  --database NAME      session database
  --schema NAME        session schema
  --role NAME          session role
  --bind TYPE:VALUE    bind a positional ? placeholder, repeatable. TYPE is a snowflake binding
                       type (TEXT, FIXED, REAL, BOOLEAN, DATE, TIMESTAMP_NTZ, ...). bindings are
                       applied in the order given: first --bind -> first ?, second -> second ?.
                       example: --bind TEXT:CA --bind FIXED:100
  --timeout SECONDS    cancel the statement if it runs longer than this (default 300; 0 = max)
  --max-wait SECONDS   give up polling after this long (default 600)
  --max-rows N         stop fetching after N rows (default 10000; 0 = fetch everything)
  --tag STRING         set QUERY_TAG on the statement for auditing
  --json               emit one json object per row (jsonl) instead of tsv
  -h, --help           show this help

environment:
  SNOWFLAKE_ACCOUNT     account identifier, e.g. xy12345.us-east-1 (required unless
                        SNOWFLAKE_BASE_URL is set)
  SNOWFLAKE_TOKEN       bearer token; injected by the runtime, so the placeholder default is fine
  SNOWFLAKE_TOKEN_TYPE  X-Snowflake-Authorization-Token-Type header (default
                        PROGRAMMATIC_ACCESS_TOKEN; set to OAUTH for OAuth tokens)
  SNOWFLAKE_BASE_URL    api root override (default https://<account>.snowflakecomputing.com)

output:
  rows on stdout — tsv with a header row by default, jsonl with --json. cells are the api's raw
  string encodings (date = days since epoch, timestamp = epoch seconds with 9-decimal fraction,
  variant/array/object = json string). statement handle, row counts, and the api's own error
  message go to stderr.

exit codes:
  0 success    1 request or statement failed    2 timed out polling (handle printed on stderr)
EOF
}

err() { printf '%s\n' "$*" >&2; }

command -v curl >/dev/null || { err "curl is required"; exit 1; }
command -v jq >/dev/null || { err "jq is required"; exit 1; }

ACCOUNT="${SNOWFLAKE_ACCOUNT:-}"
BASE_URL="${SNOWFLAKE_BASE_URL:-}"
if [ -z "$BASE_URL" ] && [ -n "$ACCOUNT" ]; then
  BASE_URL="https://${ACCOUNT}.snowflakecomputing.com"
fi
TOKEN="${SNOWFLAKE_TOKEN:-placeholder}"
TOKEN_TYPE="${SNOWFLAKE_TOKEN_TYPE:-PROGRAMMATIC_ACCESS_TOKEN}"

WAREHOUSE=""
DATABASE=""
SCHEMA=""
ROLE=""
TIMEOUT=300
MAX_WAIT=600
MAX_ROWS=10000
QUERY_TAG=""
FORMAT=tsv
BINDINGS='{}'
BIND_IDX=0
SQL=""

# require_int FLAG VALUE — flags that take a count must get a non-negative integer
require_int() {
  case "$2" in
    ''|*[!0-9]*) err "$1 needs a non-negative integer, got '${2:-nothing}'"; exit 1 ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --warehouse) WAREHOUSE="${2:-}"; shift 2 ;;
    --database) DATABASE="${2:-}"; shift 2 ;;
    --schema) SCHEMA="${2:-}"; shift 2 ;;
    --role) ROLE="${2:-}"; shift 2 ;;
    --bind)
      SPEC="${2:-}"
      BTYPE="${SPEC%%:*}"
      BVALUE="${SPEC#*:}"
      if [ -z "$BTYPE" ] || [ "$BTYPE" = "$SPEC" ]; then
        err "bad --bind '$SPEC' (expected TYPE:VALUE, e.g. TEXT:CA)"; exit 1
      fi
      BIND_IDX=$(( BIND_IDX + 1 ))
      BTYPE="$(printf '%s' "$BTYPE" | tr '[:lower:]' '[:upper:]')"
      BINDINGS="$(jq -c --arg k "$BIND_IDX" --arg t "$BTYPE" --arg v "$BVALUE" \
        '. + {($k): {type: $t, value: $v}}' <<<"$BINDINGS")"
      shift 2 ;;
    --timeout) require_int --timeout "${2:-}"; TIMEOUT="$2"; shift 2 ;;
    --max-wait) require_int --max-wait "${2:-}"; MAX_WAIT="$2"; shift 2 ;;
    --max-rows) require_int --max-rows "${2:-}"; MAX_ROWS="$2"; shift 2 ;;
    --tag) QUERY_TAG="${2:-}"; shift 2 ;;
    --json) FORMAT=json; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1 (see --help)"; exit 1 ;;
    *)
      if [ -n "$SQL" ]; then
        err "unexpected extra argument: $1 (pass the sql as one quoted string)"; exit 1
      fi
      SQL="$1"; shift ;;
  esac
done

if [ -z "$SQL" ]; then
  if [ -t 0 ]; then err "no sql given (pass it as an argument or on stdin; see --help)"; exit 1; fi
  SQL="$(cat)"
fi
if [ -z "${SQL//[[:space:]]/}" ]; then err "no sql given"; exit 1; fi
if [ -z "$BASE_URL" ]; then
  err "set SNOWFLAKE_ACCOUNT (e.g. xy12345.us-east-1) or SNOWFLAKE_BASE_URL"; exit 1
fi

sf_api() {
  curl -sS --compressed --max-time 120 \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-Snowflake-Authorization-Token-Type: ${TOKEN_TYPE}" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "User-Agent: snow-query/1.0" \
    "$@"
}

# fail if $1 isn't valid json (echo the raw body for debugging)
sf_require_json() {
  if ! jq -e . >/dev/null 2>&1 <<<"$1"; then
    err "non-json response from the api:"
    printf '%s\n' "$1" | head -c 2000 >&2
    exit 1
  fi
}

BODY="$(jq -cn \
  --arg sql "$SQL" \
  --argjson timeout "$TIMEOUT" \
  --arg wh "$WAREHOUSE" --arg db "$DATABASE" --arg sc "$SCHEMA" --arg role "$ROLE" \
  --arg tag "$QUERY_TAG" \
  --argjson bindings "$BINDINGS" \
  '{statement: $sql, timeout: $timeout}
   + (if $wh   != "" then {warehouse: $wh} else {} end)
   + (if $db   != "" then {database: $db} else {} end)
   + (if $sc   != "" then {schema: $sc} else {} end)
   + (if $role != "" then {role: $role} else {} end)
   + (if ($bindings | length) > 0 then {bindings: $bindings} else {} end)
   + (if $tag  != "" then {parameters: {QUERY_TAG: $tag}} else {} end)')"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

CODE="$(sf_api -o "$TMP" -w '%{http_code}' -X POST "${BASE_URL}/api/v2/statements" -d "$BODY")"
RESP="$(cat "$TMP")"
sf_require_json "$RESP"
HANDLE="$(jq -r '.statementHandle // empty' <<<"$RESP")"
if [ -n "$HANDLE" ]; then err "handle: ${HANDLE}"; fi

# poll until the statement leaves the running state
DEADLINE=$(( $(date +%s) + MAX_WAIT ))
while [ "$CODE" = "202" ]; do
  if [ -z "$HANDLE" ]; then
    err "got 202 but no statement handle — cannot poll"; exit 1
  fi
  if [ "$(date +%s)" -ge "$DEADLINE" ]; then
    err "gave up after ${MAX_WAIT}s; statement ${HANDLE} is still running"
    err "poll it later: GET ${BASE_URL}/api/v2/statements/${HANDLE}"
    err "or cancel it:  POST ${BASE_URL}/api/v2/statements/${HANDLE}/cancel"
    exit 2
  fi
  sleep 2
  CODE="$(sf_api -o "$TMP" -w '%{http_code}' "${BASE_URL}/api/v2/statements/${HANDLE}")"
  RESP="$(cat "$TMP")"
  # 429 -> back off and keep polling; anything else non-202 falls through to the status check
  if [ "$CODE" = "429" ]; then sleep 5; CODE="202"; continue; fi
  sf_require_json "$RESP"
done

if [ "$CODE" != "200" ]; then
  jq -r '"snowflake error \(.code // "?") (sqlState \(.sqlState // "?")): " +
    (.message // "unknown error")' <<<"$RESP" >&2
  err "(http ${CODE})"
  exit 1
fi

NUM_ROWS="$(jq -r '.resultSetMetaData.numRows // 0' <<<"$RESP")"
NPART="$(jq -r '.resultSetMetaData.partitionInfo // [] | length' <<<"$RESP")"
NUM_COLS="$(jq -r '.resultSetMetaData.rowType // [] | length' <<<"$RESP")"
err "done: ${NUM_ROWS} rows across ${NPART} partition(s)"

# statements with no result schema (ddl, dml without RETURNING) — report and stop
if [ "$NUM_COLS" = "0" ]; then
  jq -r '"statement ok: \(.message // "no result rows")"' <<<"$RESP" >&2
  exit 0
fi

COLS="$(jq -c '[.resultSetMetaData.rowType[].name]' <<<"$RESP")"
if [ "$FORMAT" = "tsv" ]; then jq -r '. | @tsv' <<<"$COLS"; fi

# print up to $2 rows from page $1; cells are already strings in the api, nulls -> "" for tsv
print_page() {
  if [ "$FORMAT" = "tsv" ]; then
    jq -r --argjson take "$2" \
      '[.data[]?][:$take][] | map(if . == null then "" else . end) | @tsv' <<<"$1"
  else
    jq -c --argjson take "$2" --argjson cols "$COLS" \
      '[.data[]?][:$take][] | [$cols, .] | transpose | map({(.[0]): .[1]}) | add' <<<"$1"
  fi
}

FETCHED=0
PART=0
PAGE="$RESP"

while :; do
  COUNT="$(jq -r '[.data[]?] | length' <<<"$PAGE")"
  TAKE="$COUNT"
  if [ "$MAX_ROWS" -gt 0 ]; then
    REMAINING=$(( MAX_ROWS - FETCHED ))
    if [ "$COUNT" -gt "$REMAINING" ]; then TAKE="$REMAINING"; fi
  fi
  if [ "$TAKE" -gt 0 ]; then print_page "$PAGE" "$TAKE"; fi
  FETCHED=$(( FETCHED + TAKE ))

  if [ "$MAX_ROWS" -gt 0 ] && [ "$FETCHED" -ge "$MAX_ROWS" ]; then
    if [ "$FETCHED" -lt "$NUM_ROWS" ]; then
      err "output truncated at ${FETCHED} of ${NUM_ROWS} rows (raise --max-rows, or 0 for all)"
    fi
    break
  fi
  PART=$(( PART + 1 ))
  if [ "$PART" -ge "$NPART" ]; then break; fi
  # fetch the next partition; back off on 429, fail loudly on anything else non-200
  TRIES=0
  while :; do
    CODE="$(sf_api -o "$TMP" -w '%{http_code}' \
      "${BASE_URL}/api/v2/statements/${HANDLE}?partition=${PART}")"
    PAGE="$(cat "$TMP")"
    if [ "$CODE" = "429" ] && [ "$TRIES" -lt 5 ]; then
      TRIES=$(( TRIES + 1 )); sleep 5; continue
    fi
    break
  done
  sf_require_json "$PAGE"
  if [ "$CODE" != "200" ]; then
    jq -r '"snowflake error \(.code // "?") (sqlState \(.sqlState // "?")): " +
      (.message // "unknown error")' <<<"$PAGE" >&2
    err "(http ${CODE} fetching partition ${PART})"
    exit 1
  fi
done

err "fetched ${FETCHED} of ${NUM_ROWS} rows"
