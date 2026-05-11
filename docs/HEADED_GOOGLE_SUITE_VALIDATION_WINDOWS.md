# Google Suite Validation on Windows

This guide is the shortest read-first companion to the bounded issue `#3`
validation flow on `fork/headed-mode-foundation`.

Use it when you want one compact entry point that checks the validation surface
first, then prints the current localhost, title, homepage-fixture, submit-path,
shared Enter-order, and attached-page follow-up order before you widen into
longer manual replay.

## Quick Start

Fail fast if a linked guide or helper drifted out of sync:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile attached-html
```

Use the default profile for the main issue `#3` guides and helpers. Use the
`attached-html` profile when the next follow-up depends on the saved-page or
attached-page localhost handoff.

Print the compact suite flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_suite_validation_flow.ps1
```

Print the broader issue `#3` flow when you want the same fail-fast checker and
step ordering surfaced through the larger reusable helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

Print the same compact flow with the manual follow-up flags that will be passed
through to the one-command recommended runner:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_suite_validation_flow.ps1 `
  -ManualPort 8123 `
  -ManualInitialPage google-saved-page.html `
  -ManualGoogleStyle `
  -LeaveOpen
```

## Shared Entry Points

Use these commands when you want the same issue `#3` work surfaced through the
broader Windows validation router before you drop into the compact helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-title
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-homepage-fixture
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-submit-path
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

That keeps the compact suite guide aligned with the shared validation index
instead of making future runs choose between two separate routing surfaces.

## What It Covers

The helper keeps these checks in one printed order:

1. Run the validation-surface checker.
2. Read the reduced title marker guide.
3. Read the narrower bounded title flow.
4. Read the saved homepage fixture flow when the next follow-up is itself a captured Google homepage.
5. Read the dedicated shared form-controls Enter-order flow.
6. Run the current one-command localhost-first issue `#3` validation pass.
7. Run the dedicated submit-path runner when the earlier title gates are already green and you want the saved homepage fixture, submit-timing, and shared Enter-order stack without replaying the earlier localhost title phases.
8. Only after those bounded passes are green, widen into attached or saved-page follow-up.

## Why It Exists

The branch already has several useful issue `#3` helpers, but the first-run
question is often still "which one should I read or run first?"

`show_google_suite_validation_flow.ps1` answers that without making the next
Windows headed run reconstruct the ordering from multiple guides.

`show_google_input_validation_flow.ps1` keeps the same checker-first ordering
available on the broader reusable issue `#3` flow instead of only on the
compact guide.

`check_google_validation_surface.ps1` complements both helpers by failing fast
when a future edit removes or renames one of the linked guides or helper
scripts.

## Working Rule

Do not use the attached-page or live-Google passes as the first evidence for
issue `#3`.

Run `check_google_validation_surface.ps1` first after guide or helper edits,
keep the localhost, title, homepage-fixture, submit-path, submit-order, and
shared Enter-order gates aligned first, and treat `KEYDOWN:<text>|13|13` before
`SUBMIT:<text>` as the bounded acceptance edge for Enter-order work.
