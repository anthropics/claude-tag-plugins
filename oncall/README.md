# oncall

A plugin that gives **@Claude** the working habits of a good on-call teammate when it lives in
an incident, oncall, or alerts channel: investigate an alert from evidence, keep an incident's
timeline and status updates straight, write the rotation handoff, and draft the postmortem.

It does not page anyone, roll anything back, or resolve anything on its own. It reads, reasons,
drafts, and asks.

## Design stance

- **Evidence first.** Every claim Claude posts carries the thing that backs it — the query and
  its result, the permalink, the graph with a pinned time window. Numbers say exactly what they
  measure. Hypotheses are labeled as hypotheses with a confidence; "X is not the cause" needs
  the same proof as "X is the cause".
- **Humans hold the write actions.** Acknowledging, resolving, muting, rolling back, flipping
  flags, and deploying all require an explicit go-ahead from a person in the thread. Read-only
  investigation is always fair game.
- **One thread per alert or incident; quiet progress.** Claude keeps its work inside the
  thread it was asked in, edits a single status message as it goes rather than posting a stream,
  never @-mentions people or on-call handles unless asked, and timestamps every status "as of".
- **The team profile is shared context.** A short per-channel document — services, dashboards,
  change sources, severity rules, escalation map, mitigation levers, recurring patterns — is
  read by every skill and kept current after each incident and handoff.
- **Composes, doesn't re-implement.** Observability, paging, tickets, and docs come from the
  service plugins in this marketplace. This plugin is the workflow on top.

## Install

```bash
claude plugin marketplace add anthropics/claude-tag-plugins
claude plugin install oncall@claude-tag-plugins
```

## What's included

### Skills

| Skill | Purpose |
|---|---|
| `oncall-profile` | Finds, builds, and maintains the channel's oncall profile — the document every other skill loads first. Owns the profile template. |
| `investigate` | Works a single alert or symptom from first fire to a labeled verdict: what changed, one failing request traced end to end, competing hypotheses with evidence for and against, cheapest reversible mitigation named. |
| `alert-triage` | Classifies incoming alerts against the team's router table and recurring patterns — live in-thread as they fire, or in batch over a window — and proposes tuning and new router rows. |
| `incident-comms` | Keeps a running incident timeline and drafts calm, structured status updates (known / unknown and doing / need from you) on the cadence the severity calls for. |
| `handoff-report` | Summarizes a rotation window — pages, incidents, open threads, follow-ups, things to watch — into the team's handoff format with sources for every line. |
| `postmortem` | Reconstructs the timeline from primary sources and drafts a blameless postmortem with a contributing-factors tree, clearly separated trigger and latent conditions, and unassigned action items. |

### Commands

| Command | Purpose |
|---|---|
| `/oncall:setup` | Build or refresh this channel's oncall profile: discover, interview the team, publish as a canvas, and list which missing connectors would unlock what. |
| `/oncall:handoff [window \| weekly]` | Write the handoff report for the current rotation window (or an explicit one). |
| `/oncall:triage [hours]` | Batch-triage the alerts that fired in the last N hours (default 24). |
| `/oncall:postmortem [link \| 5whys]` | Draft the postmortem for the incident in this channel or thread. |

## Works best with

The plugin runs with nothing else installed — it will work from what is pasted or posted in
the channel — but each of these unlocks a real capability:

| Plugin | Unlocks |
|---|---|
| [`datadog`](../datadog) | Query metrics, logs, monitors, SLOs, and events directly; pin graphs to the incident window; discover monitors during setup. |
| [`pagerduty`](../pagerduty) | See who is on call, list pages and incidents for handoffs, read escalation policies during setup, trace who was notified when. |
| [`grafana`](../grafana) | Dashboard and datasource queries, alert rules, and annotations for teams on Grafana/Prometheus. |
| [`sentry`](../sentry) | Error groups, first-seen/last-seen, release correlation, and stack traces for the "what is actually failing" step. |
| [`jira`](../jira) / [`linear`](../linear) | File and link follow-up actions from postmortems and handoffs; find existing tickets for recurring patterns. |
| [`confluence`](../confluence) / [`notion`](../notion) / [`google-drive`](../google-drive) | Read runbooks and past postmortems; file handoffs and postmortems where the team keeps them. |
| [`claude-tag-data-viz`](../claude-tag-data-viz) | Render the incident-window chart that goes in the status update or postmortem instead of describing it. |

## Suggested rollout

1. **Run `/oncall:setup`** in the channel. Answer its questions; correct what it discovered.
   This is where the team decides the working agreements (may Claude ack pages when asked?
   what is the declare bar?).
2. **Start with handoff reports and postmortem drafts.** These are after-the-fact, low-risk,
   and immediately useful. They also exercise the profile and show you what is missing from it.
3. **Turn on alert triage in shadow mode** (`Triage mode: shadow` in the profile). Claude
   classifies alerts in-thread only and pings nobody. Compare its verdicts with what the
   on-call actually did for a rotation or two; fix the router table where it was wrong.
4. **Graduate to live triage callouts.** Set `Triage mode: live` and a callout confidence
   floor in the profile. Claude now replies under new alerts with a first check and a verdict,
   calling out "this likely meets the incident bar" only at or above the floor and posting a
   shorter "watching" note below it.
5. **Add routines.** Schedule the recurring prompts below so handoffs and sweeps happen
   without anyone remembering to ask.

## Suggested routines

Scheduled prompts that work well once the profile exists. Adjust times to the rotation.

- **Rotation-boundary handoff** — at the handover time in the profile:
  > `/oncall:handoff` — then post a one-paragraph summary at the top of the thread for the
  > incoming on-call, and list anything still open that needs a human decision today.

- **Daily alert sweep** — start of the working day:
  > `/oncall:triage 24` — highlight anything that fired overnight without a human reply, and
  > any alert that has fired on three or more days this week.

- **Weekly pattern review** — end of week:
  > Read this week's resolved incidents and alert threads in this channel. For each, check the
  > recurring-patterns table in the oncall profile: propose new rows, bump occurrence counts,
  > and flag any pattern open for more than four weeks without a linked fix. Post the proposed
  > profile edits in a thread for review; do not apply them until someone approves.

## License

Apache 2.0
