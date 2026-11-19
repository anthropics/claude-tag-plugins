# Coralogix HTTP API reference

Use the regional API host for the customer, for example
`https://api.eu2.coralogix.com`. Requests authenticate with:

```text
Authorization: Bearer ${CX_API_KEY}
```

The Claude Tag runtime injects the real credential. Do not create API keys, prompt for a key, or
put a secret in a command or file.

## Contents

- [DataPrime](#dataprime)
- [Metrics](#metrics)
- [Management API](#management-api)
- [Error handling and permissions](#error-handling-and-permissions)
- [Not available as direct REST](#not-available-as-direct-rest)

## DataPrime

`POST ${CX_API}/api/v1/dataprime/query` executes a DataPrime query. It answers in JSON Lines:
individual lines can contain `result`, `warning`, or `error`. Always preserve and report warnings.

```bash
cxapi -X POST "${CX_API}/api/v1/dataprime/query" \
  -H "Content-Type: application/json" \
  --data @- <<'JSON'
{
  "query": "source logs | filter $m.severity == ERROR | limit 50",
  "metadata": {
    "syntax": "QUERY_SYNTAX_DATAPRIME",
    "startDate": "2026-11-19T10:00:00Z",
    "endDate": "2026-11-19T11:00:00Z",
    "limit": 50
  }
}
JSON
```

Supported sources used by this plugin:

| Source | Use for |
|---|---|
| `source logs` | Application, infrastructure, and audit logs |
| `source spans` | APM traces and spans |
| `source rum.events` | Browser and mobile RUM events |

DataPrime queries should contain an explicit `limit` when returning raw records. For summaries,
prefer `count`, `aggregate`, `groupby`, and a final `limit`.

`metadata.startDate` and `metadata.endDate` accept ISO-8601 timestamps. `metadata.limit` bounds
returned rows. The optional archive tier value is `TIER_ARCHIVE`; use it only when the user
specifically needs archive data and the runtime's key has archive-query permission.

## Metrics

The metrics API is Prometheus HTTP API compatible under `${CX_API}/metrics/api/v1`. Coralogix
supports the following endpoint families:

| Endpoint | Purpose |
|---|---|
| `GET/POST /query` | Instant PromQL query |
| `GET/POST /query_range` | Range PromQL query |
| `GET/POST /labels` | Label names, optionally scoped by `match[]` |
| `GET/POST /label/{label}/values` | Values for a label, optionally scoped by `match[]` |
| `GET/POST /series` | Series matching one or more `match[]` selectors |

`/query_range` requires `query`, `start`, `end`, and `step`. Use a bounded range and a step
appropriate to the requested granularity. Prometheus responses have `status`, `data`, and
optionally `error`/`errorType`; do not present an error response as an empty result.

```bash
cxapi -G "${CX_API}/metrics/api/v1/series" \
  --data-urlencode 'match[]={__name__="http_requests_total"}' \
  --data-urlencode 'start=2026-11-19T10:00:00Z' \
  --data-urlencode 'end=2026-11-19T11:00:00Z' | jq '.data'
```

## Management API

The versioned Management API base is `${CX_API}/mgmt/openapi/5`. Its live OpenAPI document,
`${CX_MGMT_API}/openapi.yaml`, is authoritative for each operation's exact request/response schema
and required permission. Read it before calling a management endpoint that is not listed below.

### Stable resource families

| Resource | Base path | Direct operations |
|---|---|---|
| Dashboards | `/dashboards/dashboards/v1` | Catalog/list and dashboard retrieval; see the live schema for create/update/delete |
| Dashboard folders | `/dashboards/folders/v1` | List, create, delete |
| Views | `/data-exploration/views/v1/views` | List, get, create, update, delete |
| View folders | `/data-exploration/views/v1/folders` | List, get, create, update, delete |
| Cases | `/cases` | Case details, comments, assignment, acknowledgement, lifecycle, priority, mute, linked cases, and events |
| Data usage | `/dataplan/data-usage/v1` | Read capabilities and submit bounded usage queries |

Useful direct reads:

```bash
# Dashboard catalog and folders.
cxapi "${CX_MGMT_API}/dashboards/dashboards/v1/catalog/list" | jq .
cxapi "${CX_MGMT_API}/dashboards/folders/v1" | jq .

# Saved views and folders.
cxapi "${CX_MGMT_API}/data-exploration/views/v1/views" | jq .
cxapi "${CX_MGMT_API}/data-exploration/views/v1/folders" | jq .

# Learn the allowed data-usage dimensions before querying.
cxapi "${CX_MGMT_API}/dataplan/data-usage/v1/capabilities" | jq .
```

Profiling uses the `${CX_API}/profiles` REST API with proto3-JSON request bodies. It supports
profiled-service overview and metadata, filter discovery, profile metrics, and flame graphs. These
body schemas are service-specific rather than part of the Management OpenAPI document; use the
published profiling API schema for the installed Coralogix region and do not infer enum values or
body fields.

Infrastructure inventory uses the non-OpenAPI base `${CX_API}/mgmt/api/infrastructure`:

| Endpoint | Purpose |
|---|---|
| `GET /enablement/v1` | Whether infrastructure inventory is available |
| `GET /resources/v1/types` | Resource categories/types |
| `GET /resources/v1/filters` | Available filters |
| `POST /resources/v1` | List a bounded page of matching resources |
| `GET /resources/v1/{encoded-id}/raw-data` | Resource source document |

The live v5 schema also defines alerts, SLOs, parsing rules, enrichments, integrations,
notifications, quotas, recording rules, and AI Center resources such as applications, evaluations,
and model pricing. Their operation paths and schemas evolve; obtain them from `openapi.yaml` at
call time rather than guessing them.

### Mutations

Management API writes are not generally idempotent. Before a write:

1. Confirm that the user explicitly requested the action.
2. Retrieve the current resource if a get/list operation exists.
3. Read the OpenAPI request schema and permissions.
4. For updates, determine whether the endpoint accepts a patch or replaces the full object.
5. Report the result and do not retry a failed request automatically.

Do not create or manage API keys through this plugin, even though the Management API supports it.

## Error handling and permissions

- **400** — The DataPrime or OpenAPI request body is invalid. Surface the server response and
  correct the request shape before retrying.
- **401 / 403** — The runtime credential is missing, has insufficient permissions, or is for a
  different region. Report the failure; do not change credential configuration.
- **404** — Confirm the resource ID and the regional host.
- **429 / 5xx** — Honor a `Retry-After` header when present. Do not retry writes automatically.

Data query, management, and configuration actions require different Coralogix API-key permissions.
Use a least-privileged runtime identity. DataPrime's `DataQuerying` preset and the metrics
`metrics.data-api#high:ReadData` permission cover common query scenarios; management operations
require the specific permissions identified by the live OpenAPI schema.

## Not available as direct REST

The Coralogix MCP server has capabilities that this HTTP plugin does not duplicate:

- semantic field/metric search and service-catalog graph/entity queries use internal gRPC services;
- some alert and SLO read operations use gRPC;
- IaC-MCP proxy features are a separate MCP integration;
- Olly conversations, MCP Apps, and tenant UI rendering are MCP features rather than public REST
  operations.

Use the Coralogix MCP integration when these capabilities are required.
