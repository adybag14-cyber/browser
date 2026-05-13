# Google Home Keypress-Submit Validation

Use this note when issue `#3` has already cleared the reduced homepage and
saved-homepage fixture checkpoints, and the next question is whether the
reduced homepage keypress-submit probe still proves that Enter stalls at the
keydown edge and only submits after the matching keypress path lands on the real
headed surface.

This note is intentionally narrower than
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md` and
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md`.
It focuses on the small reduced-home real-surface checkpoint that now sits
between the bounded homepage-fixture gate and the broader later submit-path
wrappers.

## Start with the validation surface check

Use the dedicated checker first so missing docs, helpers, wrapper commands, or
the raw headed probe fail fast before you trust this narrower issue `#3`
checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_keypress_submit_validation_surface.ps1
```

That checker verifies the dedicated note, the earlier homepage-fixture note,
the later submit-path note, the Windows runbook, the broader issue `#3` flow
helper, the dedicated flow helper, the wrapper runner, and the raw reduced-home
keypress-submit probe.

## Start with the printed flow

After the surface check is green, use the dedicated helper first when you want
the current command order printed before you run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_keypress_submit_validation_flow.ps1
```

That helper keeps the dedicated surface check, wrapper runner, and raw probe on
one small command surface before you widen again.

## Fastest bounded runner

When you want the reusable reduced-home keypress-submit checkpoint in one
command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_keypress_submit_validation.ps1
```

Use the wrapper when the earlier homepage-fixture checkpoint is already green
and the next question is whether the reduced Google homepage still records
Enter keydown before the later submit marker on the real headed Win32 surface.

## Raw probe fallback

When you need the exact underlying reduced-home headed probe without the
wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1
```

Prefer the wrapper unless you specifically need the raw probe output files from
`tmp-browser-smoke\google-home`.

## What success looks like

Treat the reduced-home keypress-submit checkpoint as green only when all of
these remain true:

- the reduced homepage probe still reaches the expected focus and typed-text
  title states
- the Enter path still pauses at the expected `KEYDOWN:<text>` title before the
  submitted marker appears
- the same headed pass still reaches the later `SUBMIT:<text>` marker on the
  real surface
- the same ordering still agrees with the broader later submit-path wrappers
  when you widen back out

If this checkpoint fails, fix it before widening into the later submit-path
slice, the broader shared Enter-order stack, attached HTML follow-up, or the
live Google homepage.

## When to widen again

After this bounded checkpoint is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1` when you want the broader later-stage saved homepage fixture, submit-timing, and shared Enter-order ladder printed before you run it
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1` when you want the next broader later-stage wrapper on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1` when the next question is the narrower bounded timing slice rather than the full later submit-path ladder
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` only after the reduced-home keypress, later submit-path, and shared Enter-order checkpoints agree

## Working rule

Do not jump from the homepage-fixture checkpoint straight to the broader
submit-path wrappers, attached HTML, or the live Google homepage when the
branch already provides this smaller reduced-home keypress-submit proof.

Keep the reduced-home keypress-submit checkpoint green first, then widen back
out to the submit-path slice, the shared Enter-order ladder, attached-page
follow-up, or the live headed homepage only as needed.
