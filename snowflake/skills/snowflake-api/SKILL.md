---
name: snowflake-api
description: Run SQL against Snowflake — submit statements, poll async handles, fetch result partitions, cancel, and browse warehouses/databases/schemas/tables. Use this whenever the user wants to query Snowflake, ask "what tables are in this schema", check a warehouse's status, or mentions `snowflakecomputing.com`, `/api/v2/statements`, or a Snowflake account identifier (like `xy12345.us-east-1`). Always start from this skill when interacting with this service — its bundled scripts and recipes are the fastest path.
---

Snowflake's SQL API v2 (`/api/v2/statements`) is a thin REST layer for running SQL and fetching results.
POST a SQL string, get back a **statement handle** and either the result (for fast queries) or a
`202 Accepted` to poll. Large results are split into **partitions** you fetch one at a time. There
is no separate "list tables" endpoint — catalog browsing is just SQL (`SHOW TABLES`,
`INFORMATION_SCHEMA`).

## Request setup

Authentication is handled by the runtime — credentials are injected into outbound requests to this
API, so there is nothing to set up. Do not try to create, mint, refresh, or validate tokens or keys.
Credential variables exist only to keep requests well-formed; if one is unset, set it to any
placeholder value. A persistent `401` means the credential isn't configured for this workspace —
report that instead of debugging auth.

The **account identifier** must be real — it's the hostname. It's the part of the Snowflake URL
before `.snowflakecomputing.com` — e.g. `xy12345.us-east-1` or an org-style `myorg-myaccount`.

```bash
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"           # your account identifier — must be real
export SNOWFLAKE_BASE="https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com"
export SNOWFLAKE_TOKEN="placeholder"                   # injected by the runtime; any value works
export SNOWFLAKE_TOKEN_TYPE="${SNOWFLAKE_TOKEN_TYPE:-PROGRAMMATIC_ACCESS_TOKEN}"   # leave as provided by the runtime; the injected credential is a PAT
```

### Helper and sanity check

Every request carries the same headers. Define a helper once:

```bash
snowapi() {
  curl -sS --compressed "$@" \
    -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
    -H "X-Snowflake-Authorization-Token-Type: ${SNOWFLAKE_TOKEN_TYPE}" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -H "User-Agent: curl-sql-api/1.0"
}
```

(`User-Agent` is required — Snowflake rejects requests without one. `--compressed` matters for
result partitions, which come back with `Content-Encoding: gzip`.)

**Sanity check** — confirm the account identifier is right and the workspace is wired up:

```bash
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements" \
  -d '{"statement":"SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE()","timeout":10}' | jq .
# Returns the configured user/role/warehouse on success.
```

## Core operations

### 1. Run a statement (`scripts/snow_query.sh`)

