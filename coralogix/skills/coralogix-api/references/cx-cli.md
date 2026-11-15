# CX CLI reference

The Coralogix plugin uses the official `cx` CLI. This reference summarizes the read-only command
families useful to Claude Tag. Use `cx schema` and the installed command's `--help` output as the
source of truth for the version available in the runtime.

## Profile and output rules

The Claude Tag runtime, not a Slack user, owns the configured `cx` profile. The profile contains
the regional Coralogix connection and credentials. Do not run interactive setup or switch profiles
inside a conversation.

Use `-o toon` for agent-facing results. It emits compact structured output and can spill oversized
results to a temporary file. When output reports a result-file path, read that file before
summarizing the query.

## Logs and spans

| Command | Purpose | Important options |
|---|---|---|
| `cx logs QUERY` | Query logs with DataPrime syntax; `source logs` is implicit. | `--start`, `--end`, `--limit`, `--tier`, `-o toon` |
| `cx spans QUERY` | Query distributed spans; `source spans` is implicit. | `--start`, `--end`, `--limit`, `--tier`, `-o toon` |
| `cx dataprime query QUERY` | Run a raw DataPrime query. | `--source logs|spans`, `--start`, `--end`, `--limit`, `--tier`, `-o toon` |
| `cx search-fields QUERY` | Find fields by description or value. | `--dataset logs|spans|all`, `--search-type semantic|value`, `--limit`, `--offset` |

Use a blank expression for the most recent raw records:

```bash
cx logs '' --limit 5 -o toon
```

For a time window, use `now`, relative expressions such as `now-6h`, or ISO-8601 UTC timestamps.
`cx logs`, `cx spans`, and `cx dataprime query` default to `now-1h` through `now`.

## Metrics

| Command | Purpose |
|---|---|
| `cx metrics query PROMQL` | Run an instant PromQL query. |
| `cx metrics query-range PROMQL` | Run a range PromQL query with bounded start, end, and step. |
| `cx metrics search QUERY` | Discover available metric names. |
| `cx metrics get-labels` | Discover labels before composing a PromQL selector. |

Use a bounded range and a sensible step to avoid flooding the conversation:

```bash
cx metrics query-range 'rate(http_requests_total[5m])' \
  --start now-1h --end now --step 60s -o toon
```

## Other read-only discovery

The CLI also exposes read-only commands for dashboards, alerts, cases, documentation, and more.
Use `cx schema` before calling them, because command names and flags are versioned with the CLI.
Favor list, get, search, show, and describe operations.

The plugin is intentionally read-only. Do not invoke mutating command variants or pass `--yes`,
even when the user asks for a change, unless a separately approved plugin capability is added.

## Failures

- **CLI missing** — the Claude Tag runtime must install the `cx` binary.
- **No profile or authentication failure** — the runtime administrator must configure a Coralogix
  profile and its read-only credential.
- **Region failure** — the configured profile targets the wrong Coralogix region.
- **Query timeout or truncation** — narrow the time interval, add filters, lower the limit, or
  aggregate.

Never replace a CLI failure with raw HTTP calls; preserving the CLI boundary is intentional.
