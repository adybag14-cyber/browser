# Google Input Validation

This note captures the smallest repeatable validation stack for the headed
Windows Google search-box work tracked by issue `#3`.

## Purpose

Use this when a change affects headed focus, text commit, Enter handling, or
submit timing on Google-like pages.

The goal is to confirm the shared engine path in this order:

1. The bounded Google-style title fixture still focuses, accepts typed text, and submits on a keypress-backed Enter path.
2. The reduced localhost input-phase gate still proves text commit before Enter submit reaches the page.
3. Enter still submits only after the page sees the keypress phase.
4. The saved homepage probe remains available for deeper page-state inspection.
5. Only then move on to the broader issue `#3` runner, attached localhost HTML follow-up, or live Google tracing.

## Dedicated Title Gate

Use the dedicated title wrapper when you want the smallest bounded readiness,
focus, typed-text, and keypress-backed submit pass before the wider homepage or
shared Enter-order ladder.

Surface checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_title_validation_surface.ps1
```

Read-first flow helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1
```

Marker guide:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1
```

One-command wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1
```

Direct probe wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_title_probe.ps1
```

Raw headed localhost title probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1
```

## Dedicated Localhost Input-Phase Gate

Use the dedicated reduced localhost input-phase wrapper set when you want a
smaller checkpoint between the title gate and the broader reduced-homepage or
live Google passes.

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

## Issue #3 One-Command Stack

Use the broader issue `#3` helpers only after the title gate and reduced
localhost checkpoints are the right next question.

Fail-fast surface checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1
```

Read-first flow helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_recommended_validation_flow.ps1
```

One-command recommended runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

## What Success Looks Like

A good bounded title run should prove all of the following:

- click or keyboard focus reaches the reduced Google query input
- typed text updates the page title with the expected query value
- Enter submits the form
- submit happens at `keypress`, not `keydown`
- the title markers still show the expected `Q=`, `A=`, `V=`, and `SUBMIT:` stages in order

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

Use that fixture when the bounded title probe is green but the broader
Google-style page still diverges in focus, text commit, or submit behavior.

## Recommended Escalation Order

1. Run the dedicated title wrapper first.
2. Run the dedicated reduced localhost input-phase wrapper when you want the smaller typed-text-before-submit checkpoint.
3. Run `google-enter-order-probe.ps1` when you want the stricter reduced form-controls keypress-before-submit proof.
4. If needed, re-run with `chrome-google-enter-order-probe.ps1` so the command shape matches the rest of the smoke suite.
5. If the bounded reduced gates fail, debug the shared input path before touching the broader issue `#3` runner or live-site validation.
6. If the bounded reduced gates pass, continue into `show_google_issue3_recommended_validation_flow.ps1` and `run_google_issue3_recommended_validation.ps1`.
7. Use attached localhost HTML follow-up or live Google tracing only after the smaller title-first and reduced-home checkpoints stay green.
