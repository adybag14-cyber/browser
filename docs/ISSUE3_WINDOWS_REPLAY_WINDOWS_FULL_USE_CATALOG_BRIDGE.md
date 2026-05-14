# Issue #3 Windows Replay Windows-Full-Use Catalog Bridge

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` is already open but the next replay should still stay aligned with the newer Windows full-use attached-localhost catalog helper before the route narrows again.

This keeps the replay quickstart, `docs/WINDOWS_FULL_USE.md`, and the dedicated Windows-full-use attached-html catalog helper on one read-first route without reopening the broader suite-catalog, replay-route, or safe-route notes first.

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the replay quickstart, reopen the Windows full-use attached-page route only long enough to surface the dedicated Windows-full-use catalog helper, then move back into the narrower attached-page catalog chain before widening into replay shortcuts or the wrapper-heavy safe route.

## Default read-first route

Use this route when the attached localhost compatibility lane is already obvious and no pinned bundle inputs or saved replay state need to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:

- the replay quickstart is already open but the broader Windows full-use route still matters for the next attached-page follow-up
- you want the dedicated Windows-full-use catalog helper surfaced before the narrower top-level attached-page catalog quickstart
- the suite-catalog attached-page bridge should stay visible before the route narrows into replay shortcuts or the safe-route map

## Preserve replay context

If the replay already carries a non-default repo root, saved summary output, or pinned attached bundle paths, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned across later helpers
- the next route should reuse a saved `SummaryPath` instead of regenerating outputs first
- explicit `InputPath` values are already pinned to the known attached compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`

Use this when the replay quickstart already made issue `#3` obvious but you still want the dedicated Windows-full-use catalog helper printed before the narrower top-level attached-page catalog route.

2. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when the broader validation catalog should stay visible beside the attached-page chain before the route narrows again.

3. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when the route is already clearly on attached localhost follow-up and you want the compact top-level attached-page catalog helper surfaced immediately.

4. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog-side attached-page bridge should stay visible before replay shortcuts or the safe-route map.

5. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside the smaller issue `#3` helper chain and you want the tightest next helper surface.

6. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the route has already narrowed enough that the wrapper-heavy recovery or handoff surfaces need to take over.

## Practical rule

Once `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` has already pointed the next run at attached localhost follow-up, reopen the Windows full-use route only long enough to print `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, then move back into the narrower attached-page catalog chain.
