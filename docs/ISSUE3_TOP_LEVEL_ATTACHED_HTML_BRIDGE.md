# Issue #3 Top-Level Attached HTML Bridge

Use this note when issue `#3` is already narrowed to the attached localhost
HTML route and you want the broader top-level bridge to stay aligned with
`show_google_issue3_top_level_attached_html_entrypoint.ps1`.

Start with the compact top-level helper when you only need the shortest
companion surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

Start with the broader bridge when you want the fuller attached-page helper
chain surfaced first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

If the replay already carries a non-default checkout, a saved summary, or
pinned bundle inputs, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_PRODUCTION_EXECUTION_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`

## Goal

Start from the top-level attached-page router, keep the route guard, attached
shortcut guard, compact change-area quickstart, broader attached-page flow
helper, top-level shortcut surface, compact top-level quickstart, the newer
 top-level attached-page catalog quickstart, the suite-catalog-to-top-level
attached-page catalog quickstart, and the broader top-level bridge visible long
enough to choose the next attached-page helper deliberately, then default to
`show_google_issue3_suite_router_attached_html_quickstart.ps1` before widening
back into the suite-catalog, replay-route, or safe-route ladders.

Use the broader suite-catalog or replay-side notes only when those wider helper
families still need to stay in view after the top-level bridge is open. Do not
jump to them earlier than the live entrypoint script does.

Prefer one of these narrower follow-ups before reopening the wrapper-heavy safe
route:

- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_catalog_entrypoints.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Read-First Route

Use this sequence when attached localhost follow-up is already clear and no
saved replay context needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when you want the route guard, attached-shortcut guard,
change-area quickstart, broader attached-page flow helper, top-level shortcut,
compact top-level quickstart, top-level attached-page catalog quickstart,
suite-catalog-to-top-level attached-page catalog quickstart, broader top-level
bridge, suite-router-side attached-page quickstart, issue-specific attached-page
bridge, suite-catalog guide, suite-catalog attached-page bridge, attached-page
shortcut, replay-route helper, replay shortcuts, and next-step matrix all
visible before the route widens again.

## Windows-First Re-Entry

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, keep the
broader Windows-first branch and the replay-side attached-page quickstart
aligned before this narrower top-level bridge takes over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when the broader Windows runbook already made attached localhost
follow-up obvious and you want the route-level surface check, validation-router
attached-html bridge, Windows-first catalog quickstart, replay-side attached
quickstart, change-area quickstart, broader attached-page flow helper, top-level
shortcut surface, compact top-level quickstart, top-level attached-page catalog
quickstart, suite-catalog-to-top-level attached-page catalog quickstart,
broader top-level bridge, and suite-router-side attached-page quickstart
describing the same re-entry order.

## Replay-Side Attached HTML Re-Entry

If `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay to
the attached localhost lane, keep that replay-side ladder visible long enough
to align it with the top-level bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Use that route when the replay-side attached-page quickstart already made the
attached localhost branch obvious and you want the replay-side ladder,
change-area quickstart, broader attached-page flow helper, top-level shortcut
surface, compact top-level quickstart, top-level attached-page catalog
quickstart, suite-catalog-to-top-level attached-page catalog quickstart,
broader top-level bridge, suite-router-side attached-page quickstart,
issue-specific attached-page bridge, and suite-catalog guide pointing at the
same narrower helper order.

## Router Variants

If you want the broader Google-shaped attached-page surface first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

If the current pages are still the pinned three-page compatibility bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` nearby when you use
that pinned bundle route so the exact three-page compatibility set stays
visible before the bundle-first helper and validation runner take over.

## Preserve Replay Context

If a non-default repo root, saved summary, or pinned bundle path is already in
play, keep that same context attached to the compact change-area quickstart,
compact top-level quickstart, broader top-level bridge, and default next helper
first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Pick The Next Helper Quickly

- `show_google_issue3_suite_router_attached_html_quickstart.ps1`: default next helper after the broader top-level bridge when no bundle pins or saved replay context take priority first.
- `show_google_issue3_google_attached_html_entrypoint.ps1`: use when the issue-specific attached-page bridge should come next without reopening the broader suite-catalog notes first.
- `show_google_issue3_suite_catalog_entrypoints.ps1`: use when the wider suite-catalog route still needs to stay visible beside the top-level bridge before the helper chain narrows again.
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`: use when the suite-catalog-side attached-page bridge should stay visible before dropping to attached-page shortcuts or replay-route helpers.
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`: use when the route is already close to the narrowest attached-page bridge and you want the shortest issue-specific surface before replay helpers.
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`: use when the route has already narrowed from the top-level bridge into the shorter suite-router shortcut ladder.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use when the attached-page route is already confirmed and you want the smaller replay-route companion before replay shortcuts or the safe-route map.
- `show_google_issue3_replay_shortcuts.ps1`: use when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before choosing between the next-step matrix, bundle-first branch, or safe-route map.
- `show_google_issue3_suite_router_next_steps.ps1`: use when you want the executable branch matrix reprinted after the attached-page route is confirmed.
- `show_google_issue3_contextual_flow.ps1`: use when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper should keep that replay context aligned.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when explicit `InputPath` values are already pinned or the replay should stay on the known three-page compatibility bundle.
- `show_google_issue3_safe_route_entrypoints.ps1`: use when the attached-page helper branch is out of the way and you want the wrapper-heavy commands, notes, and runner-state helpers surfaced in one place.

## Practical Rule

Once `show_headed_validation_suites.ps1` has already narrowed the route to
attached localhost HTML follow-up, prefer the route guard, attached-shortcut
guard, change-area quickstart, broader attached-page flow helper, top-level
shortcut surface, compact top-level quickstart, top-level attached-page catalog
quickstart, suite-catalog-to-top-level attached-page catalog quickstart,
broader top-level bridge, and then
`show_google_issue3_suite_router_attached_html_quickstart.ps1` before you
reopen the wider suite-catalog or replay-route families.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: rerun the Windows route check, reopen the Windows full-use validation-router bridge, then the Windows full-use attached-html catalog quickstart, then the replay-side attached-html quickstart, then the change-area quickstart, broader attached-page flow helper, top-level shortcut surface, top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, and suite-router attached-page quickstart before the route widens again
- replay reopened from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`: reopen the replay-side attached-html quickstart first, then the change-area quickstart, broader attached-page flow helper, top-level shortcut surface, top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, and suite-router attached-page quickstart before the suite-catalog or replay-route helpers return
- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the route guard, attached-shortcut guard, change-area quickstart, broader attached-page flow helper, top-level shortcut surface, top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, suite-router attached-page quickstart, issue-specific attached-page bridge, suite-catalog guide, suite-catalog attached-page bridge, attached-page shortcut, replay-route helper, replay shortcuts, next-step matrix, then the safe-route map
- Google-specific attached-page surface still matters more than the generic shortcut chain: go from `-ChangeArea google-attached-html` to the top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, suite-router attached-page quickstart, then the issue-specific attached-page bridge before narrowing further
- explicit bundle paths already pinned: reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`, then stay on the bundle-first helper after the change-area quickstart, top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, and suite-router attached-page quickstart before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the change-area quickstart, top-level quickstart, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, broader top-level bridge, and suite-router attached-page quickstart with that same context first, then choose the top-level shortcut surface, issue-specific attached-page bridge, suite-catalog guide, suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
