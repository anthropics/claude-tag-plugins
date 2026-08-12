# Shadow mode — earning trust before going live

Shadow mode is how a team finds out whether Claude's triage is worth listening to before
anyone is asked to listen to it. Claude triages every alert exactly as it would live, records a
call and a confidence, and pages nobody, pings nobody, and posts nothing top-level in the
working channel. On a schedule, a scoring pass compares those calls against what the humans
actually did. The team reads the scorecard and decides when — and for which alerts — to switch
live callouts on.

## Turning it on

The oncall profile carries a line such as:

```
Triage mode: shadow
Shadow output: thread            # or: channel <name of a low-traffic side channel>
Shadow scoring: weekdays 09:00 <TZ>   # when the scorecard runs
```

`thread` means each verdict goes as a reply under the alert's own bot post — visible to anyone
who opens the thread, invisible to anyone scanning the channel. `channel` means verdicts go
top-level in a separate low-traffic channel the team designates, one post per alert linking
back to the original; use this when the team wants the working channel's threads untouched.
Either way: no @-mentions, no reactions on the humans' messages, no write actions of any kind.

## What Claude records per alert

Same triage flow as SKILL.md, same evidence bar. The post ends with a fixed, parseable tail so
the scoring pass can read it back:

```
shadow-call: PAGE | NO-PAGE | ROUTE:<other team/rotation, plain text>
confidence: NN%
alert-id: <monitor id / incident number / fingerprint>
fired-at: <UTC>   called-at: <UTC>
```

- **PAGE** — a human should be interrupted for this now.
- **NO-PAGE** — this can wait for working hours or needs nothing.
- **ROUTE** — real, but belongs to someone else; name who.

If the picture changes while the alert is still open, add a second reply with a revised call
and mark it `revised:`; the scorer grades the *first* call as the operative one (that is what
would have woken someone) and tracks revisions separately.

**Independence boundary.** While forming the call, do not read the human responder's replies
in the alert thread, their acks, or any incident channel they opened for it — that is the
answer key. Read them freely afterwards, at scoring time. If the runtime cannot avoid showing
you the thread, form and post the call before scrolling past the bot's message, and say
`contaminated: yes` in the tail when you could not.

## The scoring pass

Run on the schedule in the profile (a routine works well), covering the window since the
previous scorecard.

1. **Coverage.** List every alert that fired into scope during the window — from channel
   history and, if `pagerduty-api` / `datadog-api` / `grafana-api` is available, from the
   source systems, paging through results until the window is covered. Diff against the set
   of alerts that have a `shadow-call`. Every miss is a row in the scorecard with a reason
   (arrived while no session was running, dedup misfire, parse failure). Coverage below 100%
   is the first thing to fix; accuracy on a biased sample means little.
2. **Ground truth ("Actual").** For each alert, derive what it turned out to need from what
   humans did — now reading everything: the alert thread, acks/escalations/snoozes in the
   paging tool's log, silences and monitor edits, deploys or rollbacks attributed to the
   responder in the window, incident records opened. Rubric:
   - Ack followed by auto-resolve and no substantive human follow-up → **Actual = NO-PAGE**.
   - Only deferrable work followed (ticket, threshold tune, silence, a non-urgent fix merged
     later) → **NO-PAGE**.
   - Responder changed production state under time pressure (rollback, restart, scale, flag
     flip), escalated to or paged another team, opened an incident, or worked under live
     customer impact → **PAGE**.
   - Another team was already paged for the same root cause and this team's impact was purely
     downstream → **ROUTE:that team** (score a NO-PAGE call as agreeing).
   - A responder's explicit statement ("nothing for us here", "this should have paged
     earlier") outranks inference from their actions — quote it with a permalink.
   - Alerts that closed less than an hour or so before the pass: mark **provisional** and
     re-derive next time; the human response may still be unfolding.
3. **Grade.** Per alert: agree / over-call (Claude PAGE, Actual NO-PAGE) / under-call (Claude
   NO-PAGE, Actual PAGE) / mis-route. Under-calls are the risk that matters — each one gets a
   short written analysis of what the triage missed and what check would have caught it.
   Over-calls are cost, not risk; track the rate.
4. **Calibration.** Bucket calls by stated confidence (50–59, 60–69, 70–79, 80–89, 90+) and
   report, per bucket, how many there were and what fraction agreed with Actual. Confidence is
   doing its job when the 90+ bucket is nearly always right and the 60s bucket is right a bit
   more than half the time. A flat line (every bucket ~75% right) means the number is
   decoration and the floor in `incident-bar.md` cannot be trusted to filter anything.
5. **Latency.** Median and worst fired-at → called-at. Exclude rows where the delay was the
   runtime's (no session, tool outage) from the median but list them; they are a coverage
   problem wearing a latency costume.

## The scorecard post

One new top-level post per scoring pass in the shadow output location (never appended to an
old one), machine-regular so the next pass and any dashboard can parse it:

```
Triage shadow scorecard — <window start> to <window end> UTC

Alerts in scope: N   covered: N (NN%)   missed: N → <ids>
Agreement (first call): NN%   over-calls: N   under-calls: N   mis-routes: N
Unrecovered under-calls (all time): N
Calibration: 50s a/b · 60s a/b · 70s a/b · 80s a/b · 90+ a/b   (agreed/total)
Latency fired→call: median Xm, max Ym (K rows excluded as runtime-delayed)

| alert-id | fired (UTC) | call | conf | actual | grade | note |
|---|---|---|---|---|---|---|
| ... one row per alert, ids bare, times absolute ... |

Under-call analysis:
- <alert-id>: <what was missed; which check would have caught it; proposed router/recipe edit>

Lessons folded into profile notes this pass: <list, or "none">
Open questions for the team: <rubric edge cases you ruled on, stated so someone can overrule>
```

Mechanical lessons (a query gotcha, a metric that counts attempts not successes, a bot whose
timestamps are local not UTC) go straight into the profile's per-alert notes. Anything that
changes the *rubric* or touches the independence boundary is written out in the scorecard as a
proposed rule with reasoning, and adopted only when a human agrees; when a rubric rule does
change, re-grade past rows under the new rule so the trend line stays comparable.

Never write a specific alert's expected verdict into memory as a shortcut ("monitor X is
always noise") during shadow — that leaks the answer key into future calls and inflates
agreement without improving triage. Discriminators are fair ("monitor X is noise *when* the
per-tenant split shows one tenant above 80%"); conclusions are not.

## Graduating

There is no universal passing grade; the team sets it, and it can differ per alert family.
Reasonable things for them to look at before switching `Triage mode: live`:

- Coverage has been complete for several consecutive scorecards.
- Zero, or fully explained, under-calls over a window the team considers representative
  (including at least one real incident, if one occurred).
- Calibration is monotone — higher stated confidence really is more often right — so a
  confidence floor is a meaningful control.
- The over-call rate at the intended floor is something the team is willing to read.

Graduation can be partial: live callouts for alerts with router entries, shadow for
everything novel; or live for NO-PAGE/ROUTE verdicts (which only ever reduce noise) while
PAGE verdicts stay in-thread until calibration firms up. When the mode flips, keep the
scoring pass running — live triage needs the same scorecard, it just stops being the only
output.
