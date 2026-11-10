---
name: pagerduty-api
description: Query and manage PagerDuty — find out who's on call, list and manage incidents, read escalation policies and schedules, trace who got paged and why, acknowledge/resolve/snooze/escalate incidents, and create or update services. Use this whenever the user mentions PagerDuty, on-call, paging, escalation, an incident ID like `PXXXXXX` or `Q...`, asks "who's on call", "page the on-call", "ack this incident", "why wasn't I paged", or pastes a pagerduty.com URL — even if they don't say "API". Always start from this skill when interacting with this service — its bundled scripts and recipes are the fastest path.
---

PagerDuty exposes two distinct APIs:

- **REST API** at `https://api.pagerduty.com` — read/manage everything (incidents, on-call,
  schedules, escalation policies, services, users, log entries).
- **Events API v2** at `https://events.pagerduty.com` — trigger/acknowledge/resolve alerts
  programmatically. Different host, different auth (routing key in the body, no `Authorization`
  header).

Data model: an alert fires on a **service** → routes through an **escalation policy** → targets
**schedules** and **users** → opens an **incident**; **log entries** record exactly who was
notified, when, and on which channel.

## Request setup

Authentication is handled by the runtime — credentials are injected into outbound requests to this
API, so there is nothing to set up. Do not try to create, mint, refresh, or validate tokens or keys.
Credential variables exist only to keep requests well-formed; if one is **unset**, give it any
placeholder value. Never overwrite a variable that is already set: a real token in the environment
must be used as-is, so assign a default only when the variable is empty (`${VAR:=placeholder}`),
never with a plain `export VAR=placeholder`. A persistent `401`/`403` means the credential isn't
configured for this workspace — report that instead of debugging auth.

**REST API** (`api.pagerduty.com`) — header on every request is `Authorization: Token token=<t>`
(neither Bearer nor Basic):

```bash
: "${PAGERDUTY_TOKEN:=placeholder}"   # injected by the runtime; only defaults when unset
```

**Events API v2** (`events.pagerduty.com`) — addressed by an integration **routing key** (32 hex
chars) in the request **body**. No `Authorization` header.

```bash
: "${PD_ROUTING_KEY:=placeholder}"   # injected by the runtime; only defaults when unset
```

**Sanity check** — confirm the workspace is wired up:

```bash
curl -sS -w '\nHTTP %{http_code}\n' "https://api.pagerduty.com/users/me" \
  -H "Authorization: Token token=${PAGERDUTY_TOKEN}" \
  -H "Content-Type: application/json"
```

`200` → wired up; pipe through `jq '.user | {id, name, email}'`. `401`/`403` → credential not
configured (the body is often **empty**, which is why the status code is printed). `/users/me` works
only on user tokens; account-level tokens can verify with `/abilities`.

Helper used below (optional):

```bash
pagerduty() { curl -sS -g "$@" -H "Authorization: Token token=${PAGERDUTY_TOKEN}" \
  -H "Accept: application/vnd.pagerduty+json;version=2" -H "Content-Type: application/json"; }
```

The `-g` matters: PagerDuty's array params use brackets (`statuses[]=triggered`), which older curl
glob-expands and fails on — see Pagination.

**Response codes & bodies** — applies to every recipe below:

- REST mutations: `200` update, `201` create. **`401` returns an empty body** — when a write looks
  like it silently did nothing, check the HTTP status (`-w '%{http_code}'`).
