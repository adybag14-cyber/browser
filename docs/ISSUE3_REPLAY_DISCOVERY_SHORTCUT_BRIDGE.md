# Issue #3 Replay Discovery Shortcut Bridge

Use this note when `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md` already surfaced the broader issue `#3` validation-router path and the next replay should move quickly into the newer shortcut-first helper chain without reopening the longer route notes first.

Keep these companion notes nearby:
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Default shortcut-first route

Use this route when the broader validation catalog already made attached localhost follow-up obvious and no saved summary or pinned bundle inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that sequence when the replay should stay on the broader attached-page bridge just long enough to keep the suite-catalog guide, the validation-router quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level catalog quickstart, the suite-catalog attached-page bridge, and the suite-router attached-page quickstart visible before the newer shortcut-first route takes over.

## Preserve replay context

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit bundle inputs, preserve that same context directly in the shorter helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when `LIGHTPANDA_REPO_ROOT`, a saved `SummaryPath`, or pinned bundle paths already matter and the replay should keep the same context all the way through the shorter helper ladder.

## Pick the next helper quickly

1. `show_google_issue3_suite_catalog_entrypoints.ps1`

Use this when the broader suite-catalog surface should stay visible beside the attached-page bridge before the shorter helper chain takes over.

2. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when `show_headed_validation_suites.ps1 -ChangeArea attached-html` is already open and you want the shortest validation-router-side attached-page bridge before the top-level attached-page notes reopen.

3. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when the top-level suite router already narrowed replay to attached localhost follow-up and you want the shortest top-level attached-page bridge before the broader top-level route note or the suite-catalog bridge reopen.

4. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this when the broader attached-page bridge is already clear and you want the narrowest suite-router-side shortcut surface before replay-route, replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route map.

5. `show_google_issue3_replay_route.ps1`

Use this when the replay should still keep the attached-bundle branch, the suite-router handoff, and the runner-state helper visible beside the shortcut chain.

6. `show_google_issue3_replay_route_shortcut_entrypoint.ps1`

Use this when `show_google_issue3_replay_route.ps1` is already open and you want the smaller replay-route follow-up surface before replay shortcuts, the next-step matrix, the bundle-first helper, or the safe-route map.

7. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned to the known three-page compatibility set and the route should stay on that bundle before widening back into the broader safe path.

8. `show_google_issue3_safe_route_entrypoints.ps1`

Use this only after the route has narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical rule

From `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`, prefer the broader validation-router entrypoints first until attached localhost follow-up is clearly the next branch. Once that branch is obvious, keep the attached-page bridge visible through the change-area quickstart, the validation-router attached-page quickstart, the top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, and the suite-router attached-page quickstart, then reopen `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` before dropping into `show_google_issue3_replay_route.ps1`, `show_google_issue3_replay_route_shortcut_entrypoint.ps1`, replay shortcuts, or the safe-route map.

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, rerun `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, then reopen `show_google_issue3_windows_full_use_attached_html_route.ps1`, `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, and `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1` before following the same shorter attached-page and shortcut-first route.

Widen back into the longer validation-chain notes only when the shortcut-first helper chain stops being enough.