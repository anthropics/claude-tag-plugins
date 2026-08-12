# Investigation methodology

The full loop behind the short version in `SKILL.md`. Read this once you are past triage and the
incident is neither obviously noise nor obviously matched to a runbook entry.

## The shape of the work

An investigation is a sequence of increasingly specific, evidenced statements. You start with
"something is wrong with X" and end with "mechanism M, introduced by change C at time T, causes
symptom S for population P; lever L reverses it." Every step in between should either sharpen one
of those slots or eliminate a candidate for it. If a query you are about to run cannot do either,
don't run it.

## Phase 1 — Establish ground truth

**Fix the timeline from data.** Find the onset in the underlying series, not the alert
notification — alerts fire after evaluation windows and notification delays, often several
minutes late. Record onset, first detection, each human or automated action, and recovery, all in
one explicitly named timezone. When two events are "around the same time", get both timestamps to
the second before treating them as related; ordering is evidence, proximity is not.

**Widen the context.** The thread you were called into is an entry point, not the whole picture.
Search the channel and adjacent channels for the same service or error string in the last day;
check whether an incident is already open elsewhere; check whether a dependency's owners are
already discussing something. Link what you find rather than re-deriving it — but treat other
people's (and other agents') conclusions as leads to verify, not facts to relay.

**Bound the blast radius early.** Which services, routes, regions, cells, tenants, client
versions are affected, and which are conspicuously fine? The unaffected set constrains hypotheses
as much as the affected set does. See `impact-assessment.md` for the full rubric; at this stage a
rough split is enough.

## Phase 2 — Find the mechanism

**Trace one concrete failure end to end.** Before any more aggregation, pick a single failed
unit — one request, one job run, one message, one customer record — and follow it through every
component it touched. Collect all of its identifiers (request ID, trace ID, correlation ID, host,
pod, shard, tenant) and read each layer's logs and spans for it in strict timestamp order. The
point of the ordering is attribution: the first component to do something abnormal is the actor;
every component after it is reacting. The service whose name is on the alert is frequently just
the one that noticed. If the failing unit has a parent (a batch, a session, an upstream call),
trace upward too.

Then confirm the mechanism generalises: take the signature you found (the exception, the status
code pair, the empty field) and count it across the incident window. One trace finds the
mechanism; the batch earns the right to call it *the* cause rather than *a* failure.

**Generate competing hypotheses deliberately.** Write down at least two or three explanations
that fit what you know, including at least one that does not involve the most recent deploy. For
error-rate and saturation symptoms, make sure demand (offered load rose), supply (capacity fell or
didn't scale), and routing (load and capacity are fine but not matched) are each represented.
For correctness symptoms, make sure code change, config/flag change, data change, and dependency
behavior change are each represented.

**Design discriminating checks.** For each hypothesis, ask: what would I observe if this were
true that I would *not* observe under the others? Run that. A query whose result is consistent
with every hypothesis on the board has told you nothing, however reassuring it looks. State the
expected result before you run the check so you can't rationalise afterward.

**Follow anomalies down, not sideways.** When a check surfaces something unexpected, ask why
*that* happened and keep descending through the same causal chain. A single investigation that
follows one thread through three systems to a mechanism is worth more than three shallow
observations about three systems.

**Consult the change log late and skeptically.** Once you have a mechanism, look for the change
that introduced it — the deploy, flag, config push, migration, scaling event, or upstream release.
Doing this *after* you understand the failure keeps you from anchoring on whichever change
happens to sit nearest the onset. A change earns "cause" status only when you can explain how it
produces the traced mechanism; temporal adjacency plus a plausible story is not enough, and the
more plausible the story, the more expensive the detour when it is wrong.

## Phase 3 — State findings

### Evidence types

Tag every finding with the kind of evidence behind it, honestly:

- **Direct** — a specific log line, span, query result, diff, or config value that shows the
  claim with no inferential step. "Line 3 of the trace shows pricing-svc returned `discounts: []`."
- **Correlational** — two things move together in time or across a dimension. "Error ratio rose
  in the same minute the rollout completed." Useful for ranking hypotheses, insufficient for a
  verdict on its own.
- **Inferential** — reasoning from how the system is built. "Given the retry policy, a 2s
  upstream stall would exhaust the pool." Legitimate, but label it, and name the direct check that
  would upgrade it.

Overclaiming wastes the verifier's time; underclaiming delays a fix that the evidence already
supports. Both are errors.

### Finding categories

Sort what you report so readers can find what they need:

- **Trigger** — the change or event that started this occurrence.
- **Root cause / contributing factor** — the latent condition that let the trigger hurt (missing
  validation, absent limit, retry amplification, single point of failure). There are usually
  several; resist collapsing them into one.
- **Timeline event** — a timestamped fact that matters to the sequence.
- **Impact** — who and what was affected, quantified.
- **Mitigation / remediation** — what was done or is recommended, and its observed effect.

### Quality bar

A finding is worth posting when it is new to the thread, backed by an artifact someone else could
open, and moves one of the slots in the target sentence. Do not post: restatements of what a human
already said (that's a quote, not a finding); facts obvious to anyone reading the alert;
speculation with no check attached; a second copy of something already established.

Make every finding independently verifiable: include the query or link, say what result you got,
say what result would have refuted it, and name the strongest alternative explanation you
considered and why you set it aside.

## Anti-patterns

- **Symptom reporting** — describing what is broken in more detail instead of explaining why.
- **Confirmation lock** — finding one piece of support for the first idea and stopping.
- **One-query verdicts** — declaring a cause from a single aggregate.
- **Timestamp hand-waving** — "around the same time" standing in for actual ordering.
- **Scope creep** — making claims about systems that the traced failure never touched.
- **Relay without verification** — passing along another person's or tool's conclusion as fact
  because its timing fits.
- **Intent as state** — reasoning from "the limit was raised" because someone said so, without
  reading the live value; overrides expire and get clobbered silently.
- **Hedged verdicts** — posting a mechanism wrapped in "preliminary" and "possibly". Either the
  unhedged part stands alone and you post that, or you wait for the settling check. The one
  exception: a mitigation that is safe under every live hypothesis can be recommended before the
  mechanism is settled — say that this is why.