- Events v2 enqueue: `202` accepted; a bad routing key is `400` with a **plain-text** body
  `Invalid routing key` (not JSON — don't pipe to `jq`).
- Any reference to another object in a request body needs the form
  `{"id": "<id>", "type": "<x>_reference"}` — omitting `type` is a `400`.

## Core operations

### 1. Who's on call (`scripts/pd_oncall.sh`)

Answer "who is on call" through the bundled script (path is relative to this skill's directory):
it resolves service and user names to ids, queries `/oncalls` with the bracketed array filters,
pages on `offset`/`limit` while `more` is true, and emits TSV or JSONL.

```bash
scripts/pd_oncall.sh --service checkout --earliest
scripts/pd_oncall.sh --user alice@example.com --at 2026-06-01T09:00:00Z --json
```

- `--service NAME|ID` scopes to one service. A value matching `^P[A-Z0-9]{5,7}$` is used as the
  id; anything else is looked up via `/services?query=`. The service's escalation policy is then
  passed as `escalation_policy_ids[]` — `/oncalls` has no service filter of its own.
- `--policy ID` / `--schedule ID` filter directly (repeatable). `--user QUERY` resolves a name or
  email via `/users?query=` to `user_ids[]` (repeatable). Name lookups (here and `--service`) must
  match exactly one result — pass the id for reliability.
- `--at TIME` asks who is on call at an ISO-8601 instant (sets both `since` and `until`);
  `--earliest` returns only the next-up entry per policy.
- `--limit N` caps total entries (default 100, `0` = everything); `--page-size N` sets the per-page
  size (max 100). `--json` emits one JSON object per entry instead of TSV with header
  `level, user, policy, schedule, until`. Resolved ids and counts go to stderr. Instance specifics
  come from `PAGERDUTY_TOKEN` above.
- Exit codes: `0` success, `1` request failed, API error, or bad arguments — the API's own
  `error.code`/`error.message` is on stderr (a `401` body is empty, so the HTTP status is printed
  instead).

If the script errors, read it — it's plain `curl` + `jq` — and debug against `references/api.md`.

### 2. List open incidents

```bash
pagerduty "https://api.pagerduty.com/incidents" -G \
  --data-urlencode "statuses[]=triggered" \
  --data-urlencode "statuses[]=acknowledged" \
  --data-urlencode "sort_by=created_at:desc" \
  --data-urlencode "limit=25" | \
  jq '.incidents[]? | {id, incident_number, title, status, urgency, service: .service.summary, created_at}'
```

Time-scope with `since=`/`until=` (ISO-8601); filter with `service_ids[]=`, `team_ids[]=`,
`urgencies[]=high`.

### 3. Get one incident

```bash
pagerduty "https://api.pagerduty.com/incidents/<incident_id>" | \
  jq '.incident | {id, title, status, urgency, assignments, escalation_policy: .escalation_policy.summary}'
```

`<incident_id>` is the alphanumeric ID (`P...`/`Q...`), **not** `incident_number`. To look up by
number, list with `date_range=all` and filter client-side.

### 4. Who actually got paged? (log entries)

```bash
pagerduty "https://api.pagerduty.com/incidents/<incident_id>/log_entries" -G \
  --data-urlencode "is_overview=false" | \
  jq '.log_entries[]? | {type, at: .created_at, summary, channel: .channel.type}'
```

`type` values of interest: `trigger_log_entry`, `notify_log_entry` (who was paged, which channel),
`acknowledge_log_entry`, `escalate_log_entry`, `assign_log_entry`, `resolve_log_entry`. Pair with
`/users/<id>/notification_rules` to understand why a channel was (or wasn't) used.

### 5. Acknowledge / resolve / escalate / snooze / note

All incident mutations require a `From:` header containing the email of a real PagerDuty user in the
account — it attributes the action in the audit log. Missing or unknown email → `400`.

```bash
pagerduty -X PUT "https://api.pagerduty.com/incidents/<incident_id>" \
  -H "From: me@example.com" \
  -d '{"incident": {"type": "incident_reference", "status": "acknowledged"}}'
```

- **Acknowledge** — `PUT /incidents/<id>`: `{"incident":{"type":"incident_reference","status":"acknowledged"}}`
- **Resolve** — `PUT /incidents/<id>`: `{"incident":{"type":"incident_reference","status":"resolved"}}`
- **Escalate to level N** — `PUT /incidents/<id>`: `{"incident":{"type":"incident_reference","escalation_level":N}}`
- **Snooze** — `POST /incidents/<id>/snooze`: `{"duration": <seconds>}`
- **Add note** — `POST /incidents/<id>/notes`: `{"note":{"content":"..."}}`

### 6. Trace routing: service → escalation policy → schedule

```bash
# service → which policy
pagerduty "https://api.pagerduty.com/services/<service_id>?include[]=escalation_policies" | \
  jq '.service | {name, escalation_policy}'

# policy → ordered rules and targets
pagerduty "https://api.pagerduty.com/escalation_policies/<policy_id>" | \
  jq '.escalation_policy.escalation_rules[]? | {delay_min: .escalation_delay_in_minutes, targets: [.targets[]? | {type, summary}]}'

# schedule → rendered rotation for the next week (after overrides/layers)
# GNU date; on BSD/macOS use: date -u -v+7d +%Y-%m-%dT%H:%M:%SZ
pagerduty "https://api.pagerduty.com/schedules/<schedule_id>" -G \
  --data-urlencode "since=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --data-urlencode "until=$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)" | \
  jq '.schedule.final_schedule.rendered_schedule_entries[]? | {start, end, user: .user.summary}'
```

Most list endpoints take `query=` for substring name match, e.g.
`GET /schedules?query=platform` → `jq '.schedules[]? | {id, name}'`.

### 7. Create an incident

```bash
pagerduty -X POST "https://api.pagerduty.com/incidents" \
  -H "From: me@example.com" \
  -d '{
    "incident": {
      "type": "incident",
      "title": "Payment gateway returning 500s",
      "urgency": "high",
      "service": {"id": "<service_id>", "type": "service_reference"},
      "body": {"type": "incident_body", "details": "Seeing 40% error rate since 14:00 UTC."}
    }
  }'
```

Success is `201` — read `.incident.id` for follow-up calls (it's `null` on an error envelope;
check the status before reusing it).

### 8. Trigger an alert via Events API v2

```bash
curl -sS -X POST "https://events.pagerduty.com/v2/enqueue" \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "'"${PD_ROUTING_KEY}"'",
    "event_action": "trigger",
    "dedup_key": "db-latency-prod-us-east",
    "payload": {
      "summary": "DB p99 latency > 500ms in prod us-east",
      "source": "prometheus:db_latency_p99",
      "severity": "critical",
      "custom_details": {"value_ms": 612}
    }
  }'
```

`event_action` ∈ `trigger` / `acknowledge` / `resolve` — send a later event with the same
`dedup_key` to close the loop. `202` returns `{"status":"success","dedup_key":"..."}`; keep the
`dedup_key` if PagerDuty generated it. Malformed payloads return `400` JSON with `errors[]`.

## Pagination

Classic offset/limit: `limit` (default 25, max 100) and `offset` (default 0); page while the
response has `more: true`, incrementing `offset` by `limit`. **`offset + limit` is capped at
10,000** — narrow the time window or filters past that. Exceptions: `/audit/records` returns
`next_cursor` (pass back as `cursor=`); `/analytics/raw/...` takes `starting_after` in the POST body
(set to the previous response's `last`).

**curl globbing trap.** Array params use bracket syntax — `statuses[]=`, `service_ids[]=`,
`team_ids[]=`, `include[]=`. Older curl treats `[` `]` as glob characters and errors with
`curl: (3) bad range`; modern curl sends them literally. Always pass `-g`/`--globoff` (the helper
does) or percent-encode the brackets via `-G --data-urlencode 'statuses[]=...'` to be safe.

## Rate limits

REST API: **960 requests/minute per token** (a user's keys share one budget). Responses carry
`ratelimit-limit`, `ratelimit-remaining`, `ratelimit-reset` (**seconds** until reset). On `429`
(`{"error":{"message":"Rate Limit Exceeded","code":2020}}`) sleep `ratelimit-reset` seconds and
retry. Some endpoints add tighter per-operation limits; the headers reflect whichever is closest.
`/oncalls` and `/schedules/{id}` are relatively expensive — cache results if reused.

Events API v2 has a **separate budget**, ~120 events/minute per routing key. On `429`, back off and
retry ~30s apart.

## Error handling

Error bodies: `{"error": {"message": "...", "code": N, "errors": ["field X is ..."]}}`.

- **`400`** — Bad request. Read `error.errors[]` — names the bad field. Common: missing `From:` on a mutation, missing `type` on a reference object, bad ISO-8601 timestamp.
- **`401`** — Credential rejected. **Body is empty** — print the status. Header must be `Authorization: Token token=...`. If it persists, the credential isn't configured — report it.
- **`403`** — Forbidden. Read-only credential mutating, or scoped to a team that doesn't own the resource.
- **`404`** — Not found. IDs are short alphanumerics (`P...`/`Q...`), not names or `incident_number`.
- **`429`** — Rate limited. Sleep `ratelimit-reset` seconds, retry.

## Going deeper

`references/api.md` has the full endpoint catalog — incidents (alerts, merges, responder requests,
priorities), services and integrations, escalation policies, schedules and overrides, users and
notification/contact methods, teams, maintenance windows, business services, event orchestration,
analytics, and the full Events API v2 payload shape. Read it when you need an endpoint beyond the
ones above.
