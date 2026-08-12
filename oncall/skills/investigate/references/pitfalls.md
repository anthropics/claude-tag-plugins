# Analytical pitfalls

Recurring ways an investigation reaches a confident wrong answer. Read this list before posting a
verdict at medium confidence or higher, and name in your post any pitfall you checked for and
ruled out — it saves the reader from asking.

## About the signal itself

- **The step at the deploy that isn't a regression.** A series that goes from absent or near-zero
  to the alert level precisely at a rollout and then sits flat is, more often than not, a new
  metric, a renamed tag, a changed denominator, or newly added logging. Three checks separate
  instrumentation from regression: does an independent signal (raw logs, a probe, user reports)
  move too; did the metric exist with the same tags before the rollout; does the *shape* look
  like a system under stress (ramps, saturation, recovery) or like a constant.
- **Wrong baseline.** Comparing to the previous hour hides daily and weekly cycles. Compare to the
  same weekday and hour one week earlier before calling anything elevated, and rule out a
  reclassification (traffic moved between tiers, tenants, or labels) masquerading as growth.
- **Aggregates hide the unit that broke.** Fleet-wide utilization, error ratio, or latency can
  look healthy while one shard, cell, zone, or pod is saturated or dead — the smallest unit fails
  first. Errors at moderate aggregate load mean: split by every physical and logical partition
  before concluding anything.
- **A label that doesn't mean what you think.** When a breakdown by some tag is driving your
  diagnosis, verify what that tag actually denotes under the current deployment. Tags get
  stamped by whichever component handled the request last, defaulted on early rejections, or
  repurposed after a migration. Attribution to one backend or version by label alone carries no
  weight until an independent indicator agrees.
- **Live thresholds versus documented ones.** The threshold and window written in a runbook or
  alert description drift from the monitor's real configuration. Read the monitor.
- **Re-using the monitor's window to check recovery.** A rolling evaluation window that summed
  the original burst will keep reporting it across overlapping evaluations. Re-query at fine
  granularity to see whether new events are still arriving.

## About causation

- **Adjacent in time is not causal.** Any busy hour contains deploys, flag flips, scaling
  events, and upstream releases that have nothing to do with your incident. The change log is a
  list of candidates. A candidate becomes a cause when you can state the mechanism linking it to
  the traced failure — and it must beat the mechanism you already traced, not merely sit near it.
- **Shared window, shared ramp, shared backdrop — no shared cause.** Two problems that overlap in
  time, or both happen during a traffic peak, or both happen while some other incident is open,
  are independent until shown otherwise. Record a suspected link as an unproven candidate on every
  surface, including handoffs, until the owning team confirms it.
- **The standing incident that explains too much.** A long-running degradation accounts for
  chronic pressure, not for a fresh step change. A minutes-old anomaly filed under an open
  incident as "probably related" needs to be shown to predate the window or be too small to
  matter; otherwise test it as its own trigger.
- **The reporter is not the culprit.** The service whose name is on the alert is the one that
  noticed. Order the traced request's events by timestamp; whoever acted abnormally first is the
  actor, and everyone downstream is reacting.
- **The minority error is often the trigger.** When an error breakdown has a dominant code and a
  non-trivial secondary one, look up the secondary before attributing everything to the dominant
  — the small one frequently starts the cascade that the large one describes.
- **Demand measured after shedding.** During a rejection storm, admitted-traffic series cannot
  show you that demand rose, because the excess never got in. "Demand was flat" needs an
  edge-side or client-side series.

## About your own process

- **Concluding from the arm that finished.** When you ran three checks and one errored or timed
  out, you have two results and a gap — not a verdict. Say which check is missing and hold the
  conclusion at hypothesis strength until it runs.
- **Negative claims held to a lower bar.** "No single tenant caused this", "the database is
  fine", "not related to the deploy" are findings and need the same query-plus-result backing as
  a positive attribution. If the check that would establish the negative didn't run or ran on
  partial data, the honest word is "unmeasured", not "diffuse" or "ruled out".
- **Intent mistaken for state.** Someone saying a limit was raised, a flag was flipped, or a fix
  was deployed is a statement of intent. Read the live value. Overrides expire, config gets
  overwritten, deploys get superseded — and a mitigation that silently lapsed is the next
  incident.
- **The prior fix assumed present.** On a re-fire of a known pattern, the first check is whether
  the earlier remediation is still in place and still effective, not a hunt for a new mechanism.
- **A corrected number in an uncorrected frame.** When one figure in a post turns out wrong,
  re-derive the whole claim. Fixing the number and leaving the surrounding sentence intact often
  leaves a conclusion standing that the new number no longer supports.
- **Scope mismatch on a direct question.** When a human asks "is X affected?", confirm that your
  data actually covers X — the right environment, region, service instance — before answering
  from it.
- **Mental arithmetic and eyeballed dates.** Derive counts, durations, and day boundaries
  programmatically. State the timezone. Prefer phrasings that stay true across the timezones your
  readers are in.
- **Expert disagreement.** When the people who own a system dispute your mechanism, keep your
  verified facts on the table and withdraw the story that connects them. The facts may still be
  the most useful thing in the thread; the story was yours to be wrong about.
