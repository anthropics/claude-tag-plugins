# Handoff report templates

Two skeletons. Use (1) for a shift or rotation handoff addressed to the incoming oncall; use (2)
for a broadcast weekly digest. In both, **delete any section with nothing in it** — an absent
heading says "nothing here" more honestly than a heading over "none".

## 1. Shift / rotation handoff

```markdown
**Oncall handoff — <rotation name>: <start, tz> to <end, tz>**
Outgoing: <name(s)>  ·  Incoming: <name(s) or "per schedule">  ·  Data through <time tz>
<if partial: "Partial — rotation ends <time tz>; anything after <data-through> is not included.">
Previous handoff: <link>

**TL;DR**
<Two or three sentences. First: is anything actively broken or degraded right now. Second: what
the incoming oncall owns as of this moment, by count and the one that matters most. Third,
optional: the dominant theme of the window if there was one.>

**Still open** — <N> items
- <One-line what> — state: <where it stands>. Next: <concrete action: command, link to check,
  question to ask whom>. Owner: <name | needs owner>. <link>  <[carried from last handoff] if so>
- ...

**Resolved since last handoff** (carried items only)
- <item> — closed by <link to fix/ticket>. | <item> — stalled, no movement; still listed above.

**Incidents** — <N>  (paged or formally declared only)
*<Short title> — <date>, <severity if the team uses them>, <status: resolved | mitigated | open>*
What broke: <one or two sentences a teammate outside the incident could follow>.
User impact: <who/what was affected, with numbers and the time window they cover; "none
observed" is a valid answer, "minimal" is not>.
Cause: <root cause if established> | "Not root-caused; mitigated by <what>."
Fix: <what was done, linked>. <"Temporary — see mitigations below" if applicable.>
Watch for: <the symptom that would mean it is back, and the first thing to do if it is>.
Links: <incident record> · <channel/thread> · <postmortem or "postmortem not yet written">

**Alerts and pages**
<N> pages to <schedule>, <M> outside working hours. Previous period: <N'>. <One sentence on
trend only if it moved meaningfully.>
| Alert / monitor | Fires | Actionable? | Note |
|---|---|---|---|
| <name> | <n> | yes / noise / flapping | <what to do when it fires, or link to tuning ticket> |
| ...top 5... | | | |
…and <K> more with ≤<x> fires each: <link to ledger or query>.

**Requests and pings handled** — <N> distinct asks (floor; from <which sweeps>)
Grouped, one line each, link on the noun. Only include ones the incoming oncall might get a
follow-up on, plus a count of the rest: "<n> routine access requests, all closed."

**Temporary mitigations in place**
| What | Why | Remove when | How to remove | Link |
|---|---|---|---|---|

**Recurring themes / suggested hygiene**
- <Pattern seen ≥2 times this window or across handoffs> — <suggested fix, sized as a ticket
  title, linked to the ticket if filed>.

**Notes for next oncall**
- <Anything that does not fit above: a planned maintenance in the coming window, a person who
  is out, a dashboard that is lying, a runbook step that turned out wrong.>
```

### Section rules

- **TL;DR** is state-of-the-world, present tense, as of the data-through time. It is not a
  summary of the sections below and not a sentence about how busy the week was.
- **Still open** is the section the reader acts on; put it before incidents even when incidents
  are more dramatic. "Next" must be something a person can do without re-reading the thread:
  `check <dashboard link> for <metric> back under <threshold>`, `ask <name> whether <specific
  question>`, `merge <PR link> once CI is green`. "Follow up on X" and "monitor Y" are not actions.
- An incident that is mitigated but not root-caused appears once under **Incidents** with status
  "mitigated", and its removal task appears under **Temporary mitigations**. It does not also
  appear under Still open unless there is a distinct next action beyond "write the postmortem".
- **Alerts and pages**: tables are for counts. The judgment — which of these should be tuned,
  which is a real recurring condition — goes in the Note column or in Recurring themes, once.
- **Requests**: dedupe to distinct asks, not messages. Never list them all; top few plus a count.

## 2. Weekly team digest

For a channel-wide or leadership audience. Fits on one screen. Grouped by component or service,
not by day.

```markdown
**Oncall week in review — <start> to <end tz>**  ·  <N> incidents, <M> pages, <K> open items
<One sentence: what is still open that the team, not just the next oncall, should know about.>

*<Component A>*
- <What happened, one or two plain sentences, current status, who is coordinating.> <links>
*<Component B>*
- ...

*Needs an owner*
- <item> — <why it matters in one clause>. <link>

*Carrying into next week*
- <owner>: <what they hold, one line, status>.

Full handoff: <link to the shift report or doc>
```

Keep incident mechanics out of the digest; link to the handoff or postmortem for them. Expand any
term a reader outside the immediate subsystem would not know, in a clause, the first time it
appears.

## Writing rules (both modes)

- **Narrative for incidents, tables for counts.** An incident is a short story: what broke, who
  noticed how, what it did to users, why, what fixed it. A table row cannot carry causality. Alert
  tallies, mitigation inventories, and carried-item status are tables or terse bullets.
- **Every number is traceable.** It came from a ledger row count, a paging-tool query, or a
  metrics query, and the sentence says which and over what window. If Slack search produced it,
  it is a floor — say so once in the section header, not on every line.
- **Concrete over abstract.** Commands, links, thresholds, names of monitors and flags exactly as
  they appear in the tools. "The latency alert" is ambiguous when there are four.
- **One home per item.** If you are tempted to mention something in two sections, pick the one
  the reader would look in first and link from nowhere else.
- **Top-N with a tail.** Five alerts, five requests, then "and N more" with a link to the full
  list. The reader will open the link if they care; they will stop reading if you inline forty.
- **Numbers, not adjectives.** "Error rate 8–12% for 22 minutes" rather than "significant
  degradation". Drop "critical", "massive", "minor" unless they are the team's literal severity
  labels.
- **No activity log, no applause.** Cut any sentence whose subject is the outgoing oncall and
  whose verb is "handled", "responded", "investigated", "worked on". Cut "great job", "shout-out",
  "busy week". What remains is what the system did and what state it is in.
- **Conditions before instructions.** "If <monitor> fires again during a deploy, <action>" — the
  reader who does not match the condition skips the line.
- **Anchor pronouns.** With several incidents in play, "it recovered" and "this is still flaky"
  force a re-read. Name the thing.
- **Uncertainty is marked, not smoothed.** `[verify: <what>]` inline where you could not confirm
  state. The outgoing oncall resolves these before the incoming one reads the report.
- **Sentence-case headings, minimal bold.** Bold the section labels and nothing inside them.
