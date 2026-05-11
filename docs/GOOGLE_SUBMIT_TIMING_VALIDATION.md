# Google Submit-Timing Validation

Use this note when issue `#3` has already cleared the earliest reduced title and
homepage gates, and the next question is whether the bounded Google-shaped
submit-timing slice still preserves keypress before submit on the real headed
surface.

This note is intentionally narrower than
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md` and
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md`.
It focuses on the timing-only bridge that now sits between the saved homepage
fixture checkpoint and the broader shared Enter-order ladder.

## Start with the validation surface check

Use the dedicated checker first so missing docs, helper scripts, wrapper
commands, or the raw headed probe fail fast before you trust this narrower
issue `#3` slice:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_timing_validation_surface.ps1
```

That checker verifies the dedicated submit-timing note, the later submit-path
note that routes into it, the Windows runbook, the submit-timing flow helper,
the wrapper runner, and the raw Google-shaped headed probe.

## Start with the printed flow

After the surface check is green, use the dedicated flow helper when you want
the current command order printed before you run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1
```

That helper keeps the dedicated surface check, wrapper runner, and raw probe on
one small command surface before you widen again.

## Fastest bounded runner

When you want the reusable submit-timing slice in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1
```

Use the wrapper when the earlier reduced homepage or saved-homepage-fixture
gates are already green and the next question is whether keypress still lands
before submit on the headed Win32 surface.

## Raw probe fallback

When you need the exact underlying Google-shaped headed probe without the
wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-google-submit-timing-probe.ps1
```

Prefer the wrapper unless you specifically need the raw probe output files from
`tmp-browser-smoke\layout-smoke`.

## What success looks like

Treat the submit-timing slice as green only when all of these remain true:

- the Google-shaped probe still reaches the expected typed-text state
- the Enter path still reaches the submitted page on the real headed surface
- `title_after_enter` still carries the expected submitted marker
- `keypress_before_submit = true` still holds for the same input text
- the same ordering still agrees with the broader shared Enter-order ladder when
you widen back out

If this slice fails, fix it before widening into the broader shared Enter-order
stack, attached HTML follow-up, or live Google replay.

## When to widen again

After this bounded slice is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when you want the stricter shared Enter-order ladder printed before you run it
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1` when you want the shared label baseline, reduced-home keypress probe, localhost wrapper, and dedicated form-controls gate back on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1` when the next question is the broader saved-homepage-fixture plus later-stage handoff
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` only after the submit-timing and shared Enter-order slices agree

## Working rule

Do not widen from the reduced homepage or saved-homepage-fixture pass straight
to attached HTML or the live homepage when the branch already provides this
smaller timing checkpoint.

Keep the submit-timing slice green first, then widen back out to the shared
Enter-order ladder, attached-page follow-up, or the live headed homepage only
as needed.
