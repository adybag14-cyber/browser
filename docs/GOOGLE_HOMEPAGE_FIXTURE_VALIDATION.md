# Google Homepage Fixture Validation

Use this note when issue `#3` has already cleared the earliest reduced title
and homepage gates, and the next question is whether the saved Google homepage
fixture still gives you one trustworthy localhost checkpoint before you widen
into the later submit-path, submit-timing, or shared Enter-order ladders.

This note is intentionally narrower than
`docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md` and
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md`.
It focuses on the bounded saved-homepage fixture slice that now sits between
the reduced headed homepage pass and the broader later-stage issue `#3`
validation helpers.

## Start with the validation surface check

Use the dedicated checker first so missing docs, helper scripts, wrapper
commands, or the raw headed probe fail fast before you trust this narrower
saved-homepage checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_homepage_fixture_validation_surface.ps1
```

That checker verifies this dedicated note, the broader issue `#3` notes that
route into and out of this slice, the Windows runbook, the shared suite router,
the homepage-fixture flow helper, the wrapper runner, and the raw saved-page
probe.

## Start with the printed flow

After the surface check is green, use the dedicated flow helper when you want
the current command order printed before you run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
```

That helper keeps the dedicated surface check, the wrapper runner, and the raw
probe on one small command surface before you widen again.

## Fastest bounded runner

When you want the reusable homepage-fixture slice in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
```

Use the wrapper when the earlier reduced homepage gate is already green and the
next question is whether the saved Google-style fixture still preserves focus,
typed text, and Enter submit on the real headed Win32 surface.

## Raw probe fallback

When you need the exact underlying saved-homepage probe without the wrapper
layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\chrome-google-homepage-probe.ps1
```

Prefer the wrapper unless you specifically need the raw probe output files from
`tmp-browser-smoke\form-controls`.

## What success looks like

Treat the homepage-fixture slice as green only when all of these remain true:

- the saved Google homepage fixture still reaches the expected focus marker
- the same fixture still reaches the expected typed-text marker on the real
  headed surface
- the Enter path still reaches the submitted page on the same bounded fixture
- the wrapper and raw probe still agree with the broader submit-path and
  submit-timing slices when you widen again

If this slice fails, fix it before widening into the later submit-path ladder,
the bounded submit-timing slice, the shared Enter-order stack, attached HTML
follow-up, or the live Google homepage trace path.

## When to widen again

After this bounded slice is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1` when the next question is the broader later-stage saved-homepage, submit-timing, and shared Enter-order handoff
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1` when you want the bounded Google-shaped keypress-before-submit slice printed before you run it
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when you want the stricter shared Enter-order ladder printed before you run it

## Working rule

Do not jump from the reduced homepage pass straight to the live Google homepage
when the branch already provides this saved-homepage checkpoint.

Keep the homepage-fixture slice green first, then widen back out to the later
submit-path ladder, the submit-timing slice, the shared Enter-order stack, or
the live headed homepage only as needed.
