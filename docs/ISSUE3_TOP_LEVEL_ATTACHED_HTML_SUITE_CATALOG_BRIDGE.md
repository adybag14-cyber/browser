# Issue #3 Top-Level Attached HTML Suite-Catalog Bridge

Use this note when issue `#3` replay is already narrowed to the top-level attached localhost route and you want the newer suite-catalog guide kept visible before the helper chain drops into the narrower attached-page bridge or shortcut helpers.

Keep these companion notes nearby:
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`

## Goal

Keep the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level catalog quickstart, the dedicated suite-catalog guide, and the suite-catalog attached-page bridge aligned in one short written route before the replay narrows into the suite-router sidecar, the attached-page shortcut, replay shortcuts, or the safe-route map.

## Default read-first route

Use this route when no explicit bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:
- the attached localhost branch is already obvious from the top-level side
- you want the dedicated suite-catalog guide reprinted before the route narrows into the suite-catalog attached-page bridge
- the replay still benefits from keeping the suite-router sidecar visible before collapsing to the tighter shortcut helpers

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known attached three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_suite_catalog_entrypoints.ps1`

Use this when you want the dedicated suite-catalog guide reprinted before the narrower suite-catalog attached-page bridge.

2. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog-side attached-page bridge should stay visible immediately after the guide.

3. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the replay should keep the narrower suite-router sidecar visible before choosing the attached-page shortcut or replay shortcuts.

4. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page route is already clear and you want the shortest bridge before widening into replay shortcuts or the safe-route map.

5. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

## Practical rule

Once the top-level attached localhost route is already in focus, prefer the top-level quickstart, then the top-level catalog quickstart, then the suite-catalog-to-top-level catalog quickstart, then the dedicated suite-catalog guide, then the suite-catalog attached-page bridge before reopening the shorter suite-router or shortcut-only surfaces.
