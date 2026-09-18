#!/usr/bin/env bash
# Copyright 2026 Anthropic PBC
# SPDX-License-Identifier: Apache-2.0
# create or safely update a confluence cloud page over the v2 rest api with curl + jq.
# handles the read-modify-write cycle that trips up ad-hoc curl: resolves the space key to its
# numeric id, reads the current version before every update, bumps version.number, sends ids as
# json strings, builds the body with jq (no hand-escaped xhtml), and retries once on a 409
# version race. generic to any confluence cloud site — everything instance-specific is env/flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  write_page.sh --page ID    [--title T] [mode] [body] [--message M]   # update an existing page
  write_page.sh --space KEY  --title T [--parent ID] [body]            # create a new page

body (storage xhtml by default; one of):
  --body-file PATH           read the body from PATH
  (stdin)                    read the body from stdin when --body-file is not given

mode (update only; default is replace):
  --replace                  overwrite the page body with the supplied body (default)
  --append                   append the supplied body after the current body (storage only)
  --prepend                  prepend the supplied body before the current body (storage only)

options:
  --page ID                  numeric id of an existing page to update
  --space KEY                space key (e.g. ENG) to create a new page in — resolved to its id
  --title TITLE              page title (required with --space; optional override with --page)
  --parent ID                numeric id of the parent page (create only; omit for space homepage)
  --representation FMT       body representation: storage (default) or atlas_doc_format
  --message MSG              version message recorded on the new revision (update only)
  -h, --help                 show this help

environment:
  CONFLUENCE_BASE      required, ends in /wiki: https://YOURSITE.atlassian.net/wiki, or the gateway
                       https://api.atlassian.com/ex/confluence/<cloud-id>/wiki for service accounts
  ATLASSIAN_EMAIL      auth user placeholder; the runtime injects real credentials
  ATLASSIAN_API_TOKEN  auth token placeholder; the runtime injects real credentials
  CONFLUENCE_BODY_DIR  directory --body-file must live under; defaults to $TMPDIR or /tmp

output:
  one json object on stdout: {id, version, url}. diagnostics and api errors go to stderr.

exit codes:
  0 success    1 request refused, api error, or 409 after one retry
EOF
}

err() { printf '%s\n' "$*" >&2; }

command -v curl >/dev/null || { err "curl is required"; exit 1; }
command -v jq >/dev/null || { err "jq is required"; exit 1; }

BASE="${CONFLUENCE_BASE:-}"
EMAIL="${ATLASSIAN_EMAIL:-placeholder}"
TOKEN="${ATLASSIAN_API_TOKEN:-placeholder}"

PAGE_ID=""
SPACE_KEY=""
TITLE=""
PARENT_ID=""
BODY_FILE=""
REPR="storage"
MODE="replace"
MESSAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --page)
      PAGE_ID="${2:-}"; shift 2
      case "$PAGE_ID" in ''|*[!0-9]*) err "--page needs a numeric id"; exit 1 ;; esac ;;
    --space)
      SPACE_KEY="${2:-}"; shift 2
      [ -n "$SPACE_KEY" ] || { err "--space needs a space key"; exit 1; } ;;
    --title)
      TITLE="${2:-}"; shift 2
      [ -n "$TITLE" ] || { err "--title needs a value"; exit 1; } ;;
    --parent)
      PARENT_ID="${2:-}"; shift 2
      case "$PARENT_ID" in ''|*[!0-9]*) err "--parent needs a numeric id"; exit 1 ;; esac ;;
    --body-file)
      BODY_FILE="${2:-}"; shift 2
      [ -r "$BODY_FILE" ] || { err "--body-file '$BODY_FILE' is not readable"; exit 1; }
      REAL_BODY_PATH="$(realpath -- "$BODY_FILE" 2>/dev/null)" \
        || { err "--body-file: cannot resolve path '$BODY_FILE'"; exit 1; }
      ALLOWED_DIR="${CONFLUENCE_BODY_DIR:-${TMPDIR:-/tmp}}"
      ALLOWED_DIR="${ALLOWED_DIR%/}"
      case "$REAL_BODY_PATH" in
        "${ALLOWED_DIR}/"*) ;;
        *) err "--body-file must be within \$CONFLUENCE_BODY_DIR (${ALLOWED_DIR})"; exit 1 ;;
      esac
      BODY_FILE="$REAL_BODY_PATH" ;;
    --representation)
      REPR="${2:-}"; shift 2
      case "$REPR" in storage|atlas_doc_format) ;; *)
        err "--representation must be storage or atlas_doc_format"; exit 1 ;; esac ;;
    --append) MODE="append"; shift ;;
    --prepend) MODE="prepend"; shift ;;
    --replace) MODE="replace"; shift ;;
    --message) MESSAGE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1 (see --help)"; exit 1 ;;
    *) err "unexpected argument: $1 (see --help)"; exit 1 ;;
  esac