Run SQL through the bundled script (path is relative to this skill's directory): it submits the
statement, polls the handle until it finishes, walks every result partition (gzip handled), and
emits decoded rows. Use it for any single-statement query, `SHOW`, or `DESCRIBE`.

```bash
scripts/snow_query.sh --warehouse MY_WH --bind TEXT:1996-01-01 \
  'SELECT o_orderdate, COUNT(*) n FROM snowflake_sample_data.tpch_sf1.orders
   WHERE o_orderdate >= ? GROUP BY 1 ORDER BY 1 LIMIT 20'
```

- SQL is one quoted argument or stdin. Instance specifics come from `SNOWFLAKE_ACCOUNT` /
  `SNOWFLAKE_TOKEN` / `SNOWFLAKE_TOKEN_TYPE` above (`SNOWFLAKE_BASE_URL` overrides the host).
- `--warehouse` / `--database` / `--schema` / `--role` set the session context (each falls back to
  the user's Snowflake default if omitted); `--tag` sets `QUERY_TAG` for auditing.
- `--bind TYPE:VALUE` (repeatable) binds positional `?` placeholders in order — prefer it over
  splicing values into the SQL string. Types are the binding types in `references/api.md`.
- `--timeout` (default 300 s) is the server-side execution cap — a statement that exceeds it is
  cancelled; `--max-wait` (default 600 s) is how long the script polls before giving up.
- `--max-rows N` caps fetched rows (default 10000, `0` = everything); `--json` emits one JSON object
  per row instead of TSV with a header. Handle, row counts, and errors go to stderr.
- Cells are emitted as the API's raw string encodings (so dates are epoch-days, timestamps are epoch
  seconds — see the gotcha under Error handling).
- Exit codes: `0` success, `1` request or SQL failed (Snowflake's `code`/`sqlState`/`message` on
  stderr), `2` gave up after `--max-wait` while still running — the handle is on stderr; fetch or
  cancel it with the endpoints below.

If the script errors, read it — it's plain `curl` + `jq` — and debug against `references/api.md`.
For multi-statement requests, idempotent `requestId` retries, array bindings, cancel, or fetching
results from a handle you already have, use the endpoints below directly.

### 2. Fetch results from an existing handle

`GET /api/v2/statements/{handle}` — the recovery path after the script's exit-2 timeout, or for any
handle you obtained elsewhere. `202` = still running (poll again with a `sleep`), `200` = done with
partition 0 of the results inline, `422` = the statement failed.

```bash
snowapi "${SNOWFLAKE_BASE}/api/v2/statements/${HANDLE}" -o /tmp/sf.json -w '%{http_code}\n'
jq '{cols: [.resultSetMetaData.rowType[]?.name], parts: .resultSetMetaData.partitionInfo, rows: .data[:5]}' /tmp/sf.json
```

- Columns are in `resultSetMetaData.rowType[]`; rows in `data[]` as arrays of strings (encoding
  table in `references/api.md`, section Result metadata & partitions).
- `resultSetMetaData.partitionInfo[]` lists every partition with its `rowCount`. Fetch the rest with
  `?partition=N` for `N` from 1 to `partitionInfo|length - 1`. Partitions are stable (fetch in
  parallel or out of order), gzip-compressed after the first (the helper's `--compressed` handles
  it), and carry only `data` — no metadata.
- Results are retained for **24 hours** after the statement finishes; past that the handle returns
  `404`.

### 3. Cancel a running statement

```bash
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements/${HANDLE}/cancel" | jq .
```

Cancellation is best-effort. If the statement already finished, this is a no-op.

### 4. Idempotent submits with `requestId`

If a POST might be retried (flaky network, timeout), pass a client-generated UUID as `requestId`. A
retry with the same `requestId` and `retry=true` returns the original statement's handle instead of
running it again.

```bash
RID=$(uuidgen)
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements?requestId=${RID}" -d '{"statement":"INSERT INTO t VALUES (1)","warehouse":"MY_WH"}'
# On timeout, retry:
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements?requestId=${RID}&retry=true" -d '{"statement":"INSERT INTO t VALUES (1)","warehouse":"MY_WH"}'
```

### 5. Run multiple statements in one request

Separate with `;` and set `MULTI_STATEMENT_COUNT` to the exact count (or `0` for "any number").
Returns a parent handle plus per-child handles.

```bash
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements" -d '{
  "statement": "CREATE TEMP TABLE tmp AS SELECT 1 AS x; SELECT * FROM tmp;",
  "warehouse": "MY_WH",
  "parameters": {"MULTI_STATEMENT_COUNT": "2"}
}' | jq '{parent: .statementHandle, children: .statementHandles, msg: .message}'
```

Fetch each child's results via its own handle. `BEGIN`/`COMMIT`/`ROLLBACK`, `USE`, `ALTER SESSION`,
and temporary table/stage creation are only supported *inside* a multi-statement request — as a
single statement they fail with a `422`. Bindings are not supported in multi-statement requests.

### 6. Browse the catalog (databases, schemas, tables, columns)

There are no REST catalog endpoints — use `SHOW`/`DESCRIBE`, which run as ordinary statements. A
failure (no such object, no privilege) comes back as `422` with `{code, message, sqlState}` and no
`data` key — guard for it once, then assume `.data` on subsequent calls:

```bash
snowapi -X POST "${SNOWFLAKE_BASE}/api/v2/statements" -d '{"statement":"SHOW DATABASES","timeout":20}' \
  | jq -r 'if .data then (.data[] | @tsv) else "error \(.code // "?"): \(.message // .)" end'
```

Swap the `statement` for any of: `SHOW SCHEMAS IN DATABASE MY_DB`,
`SHOW TABLES IN SCHEMA MY_DB.PUBLIC`, `DESCRIBE TABLE MY_DB.PUBLIC.EVENTS`,
`SHOW WAREHOUSES LIKE 'MY_WH'` (column 2 = state: `STARTED`/`SUSPENDED`/`RESUMING`/`SUSPENDING`).

For predictable column sets across versions, query `INFORMATION_SCHEMA` instead — e.g.
`SELECT table_name, row_count, bytes FROM my_db.information_schema.tables WHERE table_schema='PUBLIC'`
or `SELECT column_name, data_type, is_nullable FROM my_db.information_schema.columns WHERE table_schema='PUBLIC' AND table_name='EVENTS' ORDER BY ordinal_position`.

To label rows by column name, zip `resultSetMetaData.rowType[].name` with each `data[]` row:
`jq '[.resultSetMetaData.rowType[]?.name] as $c | .data[] | [$c,.] | transpose | map({key:.[0],value:.[1]}) | from_entries'`.

## Pagination

Pagination is **partitions**, not cursors. `resultSetMetaData.partitionInfo` is an array of
`{"rowCount", "uncompressedSize"}` entries; loop indices, no next-token. Each partition is bounded
to keep response sizes manageable (roughly a few thousand rows or ~10 MB uncompressed).

## Rate limits

Snowflake doesn't publish a fixed requests-per-second cap on the SQL API. The limits you actually
hit are:

- **Concurrent statements per warehouse** (`MAX_CONCURRENCY_LEVEL`, default 8) — excess queries
  queue inside Snowflake, not at the HTTP layer, so you won't get a `429`; they'll just sit in
  `QUEUED` state.
- **`429 Too Many Requests`** does happen if you hammer the poll endpoint. Back off and respect
  `Retry-After` if present.
- **Credential lifetime** — the runtime supplies and renews the credential. A persistent `401` means
  the configured credential needs fixing — report it rather than trying to re-authenticate.

Poll with a `sleep`, not a hot loop — and keep `timeout` in the POST reasonably high so most queries
return inline without polling at all.

## Error handling

Snowflake returns the HTTP status plus a JSON body with `code`, `sqlState`, `message`, and
`statementHandle`. The `code` is a Snowflake-specific numeric string (e.g. `"390302"`).

- **`200`** — Finished, results inline. Read `data[]`. Check `resultSetMetaData.partitionInfo` for more pages.
- **`202`** — Still running (or submitted async). Poll `GET .../statements/{handle}`. Body carries `statementStatusUrl` and `message`.
- **`400`** — Malformed request. Read `message`. Common causes: missing `Content-Type`, bad JSON, wrong binding index (bindings are 1-indexed strings: `"1"`, `"2"`, one per `?`).
- **`401`** — Credential missing or rejected. Check `SNOWFLAKE_ACCOUNT` points at the right account and the token/type headers are present. If it persists, the credential isn't configured for this workspace — report it.
- **`404`** — Handle not found. Results are retained 24 h; past that the handle is gone. Or the handle is wrong.
- **`408`** — Statement exceeded the request's `timeout` and was cancelled. Raise (or omit) `timeout` and resubmit.
- **`422`** — Statement failed (SQL error, cancelled). `message` and `sqlState` carry the SQL error. Don't retry blindly.
- **`429`** — Rate limited. Back off per `Retry-After`.
- **`503` / `504`** — Transient. Retry with backoff. For POSTs, retry with the same `requestId` + `retry=true` to stay idempotent.

Gotchas worth calling out:

- **Everything is uppercase by default.** Unquoted identifiers resolve uppercased.
  `SHOW TABLES IN schema my_db.public` and `MY_DB.PUBLIC` are the same; `"my_db"."public"` is not.
- **Bind placeholders in the SQL are `?`**, and **bindings are a 1-indexed string-keyed object**,
  not an array: `{"1": {...}, "2": {...}}`. Values are always strings regardless of `type`. See
  `references/api.md` (Bindings) for the type list and array-binding form.
- **`data[]` values are all strings**, and dates/timestamps are **not** ISO — `date` is days since
  epoch (`"18262"`), `timestamp_*` is epoch seconds with a 9-decimal fraction. Parse against
  `resultSetMetaData.rowType[].type`; the full per-type encoding table is in `references/api.md`
  (Result metadata & partitions).
- **Warehouse is required for anything that scans data.** Metadata-only statements (most `SHOW`
  commands, `DESCRIBE`) don't need one, but `SELECT` does. A missing warehouse fails with a clear
  message. Queries on a suspended warehouse auto-resume it (startup delay), and each resume incurs a
  60 s billing minimum (per warehouse start, not per query) — batch small lookups where you can.

## Going deeper

`references/api.md` has the fuller reference — the complete request body fields, the
`resultSetMetaData` shape, all the `parameters` session options, multi-statement and child-handle
mechanics, the monitoring endpoints (`/api/v2/statements/{handle}` status values), and notes on
binding types and VARIANT/ARRAY handling. Read it when you need the exact shape for something not
covered above.
