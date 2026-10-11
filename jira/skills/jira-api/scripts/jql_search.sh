#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0
# run a jira cloud jql search end-to-end with curl + jq: post to /rest/api/3/search/jql (the old
# /search is 410), always send an explicit fields list (the endpoint defaults to id only), follow
# nextPageToken through every page, surface the {errorMessages,errors} envelope, and emit tsv or
# jsonl. generic to any jira cloud site — everything instance-specific comes from env vars or
# flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  jql_search.sh [options] "project = PROJ AND ..."   # jql as a single quoted argument
  echo "project = PROJ ..." | jql_search.sh [opts]   # jql on stdin

  the jql must be bounded (at least one filter clause); a bare ORDER BY ... -> 400 from the api.

options:
  --fields LIST    comma-separated fields to request (default: summary,status,assignee,updated).
                   always sent — /search/jql returns id only when fields is omitted.
  --limit N        stop after N issues total (default 100; 0 = fetch everything)
  --page-size N    issues per request page (default 50; the api clamps per field count)
  --json           emit one json object per issue (jsonl) instead of tsv
  -h, --help       show this help

environment:
  JIRA_BASE            base url (required): site root https://your-domain.atlassian.net, or the
                       gateway https://api.atlassian.com/ex/jira/<cloud-id> for service accounts
  ATLASSIAN_EMAIL      auth user placeholder; the runtime injects real credentials
  ATLASSIAN_API_TOKEN  auth token placeholder; the runtime injects real credentials

output:
  issues on stdout — tsv with header (key, summary, status, assignee, updated) by default, or the
  raw issue object per line with --json. the tsv columns are fixed; --json emits the full issue
  object, so custom --fields selections are visible there. there is no total count from this
  endpoint; the fetched count and any truncation warning go to stderr.

exit codes:
  0 success    1 request failed, api error, or bad arguments
EOF
}

err() { printf '%s\n' "$*" >&2; }

command -v curl >/dev/null || { err "curl is required"; exit 1; }
command -v jq >/dev/null || { err "jq is required"; exit 1; }

BASE="${JIRA_BASE:-}"
EMAIL="${ATLASSIAN_EMAIL:-placeholder}"
TOKEN="${ATLASSIAN_API_TOKEN:-placeholder}"
FIELDS="summary,status,assignee,updated"
LIMIT=100
PAGE_SIZE=50
FORMAT=tsv
JQL=""

# require_int FLAG VALUE — flags that take a count must get a non-negative integer
require_int() {
  case "$2" in
    ''|*[!0-9]*) err "$1 needs a non-negative integer, got '${2:-nothing}'"; exit 1 ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fields)
      if [ -z "${2:-}" ]; then err "--fields needs a comma-separated list"; exit 1; fi
      FIELDS="$2"; shift 2 ;;
    --limit) require_int --limit "${2:-}"; LIMIT="$2"; shift 2 ;;
    --page-size)
      require_int --page-size "${2:-}"
      if [ "$2" -lt 1 ]; then err "--page-size must be at least 1"; exit 1; fi
      PAGE_SIZE="$2"; shift 2 ;;
    --json) FORMAT=json; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1 (see --help)"; exit 1 ;;
    *)
      if [ -n "$JQL" ]; then
        err "unexpected extra argument: $1 (pass the jql as one quoted string)"; exit 1
      fi
      JQL="$1"; shift ;;
  esac
done

if [ -z "$JQL" ]; then
  if [ -t 0 ]; then err "no jql given (pass it as an argument or on stdin; see --help)"; exit 1; fi
  JQL="$(cat)"
fi
if [ -z "${JQL//[[:space:]]/}" ]; then err "no jql given"; exit 1; fi
if [ -z "$BASE" ]; then
  err "set JIRA_BASE (e.g. https://your-domain.atlassian.net or https://api.atlassian.com/ex/jira/<cloud-id>)"; exit 1
fi
BASE="${BASE%/}"

FIELDS_JSON="$(jq -cn --arg f "$FIELDS" \
  '$f | split(",") | map(gsub("^ +| +$"; "")) | map(select(. != ""))')"
