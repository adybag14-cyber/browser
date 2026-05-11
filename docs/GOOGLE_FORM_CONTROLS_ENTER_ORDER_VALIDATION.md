# Google Form-Controls Enter-Order Validation

Use this note when issue `#3` has already been narrowed to the smallest shared
Enter-order checkpoint and you want one read-first guide for the dedicated
form-controls gate before widening back out to the broader shared ladder.

This note is intentionally narrower than
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md` and
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md`.
It focuses on the single shared headed Windows proof that submit still lands
after Enter keypress on the Google-style form-controls path.

## Start with the validation surface check

Use the dedicated checker first so missing docs, wrapper scripts, or the raw
headed probe fail before you trust this narrower gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1
```

That checker verifies the dedicated note, the broader shared Enter-order note,
the Windows runbook, the shared discovery routes, the dedicated flow helper,
the trace guide, the wrapper runner, and the raw form-controls probe that this
smallest gate depends on.

## Reconfirm the shared discovery routes

When you are approaching this gate from the broader Windows runbook instead of
opening the dedicated note first, print the shared discovery surfaces before
running anything:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-form-controls-enter-order
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

Those commands should keep the dedicated surface checker, trace guide, wrapper,
and the wider shared Enter-order ladder visible from the same issue `#3`
entrypoints future runs already use.

## Read the trace guide first

Use the quick diagnosis helper after the surface check when you want the
dedicated marker meanings printed before or after a rerun:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1
```

That helper translates the smallest gate's `title_after_click`,
`title_after_type`, `submit_phase`, `event_log`, and
`submit_after_keypress` outputs into short failure stages so you can tell
quickly whether the break stayed before click focus, before visible text entry,
before keypress, or before final submit.

## Start with the printed flow

Use the dedicated helper after the surface check when you want the current
command order printed with the active host, port, and shared text value:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
```

That helper keeps the dedicated surface check, the trace guide, the wrapper,
the raw headed localhost probe, and the wider shared Enter-order escalation
path aligned on one small command surface.

## Fastest bounded runner

When you want the narrowest reusable shared gate in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
```

Use the dedicated runner when the earlier reduced title, homepage-fixture, or
shared Enter-order setup is already green and the next question is whether the
smallest Google-style form-controls checkpoint still records submit after
keypress on the real headed surface.

## Raw probe fallback

When you need the exact underlying probe surface without the wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1
```

Prefer the wrapper unless you specifically need the raw script entrypoint.
The wrapper keeps the common host, timeout, and shared text arguments aligned
with the broader issue `#3` helpers.

## What success looks like

Treat the dedicated gate as green only when all of these remain true:

- the Google-style shared form-controls probe still reaches the expected text value
- click focus still lands before typing
- the Enter path still records the keydown edge before the final submit state
- submit still lands after keypress on the real headed Win32 surface
- the same text and Enter-order expectations still agree with the broader shared Enter-order ladder when you widen back out

If this gate fails, fix it before widening to the saved-homepage fixture,
submit-timing slice, attached HTML follow-up, or live Google replay.

## When to widen again

After this dedicated gate is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when you want the wider shared Enter-order ladder printed again
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1` when you want the reduced homepage, localhost wrapper, and shared Enter-order phases back on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1` when the next question is the later saved-homepage-fixture and submit-timing handoff
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` only after the shared Enter-order stack is green again and the current run already has Google-like HTML snapshots

## Working rule

Do not use this gate as a substitute for the broader shared ladder when the
reduced homepage, localhost wrapper, or submit-timing phases are still suspect.

Use it as the smallest shared end-state proof inside issue `#3`: keep the
dedicated form-controls gate green, then widen back out to the shared
Enter-order ladder, submit-path note, attached-page follow-up, or the live
homepage only as needed.
