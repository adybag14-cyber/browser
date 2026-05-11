# Google Home Input-Phase Localhost Validation

This note captures the smallest dedicated validation surface for the reduced
Google-style localhost probe that proves typed text commits before Enter submit
reaches the page.

## Purpose

Use this when issue `#3` work needs one more bounded checkpoint between the
generic localhost Google-style probes and the broader reduced-homepage or live
Google passes.

The goal is to prove all of the following on the real headed surface:

1. Click focus recovery still reaches the reduced Google-style query input.
2. Typed text still commits into the field and updates the page title.
3. Enter submit still waits until the keypress phase, not keydown.
4. Only then widen back out to the broader issue `#3` validation ladder.

## Commands

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

## Success Markers

A good run should prove all of the following:

- the probe can recover focus onto the reduced query field
- typing updates the title to `Google Home Typed <query>`
- Enter reaches the submitted page
- the server-side submit marker records `submit_phase=keypress`

## Escalation Order

1. Run the surface checker first.
2. Run the dedicated wrapper.
3. Drop to the raw probe only when the wrapper fails and you need the direct
   output files from `tmp-browser-smoke/google-investigation-next/`.
4. Return to `docs/GOOGLE_INPUT_VALIDATION.md` or
   `scripts/windows/show_google_input_validation_flow.ps1` when this smaller
   gate is green and you want the broader issue `#3` ladder again.
