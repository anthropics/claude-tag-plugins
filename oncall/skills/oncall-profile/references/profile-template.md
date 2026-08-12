# Oncall profile — <team name>

_Last reviewed: <date> by <handle>. Sections marked (unconfirmed) were discovered automatically
and have not been checked by a human. Keep this to about two screens; link out for detail._

## Team & rotation

| | |
|---|---|
| Team | <name> — <one line on what the team is responsible for> |
| Rotation name | <as it appears in the paging tool> |
| Handover | <weekday> <HH:MM> <timezone> |
| Paging service(s) / schedule(s) | <names as they appear in PagerDuty or equivalent> |
| Oncall handle / user group | <@group-handle as plain text> — named in reports, never @-mentioned unasked |
| Alerts land in | <this channel / #other-channel> |
| Other channels to sweep | <team help / requests channel, incident-announcements channel, if any> |
| Incident channels | <naming convention, e.g. `#inc-<date>-<slug>`, or "we stay in-thread"> |
| Incidents declared / tracked in | <PagerDuty, incident.io, FireHydrant, Jira, a Slack workflow, …> |
| Working agreements | e.g. "Claude may ack a page when the on-call asks in-thread; never resolves." / "Claude never touches the pager." / "Top-level posts only for SEV2+; everything else in-thread." / "Claude may @-mention the incoming on-call in the scheduled rotation handoff." |

## Services owned

| Service | Purpose | Tier | Dashboard | Logs query | Repo |
|---|---|---|---|---|---|
| <name> | <one line> | <critical / standard / best-effort> | <link> | `<saved query or filter>` | <link> |

## Dependencies

| Direction | System | Owner / where to check its health | How its failure shows up here |
|---|---|---|---|
| Upstream (we call it) | <database, queue, auth, vendor API> | <team handle or status page> | <symptom> |
| Downstream (calls us) | <consumer> | <team handle> | <who complains and how> |

## First places to look

- Dashboards: <link> — <what question it answers>
- Saved log queries: `<query>` — <when to run it>
- Traces: <service / operation names worth filtering on>
- Error tracker projects: <project names>
- Synthetic checks / status page: <link>

## How to see what changed

The first universal question when something breaks. List every place a change can come from.

| Change type | Where to look | Notes |
|---|---|---|
| Deploys | <pipeline UI, release feed, bot posts in #channel> | <auto-deploy windows, if any> |
| Feature flags | <flag tool audit log> | <naming prefix for this team's flags> |
| Config | <config repo / service> | |
| Infra & scaling | <autoscaler events, node pool changes, cloud console> | |
| Vendor status | <status page links> | |
| Data / schema | <migration log> | |

## Alert router

Link to the team's filled-in copy of the alert-triage router table:
<link or "see canvas: Alert router">

(Format: alert / monitor → what it measures → question it answers → first check → runbook.
Template lives with the `alert-triage` skill. Per-alert recipe entries and triage notes — last
verdicts, known benign shapes, lessons from shadow scoring — live under the table in the same
place, not in this profile.)

## Severity & declaring an incident

Link to team or company policy: <link>. If none, these defaults apply until replaced:

| Level | Meaning | Declare? | Update cadence |
|---|---|---|---|
| SEV1 | Broad customer-visible outage or data at risk | Yes, immediately | <e.g. every 30 min> |
| SEV2 | Significant degradation, subset of users, or a critical internal path down | Yes | <e.g. hourly> |
| SEV3 | Minor or contained; workaround exists | Optional; work in-thread | On material change |
| SEV4 | Internal-only, cosmetic, or a single alert that self-resolved | No | — |

Declare bar in one sentence: <e.g. "any SEV2+ or anything customer-visible for >10 min">.

## Escalation & ownership

Claude names owners from this table; it does not @-mention them unless someone asks.

| Component / symptom area | Owning team | How to reach (channel / handle) | Notes |
|---|---|---|---|
| <component> | <team> | <#channel or @group-handle> | <hours, preferences> |

Escalate past the on-call to: <secondary / manager handle> when <condition>.

## Mitigation levers

Cheapest reversible lever first. Claude never runs these unasked; it may name the right one
and draft the command for a human.

| Lever | How | Who may pull it | Reversal |
|---|---|---|---|
| Feature flag off | <tool + flag naming> | <role> | Flip back |
| Rollback | <pipeline action or command> | <role> | Redeploy |
| Scale out | <where> | <role> | Scale in |
| Shed / rate-limit traffic | <mechanism> | <role> | Remove limit |
| Failover | <mechanism> | <role> | Fail back |

## Recurring patterns

Two or more distinct occurrences to earn a row. Same entity re-reported counts once.

| ID | Signature (what you see) | First check | Last seen | Occurrences | Permanent fix |
|---|---|---|---|---|---|
| RP-01 | <alert names / error text / shape on the graph> | <the one query or page that confirms it> | <date + link> | <n> | <ticket link + status: open / in progress / shipped <date>> |

## Reporting

| | |
|---|---|
| Handoff notes live in | <doc location / channel canvas / ticket> using <template link> |
| Postmortems live in | <location> using <template link>; due <n> business days after resolve |
| Follow-up actions tracked in | <Jira / Linear project> |
| Follow-up marker in incident threads | <e.g. a `:memo:` reaction or a "TODO:" prefix, or none> |
| Status update cadence | per severity table above |
| Triage mode | <shadow / live> — shadow: verdicts go only where "Shadow output" says, nobody is pinged, and a scorecard compares calls with what humans did (see the `alert-triage` skill) |
| Shadow output | <thread / channel <name>> |
| Shadow scoring | <e.g. weekdays 09:00 <TZ>> |
| Callout confidence floor | <e.g. 70%> — below this, triage posts a short "watching" note in the alert's thread instead of an incident-bar callout |

## Glossary

| Term | Meaning here |
|---|---|
| <internal name> | <what it is, in one line> |
