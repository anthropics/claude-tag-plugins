# Gathering the raw material

The report is only as good as the ledger behind it. This file is the recipe for building that
ledger so that nothing the incoming oncall will trip over is missing, and every count in the
report can be pointed back at rows.

## Preflight

1. **Window.** Start = previous handoff's "data through" time, else the profile's rotation
   boundary, else ask. End = now unless told otherwise. Convert both to the timezone the team
   works in *and* to UTC epoch seconds; Slack history tools take epoch, humans read local time.
   Write both forms at the top of the ledger.
2. **Do not truncate the end.** Setting the end to today's midnight UTC is a common, silent
   mistake — for most teams it drops the last evening and morning of the shift. Leave the end
   open, then record the timestamp of the newest message you actually retrieved and print it in
   the report as "data through <local time tz>".
3. **Is the rotation over?** If `pagerduty-api` is installed, read the schedule for the window
   and check whether the on-call has actually changed hands. If not, tell the user the report will
   be partial and through when, and ask whether to proceed or wait. A scheduled run that fires
   before the boundary should say so and stop rather than post a partial report unprompted.
4. **Who.** From the schedule: everyone who held primary or secondary during the window,
   including overrides and swaps, with the sub-window each covered. Without a paging plugin, take
   names from the profile or the user. Resolve each to a Slack user ID with the user-lookup tool —
   you need IDs for mention searches and display names for the report. Also note the team's oncall
   user-group ID and its handle text; both are in the profile, or findable via the user-group
   listing tool.

## Slack: run every sweep, union the results

Any one of these alone undercounts, sometimes badly, and they overlap less than you would expect.
Run all that apply, tag each ledger row with the sweep(s) that found it, and dedupe by permalink.

| Sweep | How | Why it is needed |
|---|---|---|
| (a) User-group mentions | Search for the group mention token (`<!subteam^ID>` form) in the window | The "official" way people summon oncall |
| (b) Literal handle text | Search the plain text of the handle and of the rotation name | People type the handle without it linkifying; bots render it as text; some search backends only match one form |
| (c) Direct mentions of the oncall people | Search `<@USERID>` for each person who held the pager, scoped to their sub-window | Once someone knows who is on, they ping the person, not the group — these never hit (a) or (b) |
| (d) Alert / paging bot posts | Read the alerts channel history for the window (channel read, not search — bot posts are often excluded from search by default) | Pages and monitor fires; the thread under each is where the response lives |
| (e) Incident channels opened in the window | Search for the team's incident-channel naming prefix, and read the incident-announcements channel if the profile lists one; also search each oncall person's ID together with the prefix | Declared incidents where the work happened in a dedicated channel and never touched the team channels |
| (f) Team channels, chronological | Read (not search) the team help / requests channel top-level messages for the window | Catches asks that mentioned nobody — "anyone know why X?" — that oncall picked up anyway |

Mechanics that matter:

- **Paginate to exhaustion.** Search and history tools return a page at a time (often 20–100).
  Keep following the cursor until it runs out or timestamps fall before the window start. If a
  tool caps total results, split the window into day-sized slices and run each.
- **Date filters can lie.** Some search backends apply `after:`/`before:` inconsistently across
  channel types. If a sweep returns suspiciously little, re-run it without date operators and
  filter by timestamp yourself.
- **Read threads.** For every top-level hit with replies, fetch the thread. Record: first and last
  reply time, whether it reads as resolved, who resolved it, and any links to tickets, PRs,
  dashboards, or other threads.
- **Follow permalinks across channels.** When a message links to another thread, read that thread
  too and attach it to the same ledger row. The linked thread is frequently where the cause and
  fix are; the swept channel has only "seeing errors, looking".
- **Resolve IDs as you go.** Collect every distinct user, group, and channel ID you encounter,
  resolve each once, cache the mapping in the ledger, and never let a raw ID reach the report.

## Dedup and counting rules

- **One ask, many messages.** A single request commonly appears as the original post, a workflow
  or ticket-bot echo, a cross-post to a second channel, and a reminder ping. Collapse to one ledger
  row; keep all permalinks on it. Count asks, not messages.
- **Alert families.** The same monitor firing repeatedly is one row with a count, first/last
  fire time, and whether each fire was the same underlying condition re-notifying or genuinely
  separate occurrences (read the threads to tell). A monitor that re-notified all week on one
  unresolved condition is a single open item, not N alerts.
- **Self-noise.** Drop the oncall person mentioning themselves, bot relays of their own messages,
  and test pages.
- **Counts are floors.** Slack search recall is imperfect and varies by sweep. When the report
  gives a count derived from search, say it is a lower bound and which sweeps fed it. Counts from
  the paging tool or ticket tracker are exact for what they query — say what that was.
- **Episodes.** After dedup, cluster rows that share a cause: the page, its alert re-fires, the
  incident channel, the request thread from an affected team, and the fix. The report tells each
  episode once.

## Beyond Slack

Use whichever of these the workspace has; each replaces guesswork with a query you can cite.

- **Paging tool** (`pagerduty-api` or equivalent): incidents on the team's service(s) in the
  window with urgency, ack and resolve times, who was notified; the on-call schedule as actually
  served. This is the authoritative page count and the strict-gate test for "was this an
  incident". Also pull the same query for the previous window so the report can state a trend.
- **Incident tracker** (if separate from paging): declared incidents touching the team's services,
  with severity, status, and postmortem link or its absence.
- **Error tracker** (`sentry-api`): new and regressed issues in the window for the team's
  projects, to cross-check "user impact" claims and catch things nobody paged on.
- **Tickets** (`jira-api` / `linear-api`): issues created or transitioned in the window on the
  oncall/ops project or label; open follow-ups from prior incidents. This is where "still open"
  gets verified against reality rather than against the last Slack message.
- **Code changes** (if the runtime has a GitHub repository connected): PRs merged in the window that reference the
  incidents, alerts, or tickets above — search by linked issue, by branch/label convention from
  the profile, or by the oncall people as author. Attach each to its episode as the "Fix" link.
  Do not produce a freestanding "PRs this week" list; a PR with no episode is not handoff content.
- **Change log** (deploy history, feature-flag audit, config repo): what shipped adjacent to each
  incident's onset, and which mitigations (flag flips, pins, scaling overrides) are still applied.
  The second feeds the Temporary mitigations table directly.

If none of these are connected, ask the user to paste the paging tool's incident list for the
window and proceed Slack-only for the rest, saying so in the report header.

## The ledger

Keep one scratch file for the run (JSON lines or a markdown table). One row per deduped item:

```
id | kind (incident|page|alert-family|request|change|carry) | episode | first_ts | last_ts |
channel | permalinks[] | found_by[] (a,b,c,d,e,f,paging,tickets) | summary | state
(open|resolved|mitigated|stalled|verify) | next_action | owner | links{ticket, pr, incident, pm}
```

Below the rows, keep the raw numbers: hits per sweep before dedup, rows after dedup per kind,
paging-tool counts for this and the previous window, and the newest timestamp retrieved. When the
user says a number looks wrong, re-derive from here or run the sweep you skipped — do not defend
the figure.

The ledger is working state, not an artifact: do not post it. Offer it to the outgoing oncall if
they want to audit, and delete it when the report is accepted.
