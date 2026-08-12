# The incident bar — should this be declared?

Triage recommends; a human declares. This file is the rubric for getting from "an alert fired"
to "this should probably be an incident, at roughly this severity, and here is why" — and for
knowing when to say that loudly versus quietly.

## Severity ladder (generic — the team's definitions win)

If the oncall profile carries the team's own severity definitions, use those verbatim and map
your evidence onto their language. The ladder below is the fallback when nothing is defined,
and a shared vocabulary for the callout.

| Level | Customer impact | Shape | Typical response |
|---|---|---|---|
| **SEV1** | A core user journey is unavailable or returning wrong results for a large share of customers, or data is being lost/corrupted, or a security boundary is breached | Sustained; not recovering on its own | All hands; page immediately regardless of hour; exec/customer comms |
| **SEV2** | A core journey is degraded (elevated errors, severe latency) for many customers, or fully broken for a significant segment (one region, one tier, one large tenant) | Sustained for more than a few evaluation windows, or recurring in bursts | Page the owning oncall now; incident channel; status page likely |
| **SEV3** | Noticeable degradation for a minority of customers, a non-core feature broken, or a core journey at risk (redundancy lost, error budget burning fast) with no visible impact yet | May be intermittent; may self-recover but keeps returning | Owning team responds in working hours, or now if trending worse; incident record for coordination |
| **SEV4** | Internal-only impact, cosmetic issues, a single customer with a workaround, or a near-miss worth tracking | — | Ticket; no page |

Reading the table: pick the row by *impact and trajectory*, not by how alarming the graph
looks. When two rows fit, choose the higher one and say it is a judgement call — declaring
one level high costs a little coordination; declaring one level low costs detection time.
A low-impact event can still merit a SEV3/4 record purely so that several people looking at
it have one place to talk.

## Two classes of alert

- **SLO-class alerts** sit directly on a customer-visible success or latency measure (checkout
  success rate, API availability, p99 on a core endpoint, error-budget burn). A sustained
  breach here *is* impact. Default: **declare unless proven benign**, where "benign" means a
  named, verified cause with no customer path — a data gap, a synthetic-only failure, a
  metric redefinition. "It recovered" is not that proof on its own.
- **Leading indicators** sit upstream of impact — queue depth, replica count, connection-pool
  saturation, disk headroom, dependency error rate, certificate expiry. They buy time. Match
  urgency to lead time: an indicator that historically precedes impact by minutes gets an
  act-now callout with a falsifiable prediction ("expect checkout errors by ~14:40 UTC if the
  queue keeps growing at this rate"); one that precedes impact by days gets a watch verdict
  and a ticket. The router entry should say which class an alert is and, for indicators,
  what the observed lead time has been.

An alert on neither list — novel, or unclassified — inherits the SLO-class default until
someone files it. Unknown is not the same as unimportant.

## Tests beyond "is the line above the threshold"

- **Accumulated vs self-healing damage.** After the metric recovers, is anything still wrong?
  Retried requests heal; dropped webhooks, stuck workflows, double charges, orphaned
  resources, and disabled schedules do not. If damage accumulates, the incident is not over
  when the graph is, and severity reflects the cleanup, not the spike.
- **Own recent changes, with equal billing.** Before reasoning about upstream providers or
  traffic anomalies, sweep your own change sources for the window before onset: deploys,
  rollbacks, migrations, cron changes, **feature-flag flips, config pushes, and
  infrastructure scaling all count as changes** even though they bypass the deploy pipeline.
  Where an alert surfaces says little about where it was caused; a large share of real
  incidents are self-inflicted and first appear as "dependency errors". Finding one candidate
  does not end the sweep — list them all, then discriminate.
- **Scope skepticism in both directions.** No page does not mean no impact (the monitor may
  be mis-scoped, Slack-only, or missing). Three pages do not mean three problems (one cause,
  three symptoms). Customer reports or a new error class with no corresponding alert still
  clear the bar — and are also a monitoring-gap finding.
- **Coverage check.** Is there already an open incident, in your tracker or an upstream
  provider's status page, that explains this? If so the callout is a link, not a declaration.

## The callout

When the verdict is act-now and you believe the bar is met, post this — as a reply under the
alert's thread, or as the one top-level pointer post if the signal did not arrive via a bot
card:

```
This likely meets the incident bar — confidence NN% (callout floor: MM%)

<one plain sentence: what is happening, to whom>

Impact now:                 <who/what is affected, quantified, as of HH:MM TZ — or "none yet">
Impact soon if unaddressed: <what happens over the next window, and why you think so>
Trigger:                    <deploy / flag / config / upstream / unknown + link —
                             "aligned with", not "caused by", until confirmed>
Nearest prior occurrence:   <past thread or postmortem link + why it matches — or "none found">
What I checked:             <3–5 discriminating checks and results, incl. what was ruled out>
Confidence NN% because:     <measured vs inferred vs assumed, in one line>
Suggested severity:         SEVn — <one clause mapping evidence to the ladder row>
Suggested first action:     <cheapest reversible lever: flag off > rollback > scale > hotfix;
                             or "declare and page <rotation name, plain text>">

If you declare, reply here and I'll start incident comms. If this is wrong, say why —
I'll record it against this alert.
```

Rules for the callout: every field is one line; anything longer goes in a threaded follow-up.
No @-mentions unless a human in the thread asks; name the rotation as plain text. Times
absolute with zone. Links to the graph pinned to the window you looked at, not a live view.
If a field is unknown, write "unknown" — an honest gap reads better than a padded guess.

## Confidence and the floor

The percentage is your probability that a human, looking back afterwards, will agree this
needed action now. Grade it from the evidence's status — measured directly / inferred from a
proxy / assumed from pattern — and from this alert's history in the per-alert notes (an alert
whose last six fires were benign starts lower; one that preceded the last two incidents starts
higher).
Do not round toward certainty to sound decisive; a well-calibrated 60% is worth more to the
team than a reflexive 90%.

The oncall profile may set a **callout confidence floor** (the `Callout confidence floor` row
under Reporting, e.g. `70%`). At or above the floor, post the callout as described. Below
it, stay in the alert's thread with a shorter note:

```
Watching — not calling this an incident yet (confidence NN% < floor MM%): <the one reason>.
Would upgrade if: <specific observable>. Re-checking at HH:MM TZ.
```

If the profile sets no floor, treat 70% as the default and say so in the post so the team can
see the knob exists. Proposing a floor change is fine — with the calibration data from
`shadow-mode.md`'s scorecard — but changing it is the team's edit to the profile, not yours.

## After the callout

Stay with the thread until it settles: note recovery time when it recovers, check once for
relapse, and close with a two-line summary (what it was, what was done, what is still open).
When a human's response reveals the verdict — they declared, they said "known, ignore", they
rolled back without comment — record predicted-vs-actual in the per-alert notes. Silence on
something you still believe is real earns exactly one follow-up in the same thread with a
sharper statement of what happens next if nobody acts; after that, the humans have the
information and the decision is theirs.
