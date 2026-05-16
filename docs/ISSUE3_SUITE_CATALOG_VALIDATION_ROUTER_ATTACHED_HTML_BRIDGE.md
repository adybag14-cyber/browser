# Issue #3 Suite-Catalog Validation-Router Attached HTML Bridge

Use this note when issue `#3` replay is reopening from the broader suite-catalog surface and you want one compact bridge into the validation-router attached-html quickstart before the route narrows back into the top-level attached-page helpers.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_validation_router_attached_html_bridge.ps1
```

If the replay already carries a non-default repo root, a saved summary, or pinned attached-page inputs, preserve that state directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`

## Goal

Start from the suite-catalog guide, keep the compact suite-catalog surface check visible, reprint the attached-html and Google-attached-html suite-catalog entrypoints, then move straight into the validation-router attached-html surface check and quickstart while keeping the broader attached-page flow helper, the Google-shaped attached-page flow helper, the Windows replay attached-html quickstart, and the narrower top-level follow-ups close at hand.

## Read-first route

Use this route when the replay is still entering from the broader suite catalog:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when the suite-catalog lane is still the main read-first surface but the replay is clearly headed toward the validation-router attached-html quickstart.

## Pick the next helper quickly

1. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this as the default next helper when there is no pinned bundle input to preserve first.

2. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this when the replay already narrowed through `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the broader attached-page flow helper plus the validation-router quickstart visible together.

3. `show_attached_html_validation_flow.ps1`

Use this when the route is still ambiguous and the broader attached-page localhost helper should stay open before the validation-router quickstart narrows again.

4. `show_google_attached_html_validation_flow.ps1`

Use this when the current attached-page set already includes a Google-like page and the Google-shaped flow should stay visible before the route narrows again.

5. `show_google_issue3_windows_replay_attached_html_quickstart.ps1`

Use this when the replay is already back on the Windows replay attached-html lane and you want that replay-side branch reprinted before the validation-router quickstart.

6. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit attached-page inputs are already pinned to the current three-page compatibility set and the replay should stay bundle-first before widening back into the broader issue `#3` helper chain.

## Practical rule

Reopen the suite-catalog guide first, then fail fast on the suite-catalog surface, then move directly into the validation-router attached-html surface check and quickstart. Keep the broader attached-page flow helper nearby when the route is still ambiguous, keep the Google-shaped attached-page flow nearby when the current input set already includes a Google-like page, and keep the bundle-first helper nearby when explicit attached-page inputs are already pinned to the current three-page compatibility set.
