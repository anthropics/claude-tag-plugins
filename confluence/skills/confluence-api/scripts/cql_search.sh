#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0
# run a confluence cql search over the v1 rest api with curl + jq (v2 has no search): submit with
# curl -G --data-urlencode and expand=space,version so the projection columns are populated, follow
# _links.next through every page (v1 next is /wiki-root-relative — prepend CONFLUENCE_BASE as-is),
# surface the v1 {statusCode,message} error envelope, and emit tsv or jsonl. generic to any
# confluence cloud site — everything instance-specific comes from env vars or flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  cql_search.sh [options] 'type = page AND text ~ "term"'   # cql as a single quoted argument
  echo 'CQL...' | cql_search.sh [options]                   # cql on stdin

options:
  --space KEY      scope the query to one space (wraps the cql as: space = KEY AND (CQL))
  --limit N        stop after N total results (default 100; 0 = fetch everything)
  --page-size N    results per api page, max 250 (default 50)
  --json           emit one json object per result (jsonl) instead of tsv
  -h, --help       show this help

environment:
  CONFLUENCE_BASE      required, ends in /wiki: https://YOURSITE.atlassian.net/wiki, or the gateway
                       https://api.atlassian.com/ex/confluence/<cloud-id>/wiki for service accounts
  ATLASSIAN_EMAIL      auth user placeholder; the runtime injects real credentials
  ATLASSIAN_API_TOKEN  auth token placeholder; the runtime injects real credentials

output:
  results on stdout — tsv with header (id, title, space, updated, url) by default, jsonl with
  --json. url is the result's _links.webui path (relative to CONFLUENCE_BASE). result count and
  any truncation warning go to stderr.

exit codes:
  0 success    1 request failed, api error, or bad arguments
EOF
}

err() { printf '%s\n' "$*" >&2; }

command -v curl >/dev/null || { err "curl is required"; exit 1; }
command -v jq >/dev/null || { err "jq is required"; exit 1; }

BASE="${CONFLUENCE_BASE:-}"
EMAIL="${ATLASSIAN_EMAIL:-placeholder}"
TOKEN="${ATLASSIAN_API_TOKEN:-placeholder}"
SPACE=""
LIMIT=100
PAGE_SIZE=50
FORMAT=tsv
CQL=""

# require_int FLAG VALUE — flags that take a count must get a non-negative integer
require_int() {
  case "$2" in
    ''|*[!0-9]*) err "$1 needs a non-negative integer, got '${2:-nothing}'"; exit 1 ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --space)
      if [ -z "${2:-}" ]; then err "--space needs a space key"; exit 1; fi
      case "$2" in
        *[!A-Za-z0-9_-]*) err "--space key contains invalid characters (alphanumeric, _ and - only)"; exit 1 ;;
      esac
      SPACE="$2"; shift 2 ;;
    --limit) require_int --limit "${2:-}"; LIMIT="$2"; shift 2 ;;
    --page-size)
      require_int --page-size "${2:-}"
      if [ "$2" -lt 1 ] || [ "$2" -gt 250 ]; then err "--page-size must be 1..250"; exit 1; fi
      PAGE_SIZE="$2"; shift 2 ;;
    --json) FORMAT=json; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1 (see --help)"; exit 1 ;;
    *)
      if [ -n "$CQL" ]; then
        err "unexpected extra argument: $1 (pass the cql as one quoted string)"; exit 1
      fi
      CQL="$1"; shift ;;
  esac
done

if [ -z "$CQL" ]; then
  if [ -t 0 ]; then err "no cql given (pass it as an argument or on stdin; see --help)"; exit 1; fi
  CQL="$(cat)"
fi
if [ -z "${CQL//[[:space:]]/}" ]; then err "no cql given"; exit 1; fi
[ -n "$BASE" ] || { err "set CONFLUENCE_BASE (https://YOURSITE.atlassian.net/wiki or https://api.atlassian.com/ex/confluence/<cloud-id>/wiki)"; exit 1; }
BASE="${BASE%/}"

if [ -n "$SPACE" ]; then CQL="space = ${SPACE} AND (${CQL})"; fi

cf_api() {
  curl -sS --max-time 60 -u "${EMAIL}:${TOKEN}" -H "Accept: application/json" "$@"
}

# exit with the api's own message if the response is a v1 error envelope (or not json at all)
cf_check_error() {
  if ! jq -e . >/dev/null 2>&1 <<<"$1"; then
    err "non-json response from the api:"
    printf '%s\n' "$1" | head -c 2000 >&2
    exit 1
  fi
  if [ "$(jq -r 'type == "object" and has("statusCode")' <<<"$1")" = "true" ]; then
    jq -r '"confluence error \(.statusCode // ""): \(.message // "unknown error")"' <<<"$1" >&2
    exit 1
  fi
}

# print up to $2 results from page $1 in the chosen format
print_page() {
  if [ "$FORMAT" = "tsv" ]; then
    jq -r --argjson take "$2" '
      .results[:$take][]?
      | [ (.id // ""), (.title // ""), (.space.key // ""),
          (.version.when // ""), (._links.webui // "") ]
      | @tsv' <<<"$1"
  else
    jq -c --argjson take "$2" '
      .results[:$take][]?
      | {id, title, space: .space.key, updated: .version.when, url: ._links.webui}' <<<"$1"
  fi
}

if [ "$FORMAT" = "tsv" ]; then printf 'id\ttitle\tspace\tupdated\turl\n'; fi

PAGE="$(cf_api -G "${BASE}/rest/api/content/search" \
  --data-urlencode "cql=${CQL}" \
  --data-urlencode "limit=${PAGE_SIZE}" \
  --data-urlencode "expand=space,version")"
cf_check_error "$PAGE"

FETCHED=0

while :; do
  COUNT="$(jq -r '.results | length' <<<"$PAGE")"
  TAKE="$COUNT"
  if [ "$LIMIT" -gt 0 ]; then
    REMAINING=$(( LIMIT - FETCHED ))
    if [ "$COUNT" -gt "$REMAINING" ]; then TAKE="$REMAINING"; fi
  fi
  if [ "$TAKE" -gt 0 ]; then print_page "$PAGE" "$TAKE"; fi
  FETCHED=$(( FETCHED + TAKE ))

  NEXT="$(jq -r '._links.next // empty' <<<"$PAGE")"
  if [ "$LIMIT" -gt 0 ] && [ "$FETCHED" -ge "$LIMIT" ]; then
    if [ -n "$NEXT" ] || [ "$COUNT" -gt "$TAKE" ]; then
      err "output truncated at ${FETCHED} results (raise --limit, or 0 for everything)"
    fi
    break
  fi
  if [ -z "$NEXT" ]; then break; fi
  # v1 _links.next is relative to the /wiki root — prepend CONFLUENCE_BASE as-is.
  # require a leading / so a compromised response can't redirect the bearer token off-host.
  case "$NEXT" in
    /*) ;;
    *) err "refusing to follow non-relative _links.next: $NEXT"; exit 1 ;;
  esac
  PAGE="$(cf_api "${BASE}${NEXT}")"
  cf_check_error "$PAGE"
done

err "fetched ${FETCHED} result(s)"
