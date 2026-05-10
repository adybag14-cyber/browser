# Google Suite Validation on Windows

This guide is the shortest read-first companion to the bounded issue `#3`
validation flow on `fork/headed-mode-foundation`.

Use it when you want one compact entry point that prints the current localhost,
title, shared Enter-order, and attached-page follow-up order before you widen
into longer manual replay.

## Quick Start

Print the compact suite flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_suite_validation_flow.ps1
```

Check that the compact issue `#3` validation surface is still present on the
current checkout before you rely on the broader flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile attached-html
```

Use the default profile for the main issue `#3` guides and helpers. Use the
`attached-html` profile when the next follow-up depends on the saved-page or
attached-page localhost handoff.

Print the same flow with the manual follow-up flags that will be passed through
to the one-command recommended runner:

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
```

That keeps the compact suite guide aligned with the shared validation index
instead of making future runs choose between two separate routing surfaces.

## What It Covers

The helper keeps these checks in one printed order:

1. Read the reduced title marker guide.
2. Read the narrower bounded title flow.
3. Read the dedicated shared form-controls Enter-order flow.
4. Run the current one-command localhost-first issue `#3` validation pass.
5. Only after those bounded passes are green, widen into attached or saved-page follow-up.

## Why It Exists

The branch already has several useful issue `#3` helpers, but the first-run
question is often still "which one should I read or run first?"

`show_google_suite_validation_flow.ps1` answers that without making the next
Windows headed run reconstruct the ordering from multiple guides.

`check_google_validation_surface.ps1` complements it by failing fast when a
future edit removes or renames one of the linked guides or helper scripts.

## Working Rule

Do not use the attached-page or live-Google passes as the first evidence for
issue `#3`.

Keep the localhost, title, submit-order, and shared Enter-order gates aligned
first, and treat `KEYDOWN:<text>|13|13` before `SUBMIT:<text>` as the bounded
acceptance edge for Enter-order work.
