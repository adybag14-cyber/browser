# Issue #3 Suite-Catalog Attached HTML Bridge

Use this note when issue `#3` work is re-entering from the suite-catalog surface and you want the attached localhost HTML route kept visible before the replay narrows into the shorter issue-specific helper chain.

This note now matches the live `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` helper more closely. It keeps the suite-catalog guide, the top-level shortcut bridge, the validation-router handoff, the Windows replay attached-page quickstart, the top-level attached-page notes, the shorter suite-router attached-page bridge, and the later replay-shortcut branches aligned on one read-first surface.

If you want the compact suite-catalog attached-page bridge first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the suite-catalog attached-page surface, keep the broader `show_headed_validation_suites.ps1` routes visible, then narrow through the validation-router handoff, the Windows replay attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, the top-level catalog quickstart, the suite-catalog-to-top-level catalog quickstart, the shorter suite-router attached-page quickstart, the Google-shaped attached-page bridge, the attached-page shortcut, the suite-router shortcut bridge, replay shortcuts, the later suite-router handoff, the replay-route helper, contextual flow, the bundle-first branch, and the safe-route map only when those wider layers are genuinely needed.

## Default Read-First Bridge

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the attached-page compatibility lane is already in focus from the suite router and you want the suite-catalog guide, the top-level shortcut bridge, the validation-router attached-page quickstart, the Windows replay attached-page quickstart, the top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level catalog quickstart, the suite-catalog-to-top-level catalog quickstart, the shorter suite-router attached-page quickstart, the suite-catalog attached-page bridge, the Google attached-page entrypoint, the attached-page shortcut, the suite-router shortcut bridge, replay shortcuts, the next-step matrix, contextual flow, the later suite-router handoff, the replay-route helper, the bundle-first branch, and the safe-route map all visible before you reopen the longer validation-chain notes.

## Windows-First Re-entry

When the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first route plus the replay-side and top-level attached-page re-entry kept visible before the suite-catalog bridge narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use that route when the broader Windows headed runbook already made attached localhost follow-up the next obvious issue `#3` branch and you want the route-level fail-fast check, the Windows-to-validation-router bridge, the Windows-first catalog quickstart, the replay-side attached-page quickstart, the suite-catalog guide, the top-level shortcut bridge, the validation-router quickstart, the top-level attached-page notes, and the suite-catalog bridge aligned on one read-first path.

## Replay-Side Attached HTML Re-entry

If `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay to the attached localhost lane and you want that replay-side helper ladder kept visible before the suite-catalog bridge takes over, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay-side attached-page quickstart already made the attached localhost branch obvious and you want the replay-side ladder, the top-level shortcut bridge, the validation-router handoff, the top-level attached-page notes, the suite-catalog guide, the suite-catalog bridge, the shorter attached-page shortcut, and the suite-router shortcut surface all pointing at the same narrower helper order before the route widens again.

## Keep The Bundle Visible

If the current pages are still the pinned three-page compatibility bundle, keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` open beside the bridge and use:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that bundle-first route when the known three-page compatibility set should stay explicit while the suite-catalog bridge narrows into the bundle-aware helper flow.

## Preserve Replay Context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the suite-catalog guide and the narrower follow-ups:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout, a saved `SummaryPath` already points at current replay outputs, or explicit `InputPath` values are already pinned to the known three-page compatibility bundle.

## Pick The Next Helper Quickly

1. `show_google_issue3_windows_full_use_attached_html_route.ps1`

Use this when the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first attached-page route helper surfaced before the replay-side quickstart and the suite-catalog bridge.

2. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when the replay is re-entering from the broader validation router and you want the shortest bridge into the narrower attached-page ladder.

3. `show_google_issue3_windows_replay_attached_html_quickstart.ps1`

Use this when the replay already came through `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` and you want the replay-side attached-page ladder kept visible before the top-level helpers and the suite-catalog bridge take over.

4. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when the broader Windows runbook or suite router already made attached localhost follow-up obvious and you want the shorter top-level attached-page route visible before you narrow further.

5. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when the broader top-level issue `#3` bridge still needs to stay visible beside the attached-page ladder before you narrow into the shorter attached-page shortcut or the suite-router shortcut helper.

6. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the top-level attached-page quickstart and its catalog-side companion surface reprinted together before the route narrows again.

7. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route is ready to stay inside the shorter suite-router attached-page bridge after the Windows replay and top-level attached-page helpers have already been surfaced.

8. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader Google-shaped attached-page surface checker and flow helper before narrowing again.

9. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the shortest bridge into replay shortcuts, the next-step matrix, contextual flow, the suite-router handoff, the replay-route helper, or the bundle-first branch.

10. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this when the route is already known to stay inside issue `#3` and you want the shorter suite-router shortcut surface reprinted after the attached-page ladder.

11. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen into the next-step matrix, contextual flow, the suite-router handoff, the replay-route helper, the bundle-first helper, or the safe-route map.

12. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after replay shortcuts before choosing between contextual flow, the suite-router handoff, the replay-route helper, the bundle-first branch, or the safe-route map.

13. `show_google_issue3_contextual_flow.ps1`

Use this when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.

14. `show_google_issue3_suite_router_handoff.ps1`

Use this when you want the wider compact bridge that keeps the exact suite-router entrypoints beside the attached-page replay helpers before narrowing into the later replay-route or wrapper-heavy surfaces.

15. `show_google_issue3_replay_route.ps1`

Use this when the narrower attached-page route is already clear and you want the smaller replay-route companion surfaced before choosing between the bundle-first branch and the safe-route map.

16. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical Rule

Once `show_headed_validation_suites.ps1` has already narrowed the route to attached localhost HTML follow-up from the suite-catalog side, prefer `show_google_issue3_suite_catalog_entrypoints.ps1`, then `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, then `show_google_issue3_validation_router_attached_html_quickstart.ps1`, then `show_google_issue3_windows_replay_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, then `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_suite_router_attached_html_quickstart.ps1`, then `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`, then `show_google_issue3_replay_shortcuts.ps1`, then `show_google_issue3_contextual_flow.ps1`, then `show_google_issue3_suite_router_handoff.ps1`, then `show_google_issue3_replay_route.ps1`, and only then reopen the bundle-first helper or the safe-route map.

- Replay reopened from `docs/WINDOWS_FULL_USE.md`: go from `show_google_issue3_windows_full_use_attached_html_route.ps1` to `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, then `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, then `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_windows_replay_attached_html_quickstart.ps1`, then the suite-catalog guide, then the top-level shortcut bridge, then the validation-router quickstart, then the top-level attached-page quickstart, then the top-level attached-page bridge, then the top-level catalog quickstart, then the suite-catalog-to-top-level catalog quickstart, then the suite-router attached-page quickstart, then the suite-catalog attached-page helper before narrowing into the shorter shortcut surfaces again.
- Replay reopened from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`: reopen `show_google_issue3_windows_replay_attached_html_quickstart.ps1` first, then the top-level shortcut bridge, then the validation-router quickstart, then the top-level attached-page quickstart, then the top-level attached-page bridge, then the top-level catalog quickstart, then the suite-catalog-to-top-level catalog quickstart, then the suite-router attached-page quickstart, then the suite-catalog guide, then the suite-catalog attached-page helper, then the attached-page shortcut, then the suite-router shortcut helper, then replay shortcuts before widening again.
- No pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the suite-catalog guide, then the top-level shortcut bridge, then the validation-router attached-page quickstart, then the Windows replay attached-page quickstart, then the top-level attached-page quickstart, then the top-level attached-page bridge, then the top-level catalog quickstart, then the suite-catalog-to-top-level catalog quickstart, then the suite-router attached-page quickstart, then the suite-catalog attached-page helper, then the Google attached-page entrypoint, then the attached-page shortcut, then the suite-router shortcut helper, then replay shortcuts, the next-step matrix, contextual flow, the suite-router handoff, the replay-route helper, the bundle-first branch, and finally the safe-route map.
- Explicit bundle paths already pinned: reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` and `show_google_issue3_suite_catalog_entrypoints.ps1` before the bundle-first helper so the exact three-page compatibility set stays visible while the suite-catalog bridge narrows into the bundle flow.
- Saved summary or repo-root override already present: reopen the suite-catalog guide, the validation-router quickstart, the Windows replay attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, the suite-catalog attached-page helper, and the later suite-router handoff or replay-route helpers with that same context first, then use contextual flow only as needed.

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.