# Issue #3 Attached HTML Change-Area Flow Surfacing

Use this note when issue `#3` replay has already narrowed to `show_headed_validation_suites.ps1 -ChangeArea attached-html`, but the next step still needs the broader attached-page localhost flow kept visible beside the pinned three-page bundle route.

## Goal

Keep the two attached-page follow-up lanes visible from the same top-level change-area entry:

- the broader attached-page localhost flow for current-run attached HTML follow-up
- the pinned three-page compatibility bundle route when the current inputs still match the known bundle

This note is the short bridge for that gap until the top-level router surface itself prints both helpers directly from the same `-ChangeArea attached-html` output.

## Default read-first sequence

Use this sequence when the replay is already narrowed to the attached localhost compatibility path and no saved summary, repo-root override, or explicit bundle input paths need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
```

Use that route when you want the broader attached-page localhost helper surfaced first, while still keeping the compact issue `#3` attached-page quickstarts and the pinned bundle-first route nearby.

## Bundle-first variant

If the current replay inputs are already pinned to the known three-page compatibility bundle, keep the same bundle context attached from the start:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay locked before widening back into the broader attached-page helper chain.

## Context-preserving variant

If the replay already carries a non-default repo root, a saved summary, or explicit bundle paths, reopen the attached-html change-area quickstart with that same context first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower next helper that matches the current state:

- `show_attached_html_validation_flow.ps1` when the broader attached-page localhost path still needs to stay visible
- `show_google_issue3_top_level_attached_html_quickstart.ps1` when the replay can narrow into the compact issue `#3` attached-page bridge
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` when the suite-router-side attached-page branch should stay visible before widening again
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit bundle paths already matter more than the broader attached-page helper chain

## Practical rule

Once `show_headed_validation_suites.ps1 -ChangeArea attached-html` has already made attached localhost follow-up the next obvious branch, prefer `show_google_issue3_attached_html_change_area_quickstart.ps1` immediately after it whenever you still need both of these surfaced together:

- the broader attached-page localhost flow helper
- the pinned three-page bundle route

Keep these companion notes nearby when you need more written route detail:

- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