done

[ -n "$BASE" ] || { err "set CONFLUENCE_BASE (https://YOURSITE.atlassian.net/wiki or https://api.atlassian.com/ex/confluence/<cloud-id>/wiki)"; exit 1; }
BASE="${BASE%/}"

if [ -n "$PAGE_ID" ] && [ -n "$SPACE_KEY" ]; then
  err "pass exactly one of --page (update) or --space (create), not both"; exit 1
fi
if [ -z "$PAGE_ID" ] && [ -z "$SPACE_KEY" ]; then
  err "pass --page ID to update or --space KEY to create (see --help)"; exit 1
fi
if [ -n "$SPACE_KEY" ] && [ -z "$TITLE" ]; then
  err "--space requires --title"; exit 1
fi
if [ -n "$SPACE_KEY" ] && [ "$MODE" != "replace" ]; then
  err "--append/--prepend only apply when updating (--page)"; exit 1
fi
if [ "$MODE" != "replace" ] && [ "$REPR" != "storage" ]; then
  err "--append/--prepend only work with --representation storage"; exit 1
fi

# read the supplied body once; jq --arg handles all xhtml/json escaping
if [ -n "$BODY_FILE" ]; then
  NEW_BODY="$(cat -- "$BODY_FILE")"
elif [ ! -t 0 ]; then
  NEW_BODY="$(cat)"
else
  err "no body supplied (use --body-file or pipe it on stdin)"; exit 1
fi
[ -n "${NEW_BODY//[[:space:]]/}" ] || { err "body is empty"; exit 1; }

# cf_req METHOD URL [JSON_BODY] — sets RESP_BODY and RESP_CODE
cf_req() {
  local method="$1" url="$2" data="${3:-}" out
  if [ -n "$data" ]; then
    out="$(curl -sS --max-time 60 -u "${EMAIL}:${TOKEN}" \
      -H "Accept: application/json" -H "Content-Type: application/json" \
      -X "$method" "$url" --data-binary "$data" -w '\n%{http_code}')"
  else
    out="$(curl -sS --max-time 60 -u "${EMAIL}:${TOKEN}" \
      -H "Accept: application/json" \
      -X "$method" "$url" -w '\n%{http_code}')"
  fi
  RESP_CODE="${out##*$'\n'}"
  RESP_BODY="${out%$'\n'*}"
}

