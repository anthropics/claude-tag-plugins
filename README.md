# claude-tag-plugins

Plugins for [@claude](https://claude.ai) that connect the agent to common SaaS services.
Each service is its own plugin, so a workspace can connect exactly the services it uses.

## Plugins

| Plugin | What it covers |
|--------|----------------|
| **[asana](./asana)** | Tasks, projects, sections, comments; list, search, create/update |
| **[bigquery](./bigquery)** | Run SQL, list datasets/tables, fetch schemas, manage jobs |
| **[claude-tag-data-viz](./claude-tag-data-viz)** | Compose polished charts from tabular data — PNG, SVG, or self-contained interactive HTML |
| **[claude-tag-oncall](./claude-tag-oncall)** | Oncall for @Claude in Slack — alert triage, incident investigation, sitreps, postmortems, rotation handoff |
| **[claude-tag-troubleshoot](./claude-tag-troubleshoot)** | Configure and debug @Claude agents — agent scopes, profiles, connections, plugin/skill loading |
| **[confluence](./confluence)** | Search pages, read/create/update content, spaces, comments |
| **[datadog](./datadog)** | Logs, metrics, monitors, dashboards, SLOs, events, traces, incidents |
| **[enterprise-search](./enterprise-search)** | Search across all connected sources, read documents, submit relevance feedback |
| **[google-drive](./google-drive)** | Search, read, upload, share files; folders; Docs/Sheets export |
| **[grafana](./grafana)** | Dashboards, datasource queries, alerting, annotations, folders |
| **[hubspot](./hubspot)** | Contacts, companies, deals, tickets; CRM search; associations |
| **[jira](./jira)** | Search with JQL, create/transition issues, comments, sprints |
| **[linear](./linear)** | Issues, projects, cycles, teams |
| **[notion](./notion)** | Search, pages, databases, blocks, block children |
| **[pagerduty](./pagerduty)** | Incidents, who's on-call, schedules, escalation policies, services |
| **[redshift](./redshift)** | Run SQL, poll results, list schemas/tables |
| **[salesforce](./salesforce)** | Query records, CRUD objects, describe schema, composite requests |
| **[sentry](./sentry)** | Issues, events, projects, releases, stats |
| **[snowflake](./snowflake)** | Run SQL statements, poll/fetch results, warehouses |

## Getting Started

### Claude Tag

```bash
# Add the marketplace first
claude plugin marketplace add anthropics/claude-tag-plugins

# Install the services you use
claude plugin install jira@claude-tag-plugins
claude plugin install datadog@claude-tag-plugins
```

Once installed, skills activate automatically when relevant.

## How It Works

Each service plugin follows the same structure:

```
<service>/
├── .claude-plugin/plugin.json   # Manifest
└── skills/<service>-api/
    ├── SKILL.md                 # How to connect and core operations
    ├── references/              # Full endpoint catalog, read on demand
    └── scripts/                 # Executable helpers (where present)
```

The two helper plugins use the same `skills/<name>/` layout but carry different
content: [`claude-tag-data-viz`](./claude-tag-data-viz) ships a Python charting
kit instead of curl scripts, and [`claude-tag-troubleshoot`](./claude-tag-troubleshoot)
ships a slash command plus two documentation-only skills.

## Authentication

Plugins contain **no auth setup instructions** — authentication is handled by the runtime.
Credentials are injected into outbound requests; the environment variables each plugin
references (`$DD_API_KEY`, `$ATLASSIAN_API_TOKEN`, `$BQ_TOKEN`, ...) exist only to keep requests
well-formed and may hold placeholder values.

## Security Considerations

The bundled scripts reference credentials only through placeholder environment variables; the
runtime injects the real credentials into each request. When run **outside** the
credential-injecting runtime (e.g. local development or CI without secrets configured), the
token variable will be unset or hold a placeholder — requests will be rejected with `401`.
Never commit real credentials; configure them through your runtime's secret injection
mechanism. To report a security vulnerability, see [SECURITY.md](./SECURITY.md).

## Maintenance Status

Active — maintained by Anthropic. Bug reports and PRs are welcome; see
[CONTRIBUTING.md](./CONTRIBUTING.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](./LICENSE).

The `claude-tag-data-viz` plugin bundles third-party JavaScript libraries (React, ReactDOM, react-is, Recharts) under their original MIT licenses. See [NOTICE](./NOTICE) for full attribution and license text.
