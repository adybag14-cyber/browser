# Issue #3 Google Attached HTML Validation Flow

Use this note when the next issue `#3` replay should auto-discover the current attached HTML pages, keep one Google-like page first, and route that saved-page set through the same localhost-first helper chain before manual headed follow-up.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that helper when you want one read-first command surface that:

- reuses the current attached HTML pages instead of a separately prepared saved-page export
- fails fast on the Google-style attached-page validation surface before launch
- runs the deep local asset-closure audit for the same attached-page set
- keeps the Google-like page first when one is available in the current attached-page inputs
- hands off into the saved-page Google validation helper and its runner with the same locked inputs

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the current attached-page set, run the Google-style fail-fast checks first, keep the broader attached-page entrypoints visible long enough to confirm the right route, then let `show_google_attached_html_validation_flow.ps1` print and hand off the same locked inputs into the saved-page Google validation flow before you widen back into replay shortcuts, the compact bundle-suite re-entry, bundle-first reuse, or the safe-route stack.

## Top-level re-entry points

Use these when the broader router should pick the next branch before the Google-style attached-page flow narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use `google-attached-html` when the replay should stay on the Google-shaped attached-page lane.
Use `attached-html` when the route should stay broader and not assume the Google-style follow-up yet.
Use `attached-html-target-bundle` when the current pages are still the known three-page compatibility bundle and the replay should stay pinned there first.
Use `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` when the current pages still match that three-page bundle and you want the compact bundle-specific re-entry surfaced before the route narrows all the way into the bundle-first helper.
Use `show_google_issue3_replay_route.ps1` when the replay still needs the broader attached-page route, the compact bundle-suite re-entry, the pinned bundle branch, and the replay-route shortcuts printed together before you commit to the narrower Google-style helper chain.
Use `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the current pages are already the known three-page compatibility bundle and the replay should stay pinned there before the narrower Google-style flow or replay shortcuts take over.

## Suite-catalog re-entry

When the next replay should reopen the live suite catalog before you commit to the broader attached-page route or the bundle-pinned route, use these focused catalog surfaces first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

Use `-SuiteName google-attached-html` when you want the dedicated Google-style attached-page surface checker, helper, broader attached-page helper, and nearby issue `#3` re-entry commands reprinted without widening back to the rest of the catalog first.
Use `-SuiteName attached-html-target-bundle` when the current attached pages are still the known three-page compatibility set and you want the pinned bundle surface checker, compact bundle-suite re-entry, helper, runner, and broader attached-page helper shown together before choosing the next replay branch.
Use the `-ChangeArea` views when you still want the same Google-shaped and bundle-aware helper surface printed with the nearby recommended suites and higher-level issue `#3` entrypoints.
Use `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` when the bundle route is already the likely next branch but you still want the compact bundle helper, the broader attached-page helper surface, and the Google-shaped attached-page fallback visible beside the suite catalog before narrowing further.

## Windows-full-use re-entry

If the broader Windows runbook already made attached localhost follow-up the next obvious issue `#3` branch, reopen the wider Windows-first route guard and bridge before dropping into this narrower Google-style flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that route when `docs/WINDOWS_FULL_USE.md` already narrowed the replay to attached localhost follow-up and you want the route-level surface check, the broader Windows-to-validation-router bridge, and the replay-side attached-page quickstart visible before this note narrows the same inputs into the Google-style helper and runner.

## Replay-route and bundle-first re-entry

If the replay is already reopening from the replay-route helper family and you still want the broader attached-page route plus the pinned bundle branch visible before the Google-style helper takes over, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that route when the replay-route helper already became the main read-first surface, but you still want the broader attached-page fallback, the compact bundle-suite re-entry, and the pinned three-page bundle branch visible before you commit to the narrower Google-style helper and runner.
Keep `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` nearby when you want the written replay-route-to-bundle-first bridge open beside that helper chain, and keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` nearby when the compact bundle-specific re-entry should stay visible before the narrower bundle-first branch takes over.

## Default read-first route

Use this route when auto-discovery should choose the current attached HTML inputs:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

Use that route when:

- the current attached-page set should be discovered automatically from the workspace
- one Google-like page should stay first if the current attached inputs include one
- the replay still needs the Google-style saved-page flow printed before launch
- you want the same attached-page set reused by the surface checker, asset-closure audit, helper, and runner

## Preserve replay context

If the replay already carries a non-default repo root, a preferred starting page, an explicit browser binary, or pinned attached-page inputs, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -RepoRoot '<repo-root>' -InputPath '<attached-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<attached-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<attached-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>' -Wait
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- the next replay should stay on an explicit saved-page set instead of auto-discovery
- the preferred starting page should stay pinned instead of relying on the helper to choose one automatically
- the replay should use a specific headed binary path

## Explicit page-root route

If the attached pages live under one page root and you want to skip saved-file auto-discovery entirely, use `-PageRoot`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -PageRoot '<page-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -PageRoot '<page-root>' -Wait
```

