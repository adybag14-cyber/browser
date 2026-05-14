# Headed Windows Localhost Validation Quickstart

Use this note from the repo root when you want the shortest path into headed Windows validation, saved-page replay, or the current attached localhost HTML follow-up for issue `#3`.

This is a compact bridge. It does not replace the broader runbooks.

## Read first

- `docs/WINDOWS_FULL_USE.md` for the headed Windows build and runbook
- `docs/HEADED_MODE_VALIDATION_GATES.md` for the bounded suite ladder and the issue `#3` validation order
- `tmp-browser-smoke/README.md` for the probe suite index and saved-page helper inventory

## Fast attached-page route

When the next replay is attached or saved localhost HTML, start with the shared validation router and then use the one-command localhost runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
```

Use the `-GoogleStyle` form when the next replay should prefer a Google-like saved page first and stay on the issue `#3` localhost-first ladder before the manual headed retest.

## Pinned three-page bundle

When the inputs are the known three-page compatibility bundle, keep the bundle-specific gate in front of launch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Issue #3 follow-up

For the headed Windows Google input and submit track, keep the attached-page pass behind the bounded issue `#3` ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Only widen to a manual headed retest after the bounded localhost gates are green.

## Practical rule

Start with the smallest bounded suite that matches the surface you changed. Use this quickstart when you already know the next pass is a Windows headed localhost replay and you want the first command sequence without reopening the larger helper chain by hand.
