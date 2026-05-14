# Issue #3 Attached HTML Validation Entrypoints

Use this note when the headed Windows replay for issue `#3` has already narrowed to attached localhost follow-up and you want one compact map of the current command surfaces.

Keep these companion notes nearby:
- `docs/HEADED_MODE_VALIDATION_GATES.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`

## Start from the broadest surface that still matches the current replay

If you are still choosing the next branch from the main validation router, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

If attached localhost follow-up is already the obvious next branch, reopen the dedicated attached-page change area first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

If the replay still needs the Google-shaped attached-page branch visible before it narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

## Known three-page compatibility bundle

When the current inputs are still the pinned three-page compatibility set, keep the route pinned to the bundle-aware surface first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when you want the current three-page bundle, its preferred initial page, and its follow-up commands to stay pinned before widening back into the broader issue `#3` helper chain.

If the bundle replay still needs the compact issue-specific bridge afterwards, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

## Top-level attached-page bridge

Once the replay is clearly inside attached localhost follow-up, use the compact top-level bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when you want the shorter top-level attached-page handoff visible before widening into the suite-router quickstart, replay shortcuts, or the safe-route map.

## Windows runbook re-entry

If the replay is being reopened from the Windows full-use runbook instead of from the suite router, print the dedicated re-entry helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

Use that route when the broader Windows headed runbook already made attached localhost follow-up the next obvious issue `#3` branch and you want that re-entry point visible before dropping back to the compact top-level helper chain.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or explicit input paths, keep that context attached to whichever helper you print next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

Use the same context-preserving flags on the next helper in the chain so the replay does not lose the working tree, saved summary, or pinned bundle inputs it already depends on.

## Quick chooser

1. Use `attached-html-target-bundle` first when the current pages are still the known three-page compatibility set.
2. Use `attached-html` first when attached localhost follow-up is known but the route should stay broad enough to keep `show_attached_html_validation_flow.ps1` visible.
3. Use `google-attached-html` first when the replay still needs the Google-shaped attached-page route printed before narrowing again.
4. Use `show_google_issue3_windows_full_use_attached_html_route.ps1` first when reopening from `docs/WINDOWS_FULL_USE.md`.
5. Use `show_google_issue3_top_level_attached_html_quickstart.ps1` first when the replay is already clearly inside the shorter issue-specific attached-page helper chain.