Use that route when the replay is already organized around a single local host directory and you do not need the saved-file search roots to choose the current inputs.

## Degraded asset mode

If the current replay must continue even though some local sibling assets are known to be missing, allow that explicitly and treat the result as a narrower signal:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -AllowMissingAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -AllowMissingLocalAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -AllowMissingLocalAssets -Wait
```

Use this only when the missing local assets are already understood and the run still needs a best-effort Google-style attached-page replay instead of a strict asset-complete pass.

## If auto-discovery comes up empty

If no Google-style attached HTML files are found automatically, do one of these instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<attached-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -PageRoot '<page-root>'
```

Use the broader attached-page flow helper when the current inputs are not clearly Google-shaped yet.
Use `-InputPath` or `-PageRoot` when the Google-style replay is still the right route but auto-discovery needs an explicit nudge.

## Pick the next helper quickly

1. `check_google_attached_html_validation_surface.ps1`

Use this first when branch state may have moved and you want the Google-style attached-page guide, helper, and downstream runner surface checked before the replay starts.

2. `check_attached_html_local_asset_closure.ps1 -GoogleStyle`

Use this next when the attached pages should stay strict about sibling local assets before the helper or runner opens a browser.

3. `show_google_attached_html_validation_flow.ps1`

Use this when you want the current attached-page set printed, summarized, and handed off into the saved-page Google validation flow with the same locked inputs.

4. `run_google_attached_html_validation.ps1 -Wait`

Use this when the earlier checks are green and you want to launch the headed localhost replay directly.

5. `show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle`

Use this when the attached-page set is already resolved and you want the underlying saved-page Google helper reprinted directly before a manual or narrower follow-up.

6. `show_headed_validation_suites.ps1 -SuiteName google-attached-html`

Use this when you want the suite catalog itself to reprint the narrower Google-style attached-page helper surface, its nearby issue `#3` re-entry commands, and the broader attached-page helper without widening back out to the rest of the catalog first.

7. `show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle`

Use this when the current inputs are still the known three-page compatibility bundle and you want the suite catalog to keep the pinned bundle helper, the compact bundle-suite re-entry, the runner, and the broader attached-page fallback visible together.

8. `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`

Use this when the current inputs are still the known three-page compatibility bundle and you want the compact bundle-specific re-entry surfaced before the route narrows into the bundle-first helper or widens back into the broader attached-page fallback.

9. `show_google_issue3_windows_replay_attached_html_quickstart.ps1`

Use this when the replay is already centered on the attached localhost compatibility pages and you want the shorter issue `#3` replay ladder beside this Google-style flow.

10. `show_google_issue3_replay_route.ps1`

Use this when you want the replay-route helper, the broader attached-page route, the compact bundle-suite re-entry, and the pinned bundle branch reprinted together before you commit to the narrower Google-style helper or the shorter attached-page shortcut chain.

11. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when the current inputs are still the known three-page compatibility bundle and the replay should stay pinned there before widening back into the broader Google-only helper chain.

## Practical rule

Prefer the Google-style attached-page flow when the current attached HTML inputs already contain a Google-like page and the next useful replay should stay aligned with the issue `#3` localhost-first helper chain. If the replay is reopening from `docs/WINDOWS_FULL_USE.md`, rerun the broader Windows-full-use attached-page route guard and bridge first so the higher-level branch stays visible before this narrower note takes over. Reopen the suite-catalog surfaces first when you want the narrower Google-shaped route, the compact bundle-suite re-entry, and the pinned bundle route printed together before picking the next replay branch. Keep the replay-route helper family nearby when you want the broader attached-page fallback, the compact bundle-specific re-entry, and the pinned bundle-first branch surfaced together before this guide narrows the route. Keep the broader attached-page router nearby when the route is still ambiguous, keep the compact bundle-suite helper and bundle-first route nearby when the inputs are still the known compatibility bundle, and only widen back into replay shortcuts or the safe-route stack after the Google-style surface check, asset audit, helper output, or runner makes the next failure state clear.
