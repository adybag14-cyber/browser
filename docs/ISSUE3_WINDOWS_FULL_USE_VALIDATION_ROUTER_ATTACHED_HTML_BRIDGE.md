# Issue #3 Windows Full-Use Validation-Router Attached HTML Bridge

Use this note when `docs/WINDOWS_FULL_USE.md` or `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` already narrowed the next headed replay to the attached localhost HTML lane and you want the newer validation-router attached-html quickstart surfaced before the route drops back into the smaller attached-page helpers.

This keeps the Windows-full-use route, the broader validation-router surface, and the newer attached-page quickstarts aligned in one read-first bridge without reopening the larger suite-catalog, replay-route, or wrapper-heavy safe-route notes first.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the Windows full-use attached-page route, reopen the broader validation-router attached-html quickstart long enough to surface the newer compact attached-page chain, then move back into the shorter attached-html quickstarts before widening into replay shortcuts or the wrapper-heavy safe route.

## Default read-first route

Use this route when the attached localhost compatibility lane is already obvious and no pinned bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- the replay is already centered on the attached localhost compatibility pages
- you want the broader validation-router bridge visible before the route narrows into the smaller attached-page quickstarts
- you still want the attached-html change-area quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the suite-router attached-page quickstart visible before the route widens again

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through the later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known attached three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this first when the Windows full-use route has already made attached localhost follow-up obvious but you still want the broader validation-router bridge surfaced before the route narrows again.

2. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this next when the replay has already reopened `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the broader attached-page flow helper kept visible beside the newer quickstarts.

3. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when you want the shortest top-level attached-page bridge kept visible before the route narrows again.

4. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level attached-page route plus the suite-catalog-side attached-page bridge preserved before the route narrows again.

5. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route should stay on the suite-router side of the attached-page helper chain before choosing between the shortcut surface, replay shortcuts, or the next-step matrix.

6. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page route is already clear and you want the shortest bridge before widening into replay shortcuts or the safe-route map.

7. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

## Practical rule

When the Windows full-use route already made attached localhost follow-up the next obvious branch, reopen `show_google_issue3_validation_router_attached_html_quickstart.ps1` before dropping back to the attached-html change-area quickstart, the smaller top-level attached-page quickstart, the top-level attached-page catalog quickstart, or the suite-router attached-page quickstart. That keeps the broader validation-router view aligned with the Windows-first route while still letting the replay narrow quickly once the next helper is obvious.