if [ "$(jq 'length' <<<"$FIELDS_JSON")" = "0" ]; then
  err "--fields resolved to an empty list"; exit 1
fi

jira_api() {
  curl -sS --max-time 60 -u "${EMAIL}:${TOKEN}" \
    -H "Accept: application/json" -H "Content-Type: application/json" "$@"
}

# exit with the api's own message if the response is an error envelope (or not json at all)
jira_check_error() {
  if ! jq -e . >/dev/null 2>&1 <<<"$1"; then
    err "non-json response from the api:"
    printf '%s\n' "$1" | head -c 2000 >&2
    exit 1
  fi
  if [ "$(jq -r 'type == "object" and (has("issues") | not)
                 and (has("errorMessages") or has("errors"))' <<<"$1")" = "true" ]; then
    jq -r '"jira error: " +
      ( ((.errorMessages // [])
         + ((.errors // {}) | to_entries | map("\(.key): \(.value)"))
        ) | if length > 0 then join("; ") else "unknown error" end )' <<<"$1" >&2
    exit 1
  fi
}

# build a request body; nextPageToken is only sent when non-empty
jira_body() {
  jq -cn --arg jql "$JQL" --argjson fields "$FIELDS_JSON" \
    --argjson max "$PAGE_SIZE" --arg tok "$1" \
    '{jql: $jql, fields: $fields, maxResults: $max}
     + (if $tok != "" then {nextPageToken: $tok} else {} end)'
}

# tsv cell rule: null -> "", nested -> json, else string
read -r -d '' CELL <<'JQ' || true
def cell: if . == null then "" elif type=="object" or type=="array" then tojson else tostring end;
JQ

print_page() {
  if [ "$FORMAT" = "tsv" ]; then
    jq -r --argjson take "$2" "$CELL"'
      .issues[:$take][]
      | [ .key,
          (.fields.summary | cell),
          (.fields.status.name | cell),
          (.fields.assignee.displayName | cell),
          (.fields.updated | cell) ]
      | @tsv' <<<"$1"
  else
    jq -c --argjson take "$2" '.issues[:$take][]' <<<"$1"
  fi
}

URL="${BASE}/rest/api/3/search/jql"
TOKEN_NEXT=""
FETCHED=0
HEADER_DONE=0

while :; do
  PAGE="$(jira_api -X POST "$URL" -d "$(jira_body "$TOKEN_NEXT")")"
  jira_check_error "$PAGE"

  # defer the tsv header until the first request has succeeded so failed runs emit nothing on stdout
  if [ "$FORMAT" = "tsv" ] && [ "$HEADER_DONE" = "0" ]; then
    printf 'key\tsummary\tstatus\tassignee\tupdated\n'; HEADER_DONE=1
  fi

  COUNT="$(jq -r '.issues | length' <<<"$PAGE")"
  TAKE="$COUNT"
  if [ "$LIMIT" -gt 0 ]; then
    REMAINING=$(( LIMIT - FETCHED ))
    if [ "$COUNT" -gt "$REMAINING" ]; then TAKE="$REMAINING"; fi
  fi
  if [ "$TAKE" -gt 0 ]; then print_page "$PAGE" "$TAKE"; fi
  FETCHED=$(( FETCHED + TAKE ))

  IS_LAST="$(jq -r '.isLast // false' <<<"$PAGE")"
  TOKEN_NEXT="$(jq -r '.nextPageToken // empty' <<<"$PAGE")"

  if [ "$LIMIT" -gt 0 ] && [ "$FETCHED" -ge "$LIMIT" ]; then
    if [ "$IS_LAST" != "true" ] || [ "$COUNT" -gt "$TAKE" ]; then
      err "output truncated at ${FETCHED} issues (raise --limit, or 0 for everything)"
    fi
    break
  fi
  if [ "$IS_LAST" = "true" ] || [ -z "$TOKEN_NEXT" ]; then break; fi
done

err "fetched ${FETCHED} issue(s)"
