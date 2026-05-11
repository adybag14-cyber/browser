# Google Input Validation

This note captures the smallest repeatable validation stack for the headed
Windows Google search-box work tracked by issue `#3`.

## Purpose

Use this when a change affects headed focus, text commit, Enter handling, or
submit timing on Google-like pages.

The goal is to confirm the shared engine path in this order:

1. The reduced Google-style localhost fixture still focuses and accepts typed text.
2. The reduced localhost input-phase gate still proves text commit before Enter submit reaches the page.
3. Enter still submits only after the page sees the keypress phase.
4. The saved homepage probe remains available for deeper page-state inspection.
5. Only then move on to live Google or attached localhost HTML follow-up.

## Dedicated Localhost Input-Phase Gate

Use the dedicated reduced localhost input-phase wrapper set when you want a
smaller checkpoint between the generic localhost probes and the broader
reduced-homepage or live Google passes.

Surface checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_input_phase_localhost_validation_surface.ps1
```

Read-first flow helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_input_phase_localhost_validation_flow.ps1
```

One-command wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_input_phase_localhost_validation.ps1
```

Raw probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\google-home-input-phase-localhost-probe.ps1
```

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

A good reduced localhost input-phase run should also prove all of the following:

- click focus recovery can still reach the reduced Google-style query field
- typing updates the title to `Google Home Typed <query>`
- Enter reaches the submitted page
- the server-side submit marker records `submit_phase=keypress`

## Deeper Investigation Inputs

The reduced Google homepage fixture used for page-level tracing lives at:

- `src/browser/tests/page/google_home_title_probe.html`

Use that fixture when the reduced form-controls probe is green but the broader
Google-style page still diverges in focus, text commit, or submit behavior.

## Recommended Escalation Order

1. Run the reduced localhost Google-style probes first.
2. Run the dedicated reduced localhost input-phase wrapper when you want the smaller typed-text-before-submit checkpoint.
3. Run `google-enter-order-probe.ps1` when you want the stricter reduced form-controls keypress-before-submit proof.
4. If needed, re-run with `chrome-google-enter-order-probe.ps1` so the command shape matches the rest of the smoke suite.
5. If the reduced gates fail, debug the shared input path before touching live-site validation.
6. If the reduced gates pass, continue into the broader issue `#3` helpers under `scripts/windows/`.
