# Google Home Title Probe Trace Guide

Use this note with `src/browser/tests/page/google_home_title_probe.html` when the
bounded localhost fixture is the next proof step for issue `#3`.

The page already mirrors the saved Google homepage and pushes a compact status
string into the document title. This guide keeps that title output readable so a
headed run can quickly tell whether the failure is in focus, text commit, or
Enter-submit ordering.

## What The Title Fields Mean

The title follows this shape:

`<last-mark>|A=<active>|Q=<query>|V=<value>|S=<selection>|E=<early-event>`

Read the fields like this:

- `A=`: the current active element.
- `Q=`: the query input that the fixture found through `document.forms.f.q` or
  `[name="q"]`.
- `V=`: the query input value visible to the fixture right now.
- `S=`: `selectionStart:selectionEnd` for the query input.
- `E=`: the latest early capture event recorded before the later status hooks.

## Common Markers

These are the most useful markers during issue `#3` triage:

- `BOUND`: the fixture found and bound the query input.
- `FOCUSIN:INPUT:q`: the real query control took focus.
- `TYPED:<value>`: text committed into the input value.
- `BEFOREINPUT:<char>:<value>`: the browser emitted `beforeinput` before the
  value changed.
- `KEYDOWN:<char>:<value>` or `KEYPRESS:<char>:<value>`: character delivery is
  happening but may not have committed yet.
- `KEYDOWN:<value>:13:13`: Enter reached the input on keydown.
- `SUBMIT:<value>`: the form submit hook fired with the current query value.

## Quick Diagnosis Rules

Use these shortcuts when the bounded fixture still fails:

- `BOUND` and focus markers appear, but `TYPED:` never appears:
  the failure is still before text commit.
- Character `KEYDOWN:` or `KEYPRESS:` markers appear, but `V=` stays empty:
  text events are arriving without the value mutation landing.
- `SUBMIT:` appears with an empty value:
  Enter submit fired before the typed text committed.
- `TYPED:` appears and `V=` matches it, but no `SUBMIT:` follows:
  focus and text commit worked, but the Enter-submit path still diverged.

## Recommended Handoff

Keep the current issue `#3` order:

1. Run the reduced localhost fixture and capture the title string.
2. If the failure is clearly before text commit, stay on the bounded
   Google-style localhost probes.
3. If text commit looks good but submit ordering is wrong, move to the bounded
   submit-timing or shared Enter-order helpers.
4. Only move back to the attached-page or live Google follow-up after the title
   fixture makes the failing stage obvious.
