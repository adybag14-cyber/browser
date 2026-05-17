# Issue #3 Top-Level Shortcut-First Entrypoint

Use this note when issue `#3` replay is re-entering from the top-level headed validation catalog and you want the shortest written bridge into the narrower issue-specific helper chain while keeping the top-level shortcut-first surface checker, the broader attached-page flow helper, the dedicated Google-shaped attached-page surface checker and flow, the suite-router attached-page surface checker, the compact attached-bundle suite surface, and the issue-specific Google attached-page bridge visible before the route widens again.

This note matches `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`

## Goal

Start from the higher-level validation router, keep the top-level shortcut bridge visible, and keep the top-level shortcut-first surface checker, the broader attached-page flow helper, the dedicated Google-shaped attached-page surface checker and flow, the suite-router attached-page surface checker, the compact attached-bundle suite surface, and the issue-specific Google attached-page bridge easy to reopen before the route widens into the longer attached-page notes.

Use this note when:
- the route is already clearly inside issue `#3` and you want the shortest top-level bridge first
- the route may narrow into attached localhost follow-up next, but you do not want to reopen the longer attached-page note family too early
- you still want the replay-side, suite-router, suite-catalog, Windows-first companion notes, the pinned three-page bundle helper, and the newer fail-fast checker commands easy to reach from one written entrypoint

## Shortcut-first bridge

If you want the shortest top-level issue `#3` bridge, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

If you want the compact top-level route to fail fast before you trust it as the next step, run its checker first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this when the top-level router already made it clear that the replay stays inside issue `#3`, but you still want the shorter attached-page helpers nearby in case the route narrows there next.

## Broader router surfacing

If you want the broader validation-router surfaces visible before the shortcut-first bridge narrows the route, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay is still re-entering from the shared validation catalog and you want the broader Google lane, the broader attached-page flow helper, the dedicated Google-shaped attached-page surface checker plus flow, and the top-level shortcut-first checker reprinted before the top-level shortcut-first bridge hands off to the narrower issue `#3` helpers.

## Attached HTML handoff

If attached localhost follow-up is already the next obvious branch, keep the shorter attached-page ladder visible before the route drops back into the narrower shortcut helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay is already centered on the attached-page compatibility branch and you want the broader attached-page flow helper, the dedicated Google-shaped attached-page surface checker and flow, the route-level surface check, the Windows full-use attached-page route, its validation-router bridge, its catalog quickstart, the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-router attached-page quickstart, the suite-router attached-page surface checker, the suite-catalog attached-page bridge, the issue-specific Google entrypoint checker, the broader top-level shortcut-first bridge, the attached-page shortcut, and the narrower suite-router shortcut-first helper all kept on the same written ladder.

## Google-shaped attached HTML handoff

If the replay still needs the broader Google-shaped attached-page surface visible before the route narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

Use that route when the replay still needs the Google-specific attached-page surface checker, helper flow, suite-router attached-page surface checker, issue-specific Google entrypoint checker, and issue-specific Google bridge visible before it collapses back into the shorter issue `#3` route.

## Bundle-first route

If the current pages are still the pinned three-page compatibility bundle, keep that route visible first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay explicit before the replay widens back into the broader issue `#3` helper chain, and when you want the compact bundle-suite surface visible before the narrower bundle-first helper takes over.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the helper you reopen next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:
- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1`

Use this when you want the compact top-level shortcut route to fail fast before you trust it as the next re-entry point.

2. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this as the default follow-up when the route is already clearly inside issue `#3` and no attached-page-specific branch needs to stay visible first.

3. `show_attached_html_validation_flow.ps1`

Use this when you want the broader attached-page compatibility route printed before the replay-side attached-page quickstart, the top-level attached-page quickstart, or the narrower issue `#3` shortcut helpers.

4. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when attached localhost follow-up is already obvious and you want the shorter top-level attached-page bridge before the suite-router attached-page quickstart or the broader attached-page notes.

5. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route has already narrowed to attached-page follow-up and you want the suite-router-side attached-page bridge reprinted before the suite-catalog bridge, the attached-page shortcut, replay shortcuts, or the next-step matrix.

