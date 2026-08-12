# Incident comms templates

Six copy-ready message shapes. Fill every `<placeholder>`; delete a line rather than leaving it
blank or writing "N/A". Times always carry a timezone. Numbers always carry window and source.
People are written as plain text (`@.name`) so the message notifies no one — switch to a real
mention only when the person running the incident asks you to reach someone.

## (a) Current-state post — one per incident, top-level, pinned, edited in place

```
<Incident title — what is broken, in user terms>
Severity: <SEVn as declared by @.name | not yet declared>
Status: <investigating | identified | mitigating | monitoring | resolved> as of <HH:MM TZ>
Impact: <who experiences what, how many / what fraction, since HH:MM TZ> (<source>)
Onset: <HH:MM TZ> (<how known>)   Detected: <HH:MM TZ> via <alert name / report> (<link>)
Running the incident: <@.name | not yet named>   Hands-on: <@.names>   Comms: <@.name>
Links: <dashboard> · <triggering alert> · <tracker record> · <status page, if any>

Timeline and working notes are in this thread. Next update: <HH:MM TZ>.

Open items
- <question or action> — owner <@.name | none> — opened <HH:MM>
- ~~<closed item>~~ — done <HH:MM>
```

Reactions on this post: `:eyes:` tracking · `:warning:` needs a human decision (see thread) ·
`:white_check_mark:` resolved. One at a time.

## (b) Sitrep — scheduled, in thread; also folded into (a) by silent edit

```
Sitrep — status as of <HH:MM TZ>   (severity <SEVn>, <status>)

Impact (measured)
- <metric>: <value> (<window>, <source link>) — <up / down / flat> vs last sitrep
- Affected: <population, region, surface> — <count or fraction> (<how counted>)

What we know, and how
- <fact> — <evidence link>
- <fact> — <evidence link>

What we don't know, and what's being done about it
- <open question> — <who is looking, what they're running>
- <item with no owner / no movement since HH:MM> — needs an owner

Actions in flight
- <action> — <@.owner> — started <HH:MM> — <expected signal that it worked>

Need from you
- <decision or input required, from whom> | Nothing right now.

Since last sitrep: <new: …; resolved: …; unchanged: …>
Next update: <HH:MM TZ>, or sooner on material change.
```

Keep each bullet to one line. If a section is empty, write one line saying so ("No actions in
flight.") rather than dropping the heading — readers scan by position.

## (c) Keepalive — thread only, never broadcast

```
<HH:MM TZ> — no material change since <HH:MM>. <metric> <value> (<window>). <Action> still in
progress (<@.owner>). Next update <HH:MM TZ>.
```

One or two lines. Its purpose is to prove the cadence is alive and pin a fresh "as of" time.

## (d) Outward update — DRAFT for a human to review and send

```
DRAFT — for <@.name> to review and send via <status page / customer email / leadership channel>.
Not sent by me.

---
<Title: plain description of the symptom, e.g. "Delays loading dashboards">

Status: <Investigating | Identified | Monitoring | Resolved> — as of <HH:MM TZ, Month D>

Since <HH:MM TZ>, some <which users: region / product area / plan, if known> may
<what they see: errors when…, slow…, unable to…>. <Other functionality> is not affected.

<If a workaround exists:> In the meantime, <what they can do>.
<If mitigated:> We applied a fix at <HH:MM TZ> and are monitoring recovery.

We will post another update by <HH:MM TZ>.
---

Notes for the sender (delete before sending):
- Cause is <confirmed / not confirmed>; the draft <does / does not> state it.
- Numbers behind "some users": <measured figure, window, source>.
- Component name on the status page this maps to: <component>.
```

No internal system names, hostnames, ticket IDs, team or personal names. No cause unless
confirmed and cleared by the person running the incident. No blame. No timing promises beyond the
next-update time you were given.

## (e) Resolution summary — final thread reply; short form folded into (a)

```
Resolved — as of <HH:MM TZ, Month D>. Declared by <@.name>.

What broke: <one or two sentences, mechanism as currently understood; mark "preliminary" if so>
User impact: <who saw what>, <count / fraction / volume> over <start HH:MM – end HH:MM TZ>
  (<duration>), per <source link>. Peak: <value> at <HH:MM>.
What fixed it: <action> at <HH:MM TZ> by <@.name>; impact ended <HH:MM TZ> (<how verified>).
Trigger vs conditions: trigger <what changed right before onset, link>; contributing
  <latent conditions named in channel, if any>.

Clocks
- Time to detect: <onset HH:MM → first alert/report HH:MM> = <duration>
- Time to mitigate: <detection HH:MM → impact ended HH:MM> = <duration>

Still open
- <residual risk, thing being monitored, temporary mitigation that must be made permanent>

Follow-ups (proposed — not yet filed)
- <action> — proposed owner <@.name> — <why>
- <action> — proposed owner <@.name> — <why>

External comms sent: <where, when, by whom | none>
Postmortem: <link when it exists | to be scheduled by @.name>
Timeline: <permalink to the timeline message or canvas>
```

One message. No congratulations, no narrative, no lessons — those belong to the postmortem.

## (f) Shift-boundary digest — long incidents, in thread

Every status in this message is **as of the boundary time in the heading**, so it stays correct
whenever it is read. Never write "now" or "currently".

```
Handoff — state at <HH:MM TZ, Month D>
Outgoing: <@.name>  →  Incoming: <@.name>

State at <HH:MM>: severity <SEVn>, <status>. Impact <metric value> (<window>, <source>).
Current working theory: <one line, with confidence: low / medium / high> — evidence <link>.

Tried and ruled out (don't re-run)
- <hypothesis> — ruled out <HH:MM> because <evidence link>
- <action> — no effect, reverted <HH:MM>

In flight at <HH:MM>
- <action> — <@.owner> — watching <signal> — next check <HH:MM>

Open decisions for the incoming
- <decision>, needed by <HH:MM or condition>, context <link>

Temporary mitigations that expire or need babysitting
- <override / flag / scale-up> — set <HH:MM> by <@.name> — <expires when>;
  verify it is still applied via <where to look>

Next scheduled update: <HH:MM TZ>. Current-state post: <permalink>. Timeline: <permalink>.
```

If nothing is in a section, keep the heading with a one-line "none at <HH:MM>" so the incoming
person knows it was checked rather than forgotten.
