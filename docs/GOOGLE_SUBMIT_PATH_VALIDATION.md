# Google Submit-Path Validation

Use this note when issue `#3` has already cleared the earliest reduced title
and homepage gates, and the next question is whether the later submit path is
still coherent before you widen back out to attached HTML or the live Google
homepage.

This guide is intentionally narrower than
`docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md` and
`docs/HEADED_GOOGLE_SUITE_VALIDATION_WINDOWS.md`.
It focuses on the middle slice that now sits between the reduced homepage pass
and the broader attached-page or live trace follow-up.

## When To Use It

Reach for this note when all of these are true:

- the reduced localhost Google-style probes are already green
- the bounded title wrapper or quick title-plus-watch pass is already green
- the reduced homepage pass is already green
- you still want one more controlled checkpoint before attached HTML or live
  Google replay

## Start with the printed flow

Use the dedicated helper first when you want the current command order printed
before you run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1
```

That helper keeps the saved homepage fixture checkpoint, the submit-timing
wrapper, and the shared Enter-order ladder aligned on one reusable command
surface.

## One-command runner for the later submit path

When the earlier title and homepage gates are already green, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1
```

Use this runner when you want the saved homepage fixture checkpoint, the bounded
submit-timing slice, and the shared Enter-order ladder without replaying the
entire earlier issue `#3` stack.

## Narrowing order

If the later submit path still needs isolation, use this smaller order:

1. Saved homepage fixture flow helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
```

2. Saved homepage fixture runner

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
```

3. Submit-path flow helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1
```

4. Submit-timing flow helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1
```

5. Submit-timing runner

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1
```

6. Shared Enter-order flow helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1
```

7. Shared Enter-order runner

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
```

8. Dedicated shared form-controls Enter-order gate when you need the smallest
shared end-state proof

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
```

## What success looks like

Treat the later submit path as green only when all of these remain true:

- the saved homepage fixture still reaches the expected title, focus, text, and
  Enter-submit markers
- the bounded submit-timing slice still keeps `KEYDOWN:<text>|13|13` ahead of
  the final `SUBMIT:<text>` marker
- the shared Enter-order ladder still proves submit completes after keypress on
  the real headed surface
- the dedicated shared form-controls gate still agrees with that same ordering

If one layer fails, fix that layer before widening out to attached HTML,
saved-page manual replay, or the live Google homepage.

## When to widen again

After this submit-path slice is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` when the current run already has Google-like attached HTML snapshots
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait` when the next step is broader localhost follow-up across attached or saved pages
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1` only when the bounded slices agree but the real homepage still diverges

## Working rule

Do not jump from the reduced homepage pass straight to the live Google homepage
when the branch already provides narrower later-stage submit checkpoints.

Keep the saved homepage fixture, submit-timing slice, and shared Enter-order
ladder green first, then widen back out to attached HTML or the live headed
homepage.