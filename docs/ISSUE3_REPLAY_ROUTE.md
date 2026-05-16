# Issue #3 Replay Route

Use this note when `show_google_issue3_replay_route.ps1` is already open and
you want the shortest written map of how that broader helper keeps the attached
localhost route, replay-route shortcut, replay-route bundle-first bridge, the
bundle-first branch, the Google-style attached-page flow, and the safe-route
handoff on one surface.

## Read-first helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

If the replay already carries `RepoRoot`, `SummaryPath`, or pinned attached
bundle paths, keep that same context on the helper first and only then narrow
again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Keep these notes nearby

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Default route

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the replay still needs the higher-level suite-router handoff
plus the attached localhost branch kept visible before the wrapper-heavy
safe-route steps.

## Windows-full-use attached route

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use that route when `docs/WINDOWS_FULL_USE.md` already made attached localhost
follow-up the next obvious issue `#3` branch and you want the route guard,
Windows-to-validation-router bridge, replay-side attached-html quickstart, and
top-level attached-page handoff visible before the replay-route helper takes
over.

## Google-style attached-page variant

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Use that route when the current attached-page inputs already include a
Google-like page and you want the Google-style attached-page guide and helper
visible before the replay-route helper narrows back into issue `#3` shortcuts,
bundle-first reuse, or the safe-route stack.

## Bundle-first variant

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
```

Use that route when the current saved or attached inputs are still the known
three-page compatibility bundle and the replay should stay pinned there before
widening again.

Keep `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` and
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` nearby when you use that
bundle-first route so the replay-route shortcut, the pinned bundle helper, and
the delegated bundle flow stay on the same compact written branch.

## Practical rule

1. Start from the broader replay-route helper only after the suite-router
   handoff or the Windows-full-use attached-page route has already
   re-established the issue `#3` branch.
2. If the route is reopening from `docs/WINDOWS_FULL_USE.md`, rerun
   `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`,
   keep `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`
   and `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
   visible, and only then drop into the replay-route helper.
3. If the current attached-page inputs already include a Google-like page,
   rerun `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`,
   keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` and
   `show_google_attached_html_validation_flow.ps1` nearby, and only then drop
   into the replay-route helper.
4. Reopen the replay-route shortcut helper next when the route is already known
   and you want the smaller attached-page, replay-shortcuts, next-step-matrix,
   bundle-first, and safe-route companion surface.
5. Stay on the replay-route bundle-first bridge and the bundle-first helper
   whenever explicit `InputPath` values are already pinned to the three-page
   compatibility set or when the replay-route helper already made that pinned
   branch the next obvious move.
6. Reopen the longer validation-chain notes only after the replay has narrowed
   into the wrapper-heavy safe route again.
