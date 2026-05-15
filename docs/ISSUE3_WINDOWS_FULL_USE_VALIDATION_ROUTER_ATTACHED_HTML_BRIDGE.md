# Issue #3 Windows Full-Use Validation-Router Attached HTML Bridge

Use this note when `docs/WINDOWS_FULL_USE.md` or `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` already narrowed the next headed replay to the attached localhost HTML lane and you want the newer validation-router attached-html quickstart surfaced without losing the Windows-first catalog step that now anchors the narrower attached-page ladder.

This keeps the Windows-full-use route, its route-level fail-fast surface check, the Windows-to-validation-router bridge, the Windows-first attached-html catalog quickstart, the broader validation-router surface, the suite-catalog-to-top-level attached-html catalog quickstart, the suite-catalog attached-html bridge, and the newer attached-page quickstarts aligned in one read-first bridge without reopening the larger suite-catalog, replay-route, or wrapper-heavy safe-route notes first.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the Windows full-use attached-page route, rerun the route-level validation-surface check, reopen the Windows-to-validation-router bridge and the newer Windows-first attached-html catalog quickstart, then move through the validation-router attached-html quickstart, the suite-catalog-to-top-level attached-html catalog quickstart, the suite-catalog attached-html bridge, and the smaller attached-page helpers before widening into replay shortcuts or the wrapper-heavy safe route.

## Default read-first route

Use this route when the attached localhost compatibility lane is already obvious and no pinned bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- the replay is already centered on the attached localhost compatibility pages
- you want the route-level fail-fast surface check, the Windows-to-validation-router bridge, the Windows-first attached-html catalog quickstart, and the validation-router surface check visible before the route narrows into the smaller attached-page quickstarts
- you still want the attached-html change-area quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-html catalog quickstart, the suite-catalog attached-html bridge, and the suite-router attached-page quickstart visible before the route widens again

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, rerun the route-level surface checks first, then keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through the later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known attached three-page compatibility bundle

## Pick the next checkpoint quickly

1. `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`

Use this first when the broader Windows full-use route already made attached localhost follow-up obvious and you want the route-level fail-fast check rerun before narrowing into the validation-router and attached-page helper chain.

2. `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`

Use this next when the Windows full-use route has already made attached localhost follow-up obvious but you still want the broader Windows-to-validation-router bridge surfaced before the route narrows again.

3. `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`

Use this next when the Windows-first catalog step should stay visible beside the narrower validation-router and attached-page quickstarts before the route collapses further.

4. `check_google_issue3_validation_router_attached_html_quickstart_surface.ps1`

Use this next when you want a fast check that the validation-router note, helper script, and downstream attached-page surfaces still line up before trusting the narrower helper ladder.

5. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this next when the Windows full-use route has already made attached localhost follow-up obvious but you still want the broader validation-router bridge surfaced before the route narrows again.

6. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this next when the replay has already reopened `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the broader attached-page flow helper kept visible beside the newer quickstarts.

7. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when you want the shortest top-level attached-page bridge kept visible before the route narrows again.

8. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when you want the broader top-level attached-page bridge reprinted beside the compact quickstart before the route narrows again.

9. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level attached-page route plus the suite-catalog-side attached-page bridge preserved before the route narrows again.

10. `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the suite-catalog-side handoff back in view so the validation-router lane stays aligned with the current catalog ladder before it narrows again.

11. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog attached-page bridge should stay visible after the top-level catalog quickstart before you drop to the shortcut surface or replay shortcuts.

12. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route should stay on the suite-router side of the attached-page helper chain before choosing between the shortcut surface, replay shortcuts, or the next-step matrix.

13. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page route is already clear and you want the shortest bridge before widening into replay shortcuts or the safe-route map.

14. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

## Practical rule

When the Windows full-use route already made attached localhost follow-up the next obvious branch, reopen `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, then `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, then `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, then `check_google_issue3_validation_router_attached_html_quickstart_surface.ps1` before dropping to `show_google_issue3_validation_router_attached_html_quickstart.ps1`, the attached-html change-area quickstart, the smaller top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-html catalog quickstart, the suite-catalog attached-html bridge, or the suite-router attached-page quickstart. That keeps the broader Windows-first route, the catalog step, the validation-router view, and the newer suite-catalog handoff aligned while still letting the replay narrow quickly once the next helper is obvious.
