# Google Home Input-Phase Localhost Validation

Use this note when issue `#3` has already cleared the reduced homepage and
saved-homepage fixture checkpoints, and the next question is whether the
reduced localhost input-phase probe still proves that submit waits until the
keypress phase completes on the real headed surface.

This note is intentionally narrower than
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md` and
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md`.
It focuses on the small reduced-home localhost checkpoint that now sits between
the bounded homepage-fixture gate and the broader submit-timing or shared
Enter-order ladders.

## Start with the validation surface check

Use the dedicated checker first so missing docs, helpers, wrapper commands, or
the raw headed probe fail fast before you trust this narrower issue `#3`
checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_input_phase_validation_surface.ps1
```

That checker verifies the dedicated note, the earlier homepage-fixture note,
the later submit-timing note, the broader issue `#3` flow helpers, the wrapper
runner, and the raw reduced-home localhost probe.

## Start with the printed flow

After the surface check is green, use the dedicated helper first when you want
the current command order printed before you run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_input_phase_validation_flow.ps1
```

That helper keeps the dedicated surface check, wrapper runner, and raw probe on
one small command surface before you widen again.

## Fastest bounded runner

When you want the reusable reduced-home input-phase checkpoint in one command,
run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_input_phase_validation.ps1
```

Use the wrapper when the earlier homepage-fixture checkpoint is already green
and the next question is whether the reduced localhost Google-style form still
records submit after the keypress phase on the real headed Win32 surface.

## Raw probe fallback

When you need the exact underlying reduced-home localhost probe without the
wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\google-home-input-phase-localhost-probe.ps1
```

Prefer the wrapper unless you specifically need the raw probe output files from
`tmp-browser-smoke\google-investigation-next`.

## What success looks like

Treat the reduced-home input-phase checkpoint as green only when all of these
remain true:

- the reduced Google-style probe still reaches the expected typed-text state
- the Enter path still reaches the submitted page on the real headed surface
- `submitted_after_keypress = true` still holds for the same shared text value
- the same ordering still agrees with the later submit-timing and shared
  Enter-order ladders when you widen back out

If this checkpoint fails, fix it before widening into the later submit-timing
slice, the shared Enter-order stack, attached HTML follow-up, or the live
Google homepage.

## When to widen again

After this bounded checkpoint is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1` when you want the later Google-shaped keydown, keypress, and submit-ordering ladder printed before you run it
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1` when you want the next bounded timing slice on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when the next question is the wider shared label baseline plus stricter Enter-order ladder
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` only after the reduced-home input-phase, submit-timing, and shared Enter-order checkpoints agree

## Working rule

Do not jump from the homepage-fixture checkpoint straight to attached HTML or
the live Google homepage when the branch already provides this smaller reduced
localhost input-phase proof.

Keep the reduced-home input-phase checkpoint green first, then widen back out
to the submit-timing slice, the shared Enter-order ladder, attached-page
follow-up, or the live headed homepage only as needed.