6. `check_google_issue3_suite_router_attached_html_quickstart_surface.ps1`

Use this when the route has already narrowed to the suite-router-side attached-page bridge and you want that compact helper surface to fail fast before trusting its narrower Google-specific follow-ups.

7. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog-side attached-page bridge should stay visible before the route narrows again.

8. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page compatibility branch itself should stay visible before the route widens back into replay shortcuts or the safe-route map.

9. `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`

Use this when the replay still needs the issue-specific Google attached-page entrypoint to fail fast before it narrows into the shortest Google-only bridge.

10. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader Google-shaped attached-page helper visible before it narrows again.

11. `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`

Use this when the current pages are already the known three-page compatibility set and you want the smallest read-first bundle helper before dropping into the narrower bundle-first route.

12. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clear and you want the narrowest stable helper surface.

13. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle state already matters and the next helper should keep that replay context aligned.

14. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after the top-level shortcut-first bridge before choosing the narrower replay surface.

15. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Start from the top-level headed validation suite router, then reopen `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and you want the shorter helper ladder printed before the replay widens again.

- No pinned bundle inputs and no saved replay state yet: go from the top-level suite router to `check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1`, then the top-level shortcut helper, then the suite-router shortcut helper, then the replay-route shortcut helper, then replay shortcuts, then the safe-route map.
- Attached localhost HTML route already in focus and the replay was reopened from `docs/WINDOWS_FULL_USE.md`: go from `-ChangeArea attached-html` and `-ChangeArea google-attached-html` to `show_attached_html_validation_flow.ps1`, `check_google_attached_html_validation_surface.ps1`, `show_google_attached_html_validation_flow.ps1`, rerun `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, reopen `show_google_issue3_windows_full_use_attached_html_route.ps1`, `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_windows_replay_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`, `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`, `show_google_issue3_suite_router_attached_html_quickstart.ps1`, `check_google_issue3_suite_router_attached_html_quickstart_surface.ps1`, `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`, `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`, and only then drop to `check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1` plus the top-level shortcut helper.
- Attached localhost HTML route already in focus and the replay was reopened from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`: go from `show_google_issue3_windows_replay_attached_html_quickstart.ps1` to `show_attached_html_validation_flow.ps1`, then `check_google_attached_html_validation_surface.ps1`, then `show_google_attached_html_validation_flow.ps1`, then the top-level attached-page quickstart, then the top-level attached-page catalog quickstart, then the suite-catalog top-level attached-html catalog quickstart, then the suite-router attached-page quickstart, then `check_google_issue3_suite_router_attached_html_quickstart_surface.ps1`, then the suite-catalog attached-page bridge, then `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`, and only then drop to `check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1` plus the top-level shortcut helper.
- Attached localhost HTML route already in focus but the broader validation-router bridge matters more than the Windows runbook route: go from `-ChangeArea attached-html` and `-ChangeArea google-attached-html` to `show_google_issue3_validation_router_attached_html_quickstart.ps1`, `check_google_attached_html_validation_surface.ps1`, `show_google_attached_html_validation_flow.ps1`, then `show_google_issue3_google_attached_html_entrypoint.ps1`, then the smaller top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog top-level attached-html catalog quickstart, the suite-router attached-page quickstart, `check_google_issue3_suite_router_attached_html_quickstart_surface.ps1`, the issue-specific Google entrypoint checker, or the companion notes, then `check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1`, then the top-level shortcut helper, then the attached-page bridge that best matches the current state.
- Saved summary or repo-root override already present: use the broader attached-page helpers plus the top-level shortcut helper with that same context first, then choose contextual flow, replay-route shortcut, replay shortcuts, the suite-router attached-page quickstart, the suite-catalog top-level attached-html catalog quickstart, the suite-catalog attached-page bridge, or the checker commands only as needed.
- Explicit bundle paths already pinned: reopen `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` first so the compact bundle helper stays visible, then stay on the bundle-first helper before widening back into the broader Google-only path.

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.