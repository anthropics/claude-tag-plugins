# Reviewing a postmortem

Two uses: the passes you run on your own draft before delivering it, and reviewer mode for a
postmortem someone else wrote. Both keep the blameless register — critique the document and
the system, never the responders or the author.

## 1. Self-review checklist

Walk the draft once per item; each is a gate, not a suggestion.

- **Every claim has a source** in the facts file or provenance appendix. Anything you cannot
  point at is hedged in place, moved to open questions, or cut — never left as bare assertion.
- **Timeline is monotonic and tz-consistent.** One timezone label throughout; entries in
  order (same-minute ties allowed); every milestone the prose refers to exists as an entry;
  the milestone durations recompute correctly from the entries they cite.
- **Numbers reconcile.** Each figure in the Summary matches its home in Impact (same value,
  window, unit); each figure in a chart caption matches the chart and the prose; durations in
  metadata match the timeline.
- **No counterfactual blame language** (table below). Analysis sections name artifacts, roles
  and decisions, not individuals. Quotes preserve the speaker's hedges and conditionals.
- **Hindsight-bias guard.** For each responder decision the draft describes, can you point at what
  they could see at that moment? If the draft says or implies "should have", re-read the record
  from their seat and rewrite as what was known, what was tried, and what would have made the
  better option visible.
- **Contributing factors is a tree.** More than one leaf; trigger separated from latent
  conditions; each leaf names a specific component or process and passes the "had this been
  different" test; timing counterfactuals checked against the timeline.
- **One home per fact.** Search for each key number and each key noun phrase; if it is stated
  (not merely referenced) in two analysis sections, keep the one doing more work.
- **Action items are specific, owned, verifiable.** Each has a type, a proposed owner role, and
  a "done when" that names observable evidence. Strike any that reduce to "be more careful",
  "improve monitoring", "add documentation" without saying which monitor or which page.
- **Length within the agreed budget**; if it is at the ceiling, cut a paragraph rather than
  tightening sentences. Only template sections present; no template brackets left unfilled;
  DRAFT in the title; review owner named.
- **Links**: the body carries only the handful a reader would click; everything else is in the
  appendix. No live-window dashboard links.

### Phrases to avoid, and blameless rewrites

| Avoid | Why | Write instead |
|---|---|---|
| "X failed to notice / forgot to" | assigns a personal lapse | "the signal was only visible on dashboard Y, which is not part of the paging path" |
| "should have known / obviously" | hindsight bias | "with the information on the alert page at 14:05, A and B looked equally likely" |
| "human error", "operator mistake" | stops the analysis one layer early | name the interface, default or process that made the wrong action easy and the right one invisible |
| "carelessly", "rushed", "sloppy" | characterizes, does not explain | state the actual constraint: concurrent incident, no dry-run available, deadline |
| "the root cause was <person's action>" | single cause, person-shaped | "the trigger was <change>; it caused impact because <latent conditions>" |
| "if only X had…" | counterfactual blame | "a guard at <layer> would have caught this regardless of X" |
| "X decided not to page" (from a hedged message) | misquotes a question as a decision | quote the actual words, or "the thread weighed paging and held off pending confirmation of retry absorption" |
| "unfortunately", "critical", "disastrous" | editorializing | the number |

The test for any sentence: attach a name to it — if it now reads as an accusation, it was one
already. Rewrite about the condition, then confirm from the record that the condition framing
is true.

## 2. Independent cold reads

A single reviewer holding every question at once does each badly; split them. Where the runtime
lets you spawn subagents, run these three in parallel, each given only the draft (with figures),
the facts file / provenance appendix, and read access to the sources — not your working notes.
Where it does not, do them yourself as three separate sequential passes, each with only its own
question in mind.

- **Factual pass** — "does the record support each claim?" Spot-check claims against their
  cited sources; confirm every number and quote matches; confirm the Summary's certainty
  matches the body's; confirm each caption matches its chart; confirm every name in the
  analysis sections resolves to an artifact, a role, or a faithful quote. Output: a list of
  unsupported or overstated claims with the correction.
- **Timeline pass** — two questions: is any key event, decision or state change in the record
  missing from the timeline? does any entry carry narrative, opinion or padding rather than an
  event? Plus the mechanical checks: chronological order, single timezone, milestone arithmetic.
  Output: missing events, entries to strip, arithmetic errors.
- **Relevance pass** — "does the intended reader need this paragraph?" applied to every
  paragraph and every figure. Output opens with the named cuts, then anything that is in the
  wrong section, then anything an outsider could not follow without one more clause of
  orientation.

Apply the findings, then do one plain-language read: first sentence of each paragraph carries
the point; consistent component names; no filler; no unexplained acronyms for the agreed
audience.

Record which passes ran. The delivery message states it plainly, e.g. "objective: <their line
or 'default'> · self-review: done · cold reads: factual + timeline ran, relevance skipped ·
length: ~3 screens / budget 4". Skipped is acceptable when stated; unstated is not.

## 3. Reviewer mode — critiquing someone else's postmortem

You are adding the perspective the authors were too close to have, not grading their prose.
Read their document first, then read the incident channel, alerts and linked sources yourself
end to end — including long threads and any call notes, which usually hold the real debugging
reasoning — before forming a view. Then work through:

**Against the checklist.** Run section 1 over their draft. Report gaps as questions or
suggested text, not verdicts: "Impact says ~2k users; the summary says 'a small number' —
which should the reader take away?"

**Recurring pattern.** Search the team's incident tracker, past postmortems and Slack for the
same component and the same failure mode. If this has happened before, the most important
finding may be why the previous action items did not prevent it — say so, linked, gently.

**Stronger action items.** For each proposed item ask: does it treat the symptom or a leaf of
the tree? What single change would have prevented this entirely? What would have halved time
to detect or time to mitigate? Propose the stronger version beside the original rather than
replacing it, with its type and a "done when".

**Implicit insights.** Look in the channel for things responders struggled with but never
turned into follow-ups: a dashboard nobody could find, a permission someone lacked, a runbook
step that was wrong, twenty minutes spent on a hypothesis that better data would have killed
in two. Frustration in the thread usually marks an unwritten action item. Also list early
assumptions that turned out wrong and what would have corrected them sooner.

**Challenge the single-cause narrative.** If the document names one root cause, sketch the
tree it implies and ask which other leaves had to hold. Is the named cause actually a trigger
with the latent conditions unexamined? Is there an uncomfortable factor (staffing, ownership,
a known-fragile component everyone routes around) that the document steps past?

**Lucky breaks.** What limited the blast radius that cannot be relied on next time — time of
day, a small canary, a person who happened to be online, a cache that happened to be warm?
Each is a candidate finding for "what went well / where we got lucky" and often a candidate
detect/mitigate item.

**Report back** in the thread, in this order: new action items not in the document; stronger
versions of existing ones; patterns or systemic issues worth naming (with prior-incident
links); questions the document does not answer; smaller consistency fixes last. Offer to draft
replacement text for any section only if asked.
