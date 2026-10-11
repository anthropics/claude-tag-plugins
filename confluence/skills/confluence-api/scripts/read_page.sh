#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0
# fetch one confluence cloud page over the v2 rest api with curl + jq and print its body to
# stdout — rendered html by default, optionally the storage xhtml source, or a crude sed-based
# plain-text strip. title/status/version/space go to stderr so the body pipes cleanly.
# generic to any confluence site — everything instance-specific comes from env vars or flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  read_page.sh [options] PAGE_ID

  PAGE_ID is the numeric segment in a confluence url (.../pages/12345/Title -> 12345).

options:
  --format FMT   body format to request: view (default), storage, or export_view.
                 view / export_view are rendered html with macros expanded; storage is the raw
                 xhtml source with <ac:...> macro elements. atlas_doc_format is deliberately not
                 offered (its value is a nested json string — fetch it with curl directly).
  --text         strip html tags and decode &amp; &lt; &gt; &quot; &nbsp; with sed for a crude
                 plain-text rendering. meant for --format view / export_view; on storage it will
                 eat the <ac:...> macro markers. cannot combine with --json.
  --json         emit one json object {id,title,status,version,body} on stdout instead of the
                 raw body. cannot combine with --text.
  -h, --help     show this help

environment:
  CONFLUENCE_BASE      required, ends in /wiki: https://YOURSITE.atlassian.net/wiki, or the gateway
                       https://api.atlassian.com/ex/confluence/<cloud-id>/wiki for service accounts
  ATLASSIAN_EMAIL      auth user placeholder; the runtime injects real credentials
  ATLASSIAN_API_TOKEN  auth token placeholder; the runtime injects real credentials

output:
  the page body on stdout (html, or stripped text with --text); with --json a single json object
  instead. title, status, version number, and space id go to stderr.

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
FORMAT="view"
AS_TEXT=false
AS_JSON=false
PAGE_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --format)
      FORMAT="${2:-}"; shift 2
      case "$FORMAT" in view|storage|export_view) ;; *)
        err "--format must be view, storage, or export_view"; exit 1 ;; esac ;;
    --text) AS_TEXT=true; shift ;;
    --json) AS_JSON=true; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1 (see --help)"; exit 1 ;;
    *)
      if [ -n "$PAGE_ID" ]; then err "unexpected extra argument: $1"; exit 1; fi
      PAGE_ID="$1"; shift ;;
  esac
done

[ -n "$BASE" ] || { err "set CONFLUENCE_BASE (https://YOURSITE.atlassian.net/wiki or https://api.atlassian.com/ex/confluence/<cloud-id>/wiki)"; exit 1; }
BASE="${BASE%/}"
case "$PAGE_ID" in
  '') err "no page id given (see --help)"; exit 1 ;;
  *[!0-9]*) err "page id must be numeric, got '${PAGE_ID}'"; exit 1 ;;
esac
if [ "$AS_TEXT" = true ] && [ "$AS_JSON" = true ]; then
  err "--text and --json are mutually exclusive"; exit 1
fi

cf_api() {
  curl -sS --max-time 60 -u "${EMAIL}:${TOKEN}" -H "Accept: application/json" "$@"
}

# exit with the api's own message if the response is a v2 error envelope (or not json at all).
# confluence returns 404 for content you cannot see, not 403 — keep the api wording verbatim.
cf_check_error() {
  if ! jq -e . >/dev/null 2>&1 <<<"$1"; then
    err "non-json response from the api:"
    printf '%s\n' "$1" | head -c 2000 >&2
    exit 1
  fi
  if [ "$(jq -r 'type == "object" and has("errors")' <<<"$1")" = "true" ]; then
    jq -r '.errors[0] | "confluence \(.status // "") \(.code // ""): "
           + (.detail // .title // "unknown error")' <<<"$1" >&2
    exit 1
  fi
}

# page id is validated numeric and format is from a fixed whitelist, so direct interpolation is safe
RESP="$(cf_api "${BASE}/api/v2/pages/${PAGE_ID}?body-format=${FORMAT}")"
cf_check_error "$RESP"

# metadata to stderr so stdout stays the body only
jq -r '"page \(.id): \"\(.title // "")\" (status \(.status // "?"), "
       + "version \(.version.number // "?"), space \(.spaceId // "?"))"' <<<"$RESP" >&2

if [ "$AS_JSON" = true ]; then
  jq -c --arg f "$FORMAT" \
    '{id, title, status, version: .version.number, body: (.body[$f].value // "")}' <<<"$RESP"
  exit 0
fi

BODY="$(jq -r --arg f "$FORMAT" '.body[$f].value // ""' <<<"$RESP")"

if [ "$AS_TEXT" = true ]; then
  # crude html-to-text: turn obvious block boundaries into newlines, drop every remaining tag,
  # then decode the handful of entities that matter. &amp; is last so &amp;lt; stays literal.
  printf '%s\n' "$BODY" | sed -E \
    -e 's:<br */?>:\n:g' \
    -e 's:</(p|div|li|tr|h[1-6])>:\n:g' \
    -e 's:<[^>]*>::g' \
    -e 's/&nbsp;/ /g' -e 's/&quot;/"/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/\&/g'
else
  printf '%s\n' "$BODY"
fi
