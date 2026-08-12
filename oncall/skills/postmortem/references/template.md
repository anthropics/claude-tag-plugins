# Postmortem template

The default skeleton. If the team's oncall profile names its own template, use that and carry
the guidance below across to the matching headings. Emit only these sections; anything else
(process notes, drafting confidence, "out of scope") goes in the delivery message, not the
document. Guidance under each heading is for you — delete it from the output.

````markdown
# DRAFT — Postmortem: <incident id or date> <short descriptive title>

| | |
|---|---|
| Date | YYYY-MM-DD (impact start, with timezone) |
| Duration | impact start → full recovery, e.g. 1h 46m |
| Severity | per the team's definitions; one clause justifying it |
| Authors | Claude (draft) — review owner: <name or TBD> |
| Status | Draft / In review / Final |
| Links | incident channel · tracker record · status page entry (if any) |

## Summary
## Impact
## Timeline
## Detection
## Response and remediation
## Contributing factors
## What went well
## Lessons
## Action items
## Appendix: provenance
````

## Section guidance

**Title and metadata.** The title says what broke in words an outsider recognizes ("Checkout
API returned 5xx for EU customers"), not the internal ticket slug alone. Fill every metadata
cell you can from the record; write "TBD" rather than leaving template brackets.

**Summary** — five sentences at most: what happened, to whom, for how long, why (the trigger
plus the one or two latent conditions that mattered most), and how it was stopped. Give the
one-breath orientation an outsider needs ("the rate limiter is the service that…") here rather
than in a separate background section. Any claim hedged in the body stays hedged here; many
readers stop after this paragraph, and a confident summary over an uncertain body is the most
misleading shape a postmortem can take.

**Impact** — who was affected and what they experienced, in their terms first (failed
checkouts, delayed notifications), then system terms. Every number carries its window, filter,
unit and source: "4.1% of API requests returned 5xx between 14:02 and 14:48 UTC (edge
dashboard, all regions)". Include the SLO or error-budget effect if the team tracks one. State
bounds when the figure is an estimate and say what it is based on. Material impact only — a
figure that would not change anyone's decision does not belong. This section justifies the
severity.

**Timeline** — one list item per key event: `- YYYY-MM-DD HH:MM TZ — event (source)`. One
timezone throughout (UTC unless the team's profile says otherwise), minute precision, strictly
chronological, objective third person, no narrative inside entries. Include every state change,
page, escalation, significant decision, mitigation attempt (and whether it held) and recovery
milestone; explain any gap longer than an hour during the active incident in a clause. Mark
these milestones explicitly, then summarize them under the list as durations from impact start:

- **Impact start** — when users or systems were first affected (often earlier than anyone
  noticed; back it with a graph).
- **Detected** — first signal, automated or human. If automated, also note first human
  engagement.
- **Cause identified** — when responders first correctly named the triggering condition.
- **Escalated** — each widening of who was involved.
- **Mitigated** — impact stopped growing or substantially reduced.
- **Recovered** — service back within normal bounds; note any backlog drain separately.

When the timeline and the length budget conflict, raise the bar for "key" — never cut analysis
to make room for entries.

**Detection** — what signal first indicated the problem, who or what noticed, and how long
after impact start. If a human noticed before any alert, name the alert that should have fired
and why it did not (threshold, coverage gap, muted, routed nowhere). If alerts fired but were
not acted on, say what they looked like from the receiving end at the time. Link the alerts.

**Response and remediation** — what was tried, in order, and what each attempt did; which one
worked and why; time to mitigate and time to recover. Note alternatives that were available and
cheaper (a flag flip instead of a rollback) only if the record shows they were genuinely
available and knowable then. Cover escalation here: did the right people get involved at the
right time, and what slowed that down. Link the fix PRs / change records.

**Contributing factors** — a tree, not a line. Root: the impact. Under it, each condition that
had to hold for the impact to occur; recurse until each leaf is a candidate change. Label the
**trigger** (the proximate event) separately from **latent conditions** (limits, defaults,
missing alerts, ownership gaps, coupling) that turned the trigger into an incident. For each
factor, one sentence on why it made sense at the time — the default that was reasonable when
set, the alert nobody knew was needed. Each leaf should pass the test "had this been different,
the incident would have been smaller or absent"; where that is a timing claim, check it against
the timeline. Name the specific component, config or job each factor is about; a lesson about
unnamed "automation" is not actionable. If this is a repeat of a prior incident, say so here
and link it. A small rendered tree diagram helps when there are more than four or five nodes.

**What went well** — defenses that worked as designed, and human adaptations that limited the
damage. Distinguish the two: "the circuit breaker shed load as configured" is a system
property; "the responder happened to remember the flag existed" is luck the team is currently
depending on. Also list where you got lucky (off-peak timing, a canary that happened to be
small) — these belong to the review even though nothing went wrong.

**Lessons** — opinionated and argued: what should change and why, in priority order, each tied
to a node in the contributing-factors tree or a gap in detection/response. Include changes that
would speed detection and mitigation of a recurrence, not only prevention — most prevention is
probabilistic. This is the section the review meeting runs on; write it so the meeting can
spend its time deciding, not reconstructing.

**Action items** — a table. Propose rows; humans confirm owners in review.

| Action | Type | Owner | Tracker | Done when |
|---|---|---|---|---|
| Bound the export queue at N and shed with 429 | prevent | <team/role> | <link once filed> | load test shows shedding at N; alert on shed rate exists |

Type is one of **prevent** (stops recurrence), **detect** (finds it sooner), **mitigate**
(limits or shortens impact), **process** (runbook, ownership, review). Each row is specific,
owned, and verifiable — "done when" names the observable evidence. "Be more careful with
config changes" is not an action item; "config changes to service X require a dry-run diff in
CI" is.

**Appendix: provenance** — the source list the body leans on, so a reviewer can spot-check any
claim: channel/thread permalinks for key moments, each query with the exact text and pinned
time window, dashboard links with the window in the URL, PRs and change records, ticket links,
prior-incident links. Group by kind. This is where link volume lives so the body stays readable.

## Graph rules

- Embed as few charts as carry the story — often one (the impact curve with onset, mitigation
  and recovery marked), sometimes none.
- A screenshot in the channel is a pointer to a chart, not the chart. Re-render from the source
  query or dashboard over the incident window (with sensible padding either side) using the
  `graphing` skill, annotate the milestones, and link the source with the window pinned —
  never a live "last 1 hour" link that shows whatever is happening when the reader clicks.
- If it cannot be re-rendered, link the dashboard with the pinned window instead of embedding.
  Never embed an illegible screenshot (cropped legend, no axes, unknown window).
- Every chart has a caption stating window, source, and the one thing to take from it, and the
  caption reconciles any number visible in the chart that differs from the prose.
- Data charts live in Impact or the appendix; the contributing-factors diagram lives in its
  own section.
