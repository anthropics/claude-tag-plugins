#!/usr/bin/env bash
# Run a bounded Coralogix DataPrime query and emit its JSON Lines response.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: cx_dataprime.sh QUERY --from ISO-8601 --to ISO-8601 [--limit N] [--tier TIER_ARCHIVE]

QUERY must start with a DataPrime source, such as "source logs", "source spans",
or "source rum.events". Output is JSON Lines from the DataPrime API.
EOF
  exit 2
}

query=${1:-}
[[ -n "${query}" ]] || usage
shift

from=
to=
limit=100
tier=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) from=${2:-}; shift 2 ;;
    --to) to=${2:-}; shift 2 ;;
    --limit) limit=${2:-}; shift 2 ;;
    --tier) tier=${2:-}; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

[[ -n "${from}" && -n "${to}" ]] || usage
[[ "${limit}" =~ ^[1-9][0-9]*$ ]] || { echo "--limit must be a positive integer" >&2; exit 2; }
[[ "${query}" =~ ^source[[:space:]] ]] || {
  echo "QUERY must start with a DataPrime source" >&2
  exit 2
}

: "${CX_API:?Set CX_API to the regional Coralogix API base URL}"
: "${CX_API_KEY:?Set CX_API_KEY (the runtime normally injects its value)}"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 127; }

metadata=$(jq -cn \
  --arg startDate "${from}" \
  --arg endDate "${to}" \
  --argjson limit "${limit}" \
  '{syntax: "QUERY_SYNTAX_DATAPRIME", startDate: $startDate, endDate: $endDate, limit: $limit}')
if [[ -n "${tier}" ]]; then
  metadata=$(jq -c --arg tier "${tier}" '. + {tier: $tier}' <<<"${metadata}")
fi
payload=$(jq -cn --arg query "${query}" --argjson metadata "${metadata}" \
  '{query: $query, metadata: $metadata}')

response=$(mktemp)
trap 'rm -f "${response}"' EXIT
if ! curl -sS --fail-with-body -X POST "${CX_API%/}/api/v1/dataprime/query" \
  -H "Authorization: Bearer ${CX_API_KEY}" \
  -H "Content-Type: application/json" \
  --data "${payload}" >"${response}"; then
  cat "${response}" >&2
  exit 1
fi

# DataPrime responds with newline-delimited JSON. Validate every non-empty line without changing it.
while IFS= read -r line || [[ -n "${line}" ]]; do
  [[ -z "${line}" ]] && continue
  jq -ce . <<<"${line}"
done <"${response}"
