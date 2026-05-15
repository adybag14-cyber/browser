# Issue #3 Replay Discovery Handoff

Use this note when issue `#3` needs the fastest read-first bridge from the top-level headed validation catalog into the current attached localhost replay helpers on `fork/headed-mode-foundation`.

Keep this note beside:
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Read-first baseline

Start from the shared issue `#3` router when you need the broader Google validation lane reprinted first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

If the next replay is already obviously attached-page-first, reprint the attached localhost branch directly from the top-level suite router first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Use `attached-html` when the generic three-page compatibility route should stay visible. Use `google-attached-html` when the Google-shaped attached-page helper should stay visible. Use `attached-html-target-bundle` when the current saved or attached inputs are already the pinned three-page compatibility bundle.

## Attached localhost re-entry

If you are reopening the route from `docs/WINDOWS_FULL_USE.md`, keep the broader Windows-first branch visible long enough to rerun its fail-fast route checker and reopen the newer validation-router and catalog-side bridge before the narrower top-level attached-page helpers take over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when the broader Windows runbook already made attached localhost follow-up obvious and you want the route-level surface checker, the validation-router attached-html bridge, the Windows-first catalog quickstart, and the narrower top-level note family all describing the same re-entry order.

When the top-level suite router already made attached localhost follow-up obvious, prefer this compact chain:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use the same helper order after `-ChangeArea google-attached-html` when the replay still needs the Google-specific attached-page bridge visible first. Use the same helper order after `-ChangeArea attached-html-target-bundle` when the route should stay pinned to the known three-page bundle before widening back into the broader safe-route chain.

If the replay already carries a non-default checkout, a saved summary, or explicit bundle inputs, preserve that same context on the helper that you open next by passing `-RepoRoot`, `-SummaryPath`, and `-InputPath` directly to the chosen helper.

## Choose The Next Helper Quickly

- `show_google_issue3_windows_full_use_attached_html_route.ps1`: use this when the replay is reopening directly from `docs/WINDOWS_FULL_USE.md` and the broader Windows-side attached-page route should stay visible first.
- `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`: use this before narrowing back into the attached-page helper chain when the Windows-first route was the last broader branch and you want missing helpers or renamed notes to fail fast.
- `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`: use this when the Windows-first route should keep the validation-router handoff visible before the narrower top-level attached-page helpers take over.
- `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`: use this when the Windows full-use branch should keep the catalog-side attached-page quickstart visible beside the narrower top-level helper chain.
- `show_google_issue3_top_level_attached_html_quickstart.ps1`: use this first when the top-level suite router already narrowed replay to attached localhost follow-up and you want the shortest top-level attached-page bridge before the broader attached-page notes reopen.
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`: use this when you want the broader top-level attached-page bridge reprinted before the route narrows into the newer suite-router or suite-catalog attached-page helpers.
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`: use this when the compact top-level attached-page route and the suite-catalog-side bridge should stay visible together before the replay narrows again.
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`: use this when the route is already inside attached-page follow-up and you want the suite-router-side attached-page bridge kept visible before choosing between the catalog bridge, the attached-page shortcut, replay route, replay shortcuts, or the safe-route map.
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`: use this when the suite-catalog-side attached-page bridge should stay visible before the route narrows again.
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`: use this when the attached-page compatibility branch itself should stay visible before widening into replay route, replay shortcuts, the next-step matrix, or the safe-route map.
- `show_google_issue3_replay_route.ps1`: use this when the attached-page helper chain is already established and you want the current replay-route surface printed before you drop into the narrower replay-route shortcut helper.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use this when `show_google_issue3_replay_route.ps1` is already open and you want the smaller replay-route companion surface before widening into replay shortcuts, the next-step matrix, the bundle-first branch, or the safe-route map.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use this when `InputPath` is already pinned to the known three-page compatibility set.
- `show_google_issue3_replay_shortcuts.ps1`: use this when the route is already clear and you want the narrowest stable helper surface.
- `show_google_issue3_suite_router_next_steps.ps1` or `show_google_issue3_contextual_flow.ps1`: use these when you still need the executable branch matrix or the repo-root, summary, and bundle context preserved before narrowing further.
- `show_google_issue3_safe_route_entrypoints.ps1`: use this only after the route has narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical Rule

From the top-level suite router, prefer `show_google_issue3_top_level_attached_html_quickstart.ps1` first whenever attached localhost follow-up is already the next obvious branch. If you are arriving from `docs/WINDOWS_FULL_USE.md`, rerun `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, reopen `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, keep `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1` nearby, and then follow the same narrower attached-page helper chain. Once the route is clearly inside the narrower attached-page helpers, prefer `show_google_issue3_replay_route.ps1`, then `show_google_issue3_replay_route_shortcut_entrypoint.ps1`, before widening back into the longer validation-chain notes or the wrapper-heavy safe-route work.
