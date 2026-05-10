# Google Input Validation

This note captures the smallest repeatable validation stack for the headed
Windows Google search-box work tracked by issue `#3`.

## Purpose

Use this when a change affects headed focus, text commit, Enter handling, or
submit timing on Google-like pages.

The goal is to confirm the shared engine path in this order:

1. The reduced Google-style localhost fixture still focuses and accepts typed text.
2. Enter still submits only after the page sees the keypress phase.
3. The saved homepage probe remains available for deeper page-state inspection.
4. Only then move on to live Google or attached localhost HTML follow-up.

## Direct Probe Entry Points

Canonical reduced Enter-order probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1
```

Chrome-prefixed wrapper for the same reduced probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\chrome-google-enter-order-probe.ps1
```

Shared parameterized form-controls probe with the Google-style mode enabled:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
```

## What Success Looks Like

A good reduced probe run should prove all of the following:

- click focus reaches the query input
- typed text updates the page title with the expected query value
- Enter submits the form
- submit happens at `keypress`, not `keydown`
- the event log contains `KD:Enter:<query>`, `KP:Enter:<query>`, and `SUBMIT:<query>` in that order

## Deeper Investigation Inputs

The reduced Google homepage fixture used for page-level tracing lives at:

- `src/browser/tests/page/google_home_title_probe.html`

Use that fixture when the reduced form-controls probe is green but the broader
Google-style page still diverges in focus, text commit, or submit behavior.

## Recommended Escalation Order

1. Run `google-enter-order-probe.ps1` first.
2. If needed, re-run with `chrome-google-enter-order-probe.ps1` so the command shape matches the rest of the smoke suite.
3. If the reduced probe fails, debug the shared input path before touching live-site validation.
4. If the reduced probe passes, continue into the broader issue `#3` helpers under `scripts/windows/`.