# print the api's own error detail (v2 envelope, with a v1/plain fallback) to stderr
cf_print_error() {
  if jq -e . >/dev/null 2>&1 <<<"$RESP_BODY"; then
    jq -r --arg c "$RESP_CODE" \
      '"confluence \($c): " +
       ( .errors[0].detail? // .errors[0].title?
         // .message? // (. | tostring) )' <<<"$RESP_BODY" >&2
  else
    err "confluence ${RESP_CODE}:"
    printf '%s\n' "$RESP_BODY" | head -c 1000 >&2
  fi
}

# build the absolute browser url from _links: v2 webui is relative to _links.base (the /wiki root)
emit_result() {
  jq -c --arg base "$BASE" \
    '{id, version: .version.number,
      url: ((._links.base // $base) + (._links.webui // ""))}' <<<"$RESP_BODY"
}

# ---- create ----------------------------------------------------------------------------------
if [ -n "$SPACE_KEY" ]; then
  cf_req GET "${BASE}/api/v2/spaces?keys=$(jq -rn --arg s "$SPACE_KEY" '$s|@uri')&limit=1"
  if [ "$RESP_CODE" -ge 300 ]; then cf_print_error; exit 1; fi
  SPACE_ID="$(jq -r '.results[0].id // empty' <<<"$RESP_BODY")"
  [ -n "$SPACE_ID" ] || { err "space key '${SPACE_KEY}' not found (or not visible)"; exit 1; }
  err "space ${SPACE_KEY} -> id ${SPACE_ID}"

  REQ="$(jq -cn --arg space "$SPACE_ID" --arg title "$TITLE" --arg parent "$PARENT_ID" \
    --arg repr "$REPR" --arg body "$NEW_BODY" \
    '{spaceId: $space, status: "current", title: $title,
      body: {representation: $repr, value: $body}}
     + (if $parent != "" then {parentId: $parent} else {} end)')"

  cf_req POST "${BASE}/api/v2/pages" "$REQ"
  if [ "$RESP_CODE" -ge 300 ]; then
    if [ "$RESP_CODE" = "400" ] && grep -qi 'title already exists' <<<"$RESP_BODY"; then
      err "400 on create — a page titled '${TITLE}' already exists in this space"
    fi
    cf_print_error; exit 1
  fi
  err "created page $(jq -r '.id // "?"' <<<"$RESP_BODY") (version 1)"
  emit_result
  exit 0
fi

# ---- update ----------------------------------------------------------------------------------
# read_current — populate CUR_VER, CUR_TITLE and (when appending/prepending) CUR_BODY
read_current() {
  local url="${BASE}/api/v2/pages/${PAGE_ID}"
  if [ "$MODE" != "replace" ]; then url="${url}?body-format=storage"; fi
  cf_req GET "$url"
  if [ "$RESP_CODE" -ge 300 ]; then
    err "could not read page ${PAGE_ID} before writing"; cf_print_error; exit 1
  fi
  CUR_VER="$(jq -r '.version.number // empty' <<<"$RESP_BODY")"
  CUR_TITLE="$(jq -r '.title // empty' <<<"$RESP_BODY")"
  CUR_BODY="$(jq -r '.body.storage.value // ""' <<<"$RESP_BODY")"
  if [ -z "$CUR_VER" ] || [ -z "$CUR_TITLE" ]; then
    err "page ${PAGE_ID}: read came back without a version/title — refusing to write"; exit 1
  fi
}

ATTEMPT=1
while :; do
  read_current
  NEXT_VER=$(( CUR_VER + 1 ))
  USE_TITLE="${TITLE:-$CUR_TITLE}"
  err "page ${PAGE_ID}: '${CUR_TITLE}' at v${CUR_VER} -> v${NEXT_VER} (${MODE}, attempt ${ATTEMPT})"

  REQ="$(jq -cn --arg id "$PAGE_ID" --arg title "$USE_TITLE" --argjson ver "$NEXT_VER" \
    --arg msg "$MESSAGE" --arg repr "$REPR" --arg new "$NEW_BODY" --arg cur "$CUR_BODY" \
    --arg mode "$MODE" \
    '{id: $id, status: "current", title: $title,
      version: ({number: $ver} + (if $msg != "" then {message: $msg} else {} end)),
      body: {representation: $repr,
             value: (if $mode == "append" then ($cur + $new)
                     elif $mode == "prepend" then ($new + $cur)
                     else $new end)}}')"

  cf_req PUT "${BASE}/api/v2/pages/${PAGE_ID}" "$REQ"
  if [ "$RESP_CODE" -lt 300 ]; then break; fi
  if [ "$RESP_CODE" = "409" ] && [ "$ATTEMPT" -lt 2 ]; then
    err "409 conflict (version race) — re-reading and retrying once"
    ATTEMPT=2
    continue
  fi
  cf_print_error; exit 1
done

err "updated page ${PAGE_ID} to version $(jq -r '.version.number // "?"' <<<"$RESP_BODY")"
emit_result
