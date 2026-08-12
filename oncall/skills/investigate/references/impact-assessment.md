# Impact assessment

How to answer "how bad is it?" — the blast radius of an incident, stated in numbers a reader can
check. This is a different mode from root-causing: here you are mapping damage, not explaining
it. Keep the two separate in your posts so a stakeholder scanning for impact does not have to read
through mechanism, and vice versa.

## Quantify, don't characterize

Every impact statement is a number with four parts attached: **what was counted, over what
window, with what filter, in what unit.** Adjectives are not impact.

| Not this | This |
|---|---|
| "A lot of requests failed." | "18,400 `POST /v2/orders` requests returned 5xx between 14:05 and 14:52 UTC (server-side count, all regions), against a baseline of ~40 per equivalent window." |
| "Latency was bad." | "p99 latency on `search-api` (edge-measured, successful responses only) rose from 310 ms to 2.4 s from 09:12 to 09:40 UTC; p50 was unchanged." |
| "Some customers were affected." | "1,212 distinct tenant IDs saw at least one failed order in the window; the top 10 tenants account for 61% of failures." |
| "It lasted about an hour." | "Onset 14:05 UTC (first minute above 2× baseline), mitigated 14:52 UTC (rollback completed), fully recovered 14:58 UTC (ratio back under baseline for 5 consecutive minutes)." |

If a number cannot be obtained, say "unmeasured" and why — never substitute a soft word like
"minimal" or "widespread" for a measurement you did not take.

## Say exactly what each number measures

The same incident produces different numbers depending on where and how you count, and mixing
them silently is how wrong figures reach stakeholders. Be explicit about:

- **Before or after retries.** Client-observed failures and server-logged failures differ by the
  retry multiplier; user-visible impact is usually closer to the former.
- **Offered versus admitted load.** Metrics recorded after admission control or load shedding
  undercount demand during the very window you care about. Use an edge or client-side series to
  talk about what users attempted.
- **Which layer's clock and which layer's status.** A gateway 502 and an upstream 500 may be the
  same failure counted twice, or two failures.
- **Internal versus external traffic.** Synthetic probes, internal batch callers, and health
  checks inflate or dilute ratios; state whether they are in or out.
- **Count versus sum on distribution metrics.** On a latency histogram, summing values gives you
  milliseconds, not events — a plausible-looking number that is off by orders of magnitude.
  Cross-check any surprising count against a sample of raw log lines or spans.
- **Live estimate versus settled data.** A figure read off a streaming dashboard mid-incident is
  provisional; when a number computed from complete logs exists later, it supersedes the live one.
  Label which kind you are quoting.

## The rubric

Work through these five dimensions. Each yields one or two lines in the impact section.

### 1. What was affected

Which services, endpoints, features, or jobs were degraded, and in what way — hard failure,
partial failure, elevated latency, stale data, silent wrong results. Name downstream effects
separately from the primary failure and say how you established the link (a traced dependency,
not just a shared time window). List what was checked and found *unaffected*; it bounds the
damage and pre-empts questions.

### 2. Who was affected

Which population — end users, API consumers, internal callers, a region, a plan tier, a client
version, tenants with a specific configuration. Give a count of distinct affected principals
(users, tenants, keys) and, where you can, the share of the total active population in the
window. Check for concentration: is it evenly spread, or do a handful of tenants carry most of
it? Both the count and the shape matter for comms and follow-up.

### 3. How severe

Error ratio against baseline (same weekday and hour, not just the preceding hour). Latency shift
at the percentiles that moved, noting which did not. Functional loss in plain terms: what could a
user not do? Map the result onto the team's severity definitions from the oncall profile and say
which level it meets and why — do not invent a severity scale if the team has one.

### 4. How long

Four timestamps, all from data, all in one named timezone: onset, detection (first alert or first
human notice — the gap between these two is itself a finding), mitigation (impact materially
reduced), recovery (back within baseline for a stated hold period). If impact is ongoing, say "as
of <time>, ongoing" rather than leaving the end open.

### 5. SLO and contractual exposure

If the `datadog-api` or `grafana-api` skill can reach the team's SLOs, report error-budget burn
for the window and remaining budget for the period. Flag, without adjudicating, whether any
affected population has contractual availability terms the team has told you about in the
profile. If you cannot see SLO data, say so rather than omitting the line.

## Getting the numbers

- Error and latency figures: the metrics backend, using the same query the monitor uses where
  possible so your numbers reconcile with what paged. Then a log or trace aggregation for the
  breakdown by route, status, and tenant.
- Distinct affected principals: a log or event aggregation with a cardinality count on the
  principal field, filtered to the failure signature from the traced request — not to "any error".
- Baseline: the same query shifted back exactly one week, same duration.
- Duration: the finest-granularity series you have; define "onset" and "recovered" as explicit
  threshold crossings and state the thresholds.
- Downstream: for each direct dependent of the failed component, run its error and latency series
  over the same window and report movement or explicit absence of movement.

## Output shape

An impact block, whether mid-incident or in the closing summary, reads in this order: what was
affected → who and how many → how severe against baseline → the four timestamps → SLO
exposure → recovery status (recovered / mitigated but degraded / ongoing, as of when). Every line
carries its artifact. Root-cause material does not appear here; link to the finding post instead.
