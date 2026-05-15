# Issue #3 Windows Replay Attached HTML Quickstart

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the next replay to the attached localhost HTML lane and you want the shortest written ladder that matches `show_google_issue3_windows_replay_attached_html_quickstart.ps1`.

This keeps the route-level fail-fast check, the Windows-full-use bridge, the validation-router attached-page quickstart, the attached-html change-area quickstart, the smaller top-level attached-page helpers, and the suite-catalog-to-top-level attached-html catalog bridge aligned in one read-first guide before the route narrows into shortcuts or widens back into the safe-route stack.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the Windows replay attached-page lane, rerun the route guard when needed, reopen the Windows-full-use and validation-router attached-page bridges long enough to keep the broader route visible, then move through the narrower attached-page helpers in the same order printed by `show_google_issue3_windows_replay_attached_html_quickstart.ps1`.

From there, prefer one of these narrower follow-ups before reopening the wrapper-heavy safe-route stack:
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first route

Use this route when no pinned bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
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
- you want the route-level fail-fast check and the broader Windows-full-use and validation-router bridges visible before the route narrows into the smaller attached-page quickstarts
- you still want the attached-html change-area quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-html catalog quickstart, the suite-catalog attached-page bridge, and the suite-router sidecar helper visible before the route collapses into the narrower shortcut surface

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, rerun the route guard first, then keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

## Pinned bundle-first route

If the current pages are already the known three-page compatibility bundle, keep the replay on that locked path before widening back into the broader issue `#3` helper stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the replay should stay pinned to the saved three-page compatibility bundle before widening back into replay shortcuts or the safe-route map.

## Pick the next helper quickly

1. `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`

Use this first when the broader Windows route already made attached localhost follow-up obvious and you want a fail-fast check before trusting the narrower helper ladder.

2. `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`

Use this next when the Windows-full-use route should stay visible beside the narrower validation-router and attached-page helpers.

3. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this next when you still want the broader validation-router attached-page bridge visible before the route narrows again.

4. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this next when the replay already reopened `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the broader attached-page flow helper kept visible beside the newer quickstarts.

5. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when you want the shortest top-level attached-page bridge kept visible before the route narrows again.

6. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when you want the broader top-level attached-page bridge reprinted beside the compact quickstart before the route narrows again.

7. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level attached-page route plus the suite-catalog-side attached-page bridge preserved before the route narrows again.

8. `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the replay-side attached-page ladder, the top-level attached-page catalog quickstart, and the suite-catalog-side bridge kept visible on the same surface before the route narrows again.

9. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when you want the suite-catalog-side attached-page bridge without reopening broader router helpers first.

10. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route should keep the suite-router-side helper visible before collapsing to the shorter shortcut surface.

11. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page route is already clear and you want the shortest bridge before widening into replay shortcuts, contextual flow, bundle-first helper reuse, or the safe-route map.

12. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

## Practical rule

When `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already made attached localhost follow-up the next obvious branch, reopen the route-level surface check first, then keep the Windows-full-use bridge, the validation-router attached-page quickstart, the attached-html change-area quickstart, the top-level attached-page quickstarts, and the suite-catalog-to-top-level attached-html catalog bridge in view before dropping to the shorter shortcut surface.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: keep the broader Windows-full-use route and its validation-router bridge in front of the narrower attached-page quickstarts
- replay already narrowed to `-ChangeArea attached-html`: keep `show_google_issue3_attached_html_change_area_quickstart.ps1` and the broader attached-page flow helper beside this note so the shorter change-area bridge stays visible before the route widens again
- explicit bundle paths already pinned: switch to the bundle-first helper after the change-area quickstart so the known three-page compatibility set stays fixed before widening back into the broader Google-only path
- saved summary or repo-root override already present: pass the same replay context through the broader route guard, the narrower helper chain, and the suite-catalog-to-top-level attached-html catalog quickstart so later follow-ups stay aligned

Only widen back into the longer validation-chain notes after the route has narrowed as far as it can go with the compact attached-page ladder.
