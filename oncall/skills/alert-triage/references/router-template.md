# Alert router template

The router is the part of the oncall profile that turns "an alert fired" into "here is the one
thing to check first". Without it, every fire starts from generic checks; with it, triage on a
known alert is a lookup. This file is the scaffold a team fills in, plus how Claude bootstraps a
first draft and keeps it honest.

## Where it lives

Under the oncall profile's `## Alert router` heading — inline while it is a few rows, or in a
separate canvas or doc linked from that heading once it grows. The `oncall-profile` skill owns
the profile's location and overall schema; this file only describes the router table and the
per-alert recipe entries and triage notes beneath it.

## The table

```
## Alert router

| Alert / monitor | What it measures | Question it answers | First check | Runbook |
|---|---|---|---|---|
| <stable ID + short name> | <metric, unit, window, filter — one clause> | <the fork this alert exists to detect, phrased as a question> | <the single query/panel/command that splits the fork> | <link or "§entry below"> |
```

Column guidance:

- **Alert / monitor** — lead with the stable identifier (monitor ID, rule name, check name),
  then a short human name. Names get retuned; IDs survive. If several monitors share one
  recipe, list them on one row.
- **What it measures** — the metric as instrumented, not as titled. "HTTP 5xx as a fraction of
  all responses at the load balancer, 5-min window, production only" beats "error rate". Say
  whether it counts attempts or successes, requests or customers, and where in the request
  path it is observed — an alert measured at the edge and one measured inside a service answer
  different questions even when they share a name.
- **Question it answers** — every useful alert distinguishes two worlds. Write the fork:
  "Did an upstream provider go down, or did our client break?" / "Did callers stop calling, or
  are we failing the calls we get?" / "New instrumentation, or real regression?" If you cannot
  phrase the fork, the alert may not be earning its place (see Alert hygiene in SKILL.md).
- **First check** — the one discriminator that splits the fork most cheaply: a group-by on a
  specific tag, a companion monitor's state, a funnel ratio, "is there a deploy marker in the
  ten minutes before onset". One item. The second and third checks belong in the recipe entry.
- **Runbook** — a link to the team's runbook page, or a pointer to a recipe entry further down
  the profile. "None yet" is an acceptable and useful value.

## Thresholds are not written here

**Do not record thresholds, evaluation windows, or "normal" baseline numbers in the router.**
They live in the monitoring tool and they change; a number copied here is wrong within a
quarter and nobody notices. When triage needs the current threshold or window, fetch the live
monitor definition through `datadog-api` / `grafana-api` / the paging tool's alert payload.
Numbers that *may* appear in a recipe entry are dated observations ("as of 2026-03, ~8 of 10
warn-level fires were token-refresh churn") and decision rules ("treat a single tenant above
60% of errors as tenant-scoped") — label them as such so nobody mistakes them for config.

## Recipe entries

Below the table, one short entry per alert (or per family) that needs more than a one-cell
first check. Keep each to what a responder needs at 3am:

```
### <ID — short name>

What it measures: <one or two sentences; include what it does NOT see — e.g. "4xx count as
success here, so a completely broken caller is invisible to this monitor">
When it fires, what is broken: <the user-visible consequence, per branch of the fork>
Discriminators, in order:
  1. <check> → if <result>, it's <branch A>; go to <next step / other entry>
  2. <check> → ...
Known benign shapes: <pattern> — recognize it by <specific signature>, not by timing alone
Known false positives: <e.g. "all traffic rejected pre-auth looks identical to audit loss">
Escalate to: <team/rotation name as plain text> when <condition>
Companion alerts: <IDs that should also be firing if this is real, and what their silence means>
```

Write discriminators as observable signatures, not conclusions: "both funnel steps drop
proportionally with conversion unchanged" is checkable; "upstream issue" is not. Where a
benign shape exists, state the exact test that confirms it — the point of the entry is that
the next responder does not have to trust the last one's judgement.

## Bootstrapping a starter table

When a team has no router, Claude drafts one rather than waiting for it to be written:

1. **List what can fire into this channel.** If `datadog-api` is installed, list monitors
   filtered by the team's tag / service / notification handle. If `grafana-api` is installed,
   list alert rules routed to the channel's contact point. If `pagerduty-api` is installed,
   list the services on the team's escalation policy and pull recent incidents' alert payloads
   to see which upstream monitors actually page. With none of these, read the last few weeks
   of channel history and extract distinct alert identities from bot posts.
2. **Fill what the tools can tell you.** ID, name, the query (from which "what it measures"
   can usually be written accurately), notification routing, and — from channel history — how
   often it fired and how often anyone replied.
3. **Leave honest gaps.** "Question it answers" and "First check" are team knowledge. Draft a
   guess only where the query makes it obvious, mark guesses as guesses, and leave the rest
   as `TODO(team)`.
4. **Post the draft in-thread and ask specific questions**, one per gap, addressed to the
   channel rather than to named people: "Row 4 splits by `upstream_host` — is a single host
   dominating the usual benign case, or the dangerous one?" Fold answers in as they arrive.
5. **Sort by pain.** Put the alerts that fired most in the lookback window at the top; that
   is where a first check pays for itself soonest.

## Keeping it alive

- Every triage post on an alert with no router row says so; every third such post on the
  same alert should come with a proposed row.
- When a triage thread discovers a new discriminator or a new benign shape, propose the
  recipe edit in the same thread while the evidence is fresh.
- When a monitor is deleted or renamed, strike or update its row the next time a sweep
  notices the ID no longer resolves.
- Rows are cheap; stale rows are expensive. A row whose first check has been wrong twice
  gets rewritten, not annotated.
