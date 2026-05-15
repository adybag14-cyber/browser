# Issue #3 Suite-Catalog Top-Level Attached HTML Catalog Quickstart

Use this note when the suite-catalog surface is already open and you want the replay-side attached HTML ladder, the top-level attached HTML catalog quickstart, and the narrower suite-router and safe-route follow-up kept visible together before the route narrows again.

If you want that compact suite-catalog-to-top-level route first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`, `show_google_issue3_suite_catalog_entrypoints.ps1`, or from the broader suite-catalog change-area surfaces, then move through the replay-side attached HTML quickstart, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, and the top-level attached-page catalog quickstart before the route narrows into the suite-catalog attached-page bridge, the shorter suite-router attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route map.

## Default read-first route

Use this route when no pinned bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:
- the suite-catalog surface already made attached localhost follow-up obvious
- you still want the broader suite-catalog guide, the replay-side attached HTML quickstart, the validation-router bridge, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, and the top-level attached-page catalog quickstart visible before the route commits to the suite-catalog or suite-router attached-page bridges
- you want the attached-page shortcut, replay shortcuts, and safe-route map kept nearby before the route widens again

## Windows-first and replay-side re-entry

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, or if `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the route to attached localhost follow-up, keep the broader Windows-first path and the replay-side attached HTML ladder visible before this suite-catalog quickstart collapses back into the narrower helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when:
- the broader Windows runbook or replay quickstart already made attached localhost follow-up the next obvious issue `#3` branch
- you want the Windows-side route, the broader suite-catalog guide, the replay-side attached HTML quickstart, the validation-router bridge, the top-level attached-page notes, and this suite-catalog-to-top-level catalog quickstart describing the same handoff order
- the route is not ready to jump straight to the shorter attached-page shortcut or replay-shortcuts surface yet

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at current replay outputs
- the broader suite-catalog entry surface should stay aligned before the route narrows into the smaller quickstart
- explicit `InputPath` values are already pinned to the known attached three-page compatibility bundle

## Pinned bundle-first route

If the current pages are already the known three-page compatibility bundle, keep the replay on that locked path before widening back into the broader issue `#3` helper stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay pinned before the route widens back into replay shortcuts, the next-step matrix, or the broader safe-route surfaces.

## Pick the next helper quickly

1. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when you want the suite-catalog-side attached-page bridge immediately after the top-level attached-page catalog quickstart.

2. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route should keep the narrower suite-router attached-page bridge visible before collapsing to the attached-page shortcut or replay shortcuts.

3. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the shortest attached-page bridge before widening into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

4. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

5. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you want the executable branch matrix reprinted after the suite-catalog attached-page bridge before choosing the narrower replay surface.

6. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and the next helper surface should keep that replay state aligned before narrowing again.

7. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the attached-page route is already clear and you want the current wrapper-heavy issue `#3` command map surfaced in one place before the next fresh replay or reuse-current-outputs step.

8. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Once the suite-catalog surface or its dedicated entrypoints guide already made attached localhost follow-up obvious, prefer the replay-side attached HTML quickstart, then the validation-router attached-page quickstart, then the compact top-level attached-page quickstart, then the broader top-level attached-page bridge, then the top-level attached-page catalog quickstart before reopening the longer validation-chain notes.

- no pinned bundle inputs and no saved replay state yet: go from the suite-catalog surface to the replay-side attached HTML quickstart, then the validation-router bridge, then the compact top-level quickstart, then the broader top-level bridge, then the top-level catalog quickstart, then the suite-catalog attached-page bridge, then the suite-router attached-page quickstart, then the attached-page shortcut, then replay shortcuts, then the safe-route map
- replay reopened from `docs/WINDOWS_FULL_USE.md` or `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`: keep the broader Windows-side route or replay-side quickstart visible before this suite-catalog quickstart narrows into the top-level attached-page note family and the smaller attached-page bridges
- broader Google-shaped attached-page surface still matters more than the generic shortcut chain: reopen the suite-catalog surface, then the top-level catalog quickstart, then the broader Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: keep the bundle-first helper in front of the delegated bundle runner so the known three-page compatibility set stays fixed before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the broader suite-catalog helper with that same context first, then this quickstart, then choose the suite-catalog bridge, replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
