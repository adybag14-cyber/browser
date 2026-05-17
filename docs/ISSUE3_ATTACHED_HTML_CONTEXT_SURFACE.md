# Issue #3 Attached HTML Context Surface

Use this note when attached localhost replay already matters and you want one
compact helper that keeps the broader attached-page lane, the narrower
Google-shaped attached-page lane, and the pinned three-page bundle lane visible
with the same replay context before the route narrows again.

This note matches `show_google_issue3_attached_html_context_surface.ps1`.

## Goal

Keep these branches on one printed surface before choosing the next helper:

- the broader attached-page router from `show_headed_validation_suites.ps1`
- the dedicated Google-shaped attached-page follow-up lane
- the pinned attached-html target-bundle route for the known three-page
  compatibility set

Use that compact surface when you do not want to re-derive the first attached
HTML branch by hand after a replay restart.

## Run the helper

Use the helper directly when you want the current replay context printed with
its recommended next command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_context_surface.ps1
```

If the replay is already using a non-default checkout, a saved summary, or
explicit attached-page inputs, preserve that same context on the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_context_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## What it keeps visible

The helper keeps these top-level entrypoints on the same surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

It also keeps these narrower helpers nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Recommended next move

The helper already chooses a default next command from current replay context:

- explicit `InputPath` values pinned: prefer the bundle-first helper
- non-default `RepoRoot` or saved `SummaryPath` already in play: reopen the
  broader suite-catalog route with that same context preserved
- no saved replay context pinned yet: fail fast on the Google-shaped attached
  page surface before choosing the broader or bundle-first branch

Use the helper itself first when you want that recommendation printed beside the
command surface instead of re-deriving it manually.

## Practical rule

Use `show_google_issue3_attached_html_context_surface.ps1` after the route has
already narrowed to attached localhost follow-up but before you commit to the
broader attached-page flow, the dedicated Google-shaped attached-page flow, or
the pinned bundle lane.

- broader attached-page compatibility still matters: keep `attached-html`
  visible and reopen `show_attached_html_validation_flow.ps1`
- Google-shaped attached-page follow-up is the most likely next branch: run the
  dedicated Google attached-page surface check before narrowing further
- the current inputs are still the known three-page compatibility bundle: keep
  the bundle surface checker, bundle flow helper, and bundle-first helper on the
  same printed lane before widening back into broader issue `#3` helpers

## Companion notes

Keep these notes nearby when you want the written route beside the helper:

- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
