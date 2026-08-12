# 5 whys — the in-thread short form

## When to use it

Someone in the incident or oncall thread asks "so what actually happened?" or "why did this
fall over?" shortly after mitigation, and wants an answer in the thread now, not a document
next week. Also useful as the seed you hand to whoever writes the full postmortem later. It is
posted by whoever was asked — the separate-gatherer discipline is for the document, not this.

Keep it to roughly fifteen lines. If you cannot, the incident wants the full document; say so
and offer it.

## Format

A linear chain: one path down what will later be the contributing-factors tree.

```
**Why this happened** (as of HH:MM TZ — draft, corrections welcome)

Symptom — <what users/systems experienced, quantified, with window>  [verified: <source>]
Why 1 — <the immediate mechanism that produced the symptom>          [verified: <source>]
Why 2 — <what caused Why 1>                                            [verified: <source>]
Why 3 — <what caused Why 2>                    ← defect layer (config) [verified: <source>]
Why 4 — <what caused Why 3>                                            [interpretation]
Why 5 — <the process/design condition behind Why 4>                    [interpretation]

Candidate action items:
1. <the fix at the defect layer> (prevent)
2. <the detection or mitigation improvement> (detect/mitigate)
3. <the deeper process change, if the team agrees with Why 4–5> (process)
```

Rules for the chain:

- **Each line is caused by the line below it.** If the next "why" would just restate the
  previous one in different words, stop. If the chain has not yet reached a layer where the fix
  is something other than "someone should have been more careful", keep going.
- **Stop at a condition, not a person.** "The deploy was not reviewed" is a person-shaped stop;
  "config-only deploys skip the review gate by design" is a condition the team can change.
- **Mark every line** `[verified: <source>]` — a metric, log query, PR, or code reference you
  actually checked — or `[interpretation]` for a step you inferred and the team should confirm.
  Do not blur the two; the value of the chain is that readers know which links are solid.
- **Flag the defect layer**: the one line where a single change would have prevented this
  incident regardless of the lines above and below it, tagged with where the defect lived —
  `code`, `config`, `infra`, `process`, or `detection`. Deeper lines usually reduce how often
  the system gets pushed to that edge; only the defect-layer fix stops a recurrence. Keep those
  two kinds of fix separate in the action items.
- **Five is a convention, not a quota.** Three solid lines beat five with padding.
- Timestamp it "as of" and call it a draft. Early chains get revised; that is expected.

## Example

Placeholder services; the shape is what matters.

```
**Why this happened** (as of 16:40 UTC — draft, corrections welcome)

Symptom — order-api returned 503 to ~18% of requests, 15:52–16:21 UTC
          [verified: edge 5xx dashboard, window pinned]
Why 1 — order-api pods were OOM-killed in a loop; 6 of 9 restarting at peak
          [verified: pod restart count + OOMKilled events, 15:50–16:20]
Why 2 — each pod's in-memory retry buffer grew past the 2 GiB limit while
        inventory-svc was slow (p99 4s → 30s)
          [verified: buffer-size metric; inventory-svc latency panel]
Why 3 — the retry buffer is unbounded and retries have no overall deadline
          ← defect layer (code)  [verified: client config in order-api repo, retry.go]
Why 4 — inventory-svc slowed because a schema migration took a table lock during
        business hours  [verified: migration job log 15:49; DB lock-wait graph]
Why 5 — migrations for that service run on merge with no scheduling or lock-time
        guard; nothing flags a locking migration before it ships  [interpretation]

Candidate action items:
1. Bound the order-api retry buffer and add a total retry deadline; shed with 503
   + Retry-After when full (prevent, code)
2. Alert on order-api memory > 80% of limit for 3 min — would have fired ~6 min
   before the first OOM (detect)
3. Gate migrations on a lock-time check or run them in a window (process) — for
   the inventory team to weigh; Why 5 is my read, not confirmed
```

Note what the example does: the symptom is quantified with a window; the defect layer is the
unbounded buffer, not the migration (the migration was the trigger, and some future slow
dependency would have found the same edge); the last two lines are honestly marked as
interpretation; and the action items keep the recurrence-stopper separate from the
frequency-reducers.

## When it grows up

If a full postmortem follows, paste the chain into the gatherer's facts file. Why 3 becomes
the main latent-condition branch of the contributing-factors tree, Why 4 the trigger branch,
and the tree adds the siblings a linear chain cannot show (why detection lagged, why only some
pods died, what limited the blast radius).
