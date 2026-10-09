#!/usr/bin/env bash
# Copyright 2026 Adspirer
# SPDX-License-Identifier: Apache-2.0
# call any adspirer tool with curl + jq: post /api/v1/tools/<tool>/execute with the
# {"arguments": {...}} envelope, parse the success/error envelope, and emit .data on
# stdout. one uniform caller for all 341 tools across google, meta, linkedin, tiktok,
# amazon, and chatgpt ads — everything instance-specific comes from env vars or flags.

set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  ads_call.sh [options] TOOL_NAME [JSON_ARGUMENTS]

  executes one Adspirer tool. TOOL_NAME is the exact tool identifier (see
  references/api.md for the catalog); JSON_ARGUMENTS is the arguments object
  (defaults to {}). the request body is wrapped as {"arguments": <JSON_ARGUMENTS>}.

examples:
  ads_call.sh list_connected_accounts
  ads_call.sh get_campaign_performance '{"customer_id":"1234567890","date_range":"LAST_30_DAYS"}'
  ads_call.sh --idempotent create_search_campaign '{"customer_id":"1234567890","campaign_name":"Test","daily_budget":50}'

options:
  --idempotent   send a fresh Idempotency-Key header (use for create/update tools so
                 network retries can't execute the operation twice)
  --raw          emit the full response envelope instead of just .data
  -h, --help     show this help

environment:
  ADSPIRER_API_KEY   bearer credential; injected by the runtime, so the placeholder
                     default is fine (self-hosted: sk_live_... from https://adspirer.ai/keys)
  ADSPIRER_BASE_URL  api root (default https://api.adspirer.ai)

output:
  .data of the success envelope on stdout (or the full envelope with --raw).
  quota status, http code, and error details go to stderr.

exit codes:
  0 success    1 request failed, api error, quota exhausted, or bad arguments
EOF
}

IDEMPOTENT=0
RAW=0
while [ $# -gt 0 ]; do
  case "$1" in
    --idempotent) IDEMPOTENT=1; shift ;;
    --raw) RAW=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "ads_call.sh: unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) break ;;
  esac
done

[ $# -ge 1 ] || { usage >&2; exit 1; }
TOOL="$1"
ARGS="${2:-{\}}"

echo "$ARGS" | jq -e . >/dev/null 2>&1 || { echo "ads_call.sh: JSON_ARGUMENTS is not valid JSON: $ARGS" >&2; exit 1; }

BASE_URL="${ADSPIRER_BASE_URL:-https://api.adspirer.ai}"
API_KEY="${ADSPIRER_API_KEY:-placeholder}"

HEADERS=(-H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json")
if [ "$IDEMPOTENT" = 1 ]; then
  KEY="$(uuidgen 2>/dev/null || od -x /dev/urandom | head -1 | awk '{print $2$3"-"$4"-"$5"-"$6"-"$7$8$9}')"
  HEADERS+=(-H "Idempotency-Key: ${KEY}")
  echo "idempotency-key: ${KEY}" >&2
fi

BODY="$(jq -cn --argjson a "$ARGS" '{arguments: $a}')"

RESPONSE="$(curl -sS -w $'\n%{http_code}' -X POST "${BASE_URL}/api/v1/tools/${TOOL}/execute" \
  "${HEADERS[@]}" -d "$BODY")" || { echo "ads_call.sh: request failed to send" >&2; exit 1; }

HTTP_CODE="$(printf '%s' "$RESPONSE" | tail -1)"
PAYLOAD="$(printf '%s' "$RESPONSE" | sed '$d')"

if [ "$HTTP_CODE" = "200" ]; then
  QUOTA="$(printf '%s' "$PAYLOAD" | jq -r '.data.quota | select(. != null) | "quota: \(.used)/\(.limit) (\(.tier), resets \(.period_end))"' 2>/dev/null || true)"
  [ -n "$QUOTA" ] && echo "$QUOTA" >&2
  if [ "$RAW" = 1 ]; then printf '%s\n' "$PAYLOAD"; else printf '%s' "$PAYLOAD" | jq '.data'; fi
  exit 0
fi

echo "http ${HTTP_CODE}" >&2
printf '%s' "$PAYLOAD" | jq -r '.error // "unrecognized error payload"' >&2
if [ "$HTTP_CODE" = "402" ]; then
  printf '%s' "$PAYLOAD" | jq -r '.quota.upgrade_url | select(. != null) | "upgrade: \(.)"' >&2
fi
exit 1
