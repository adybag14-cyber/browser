# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

Use this note when you are starting from `docs/WINDOWS_FULL_USE.md` or `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` and you want the shorter attached-page route that keeps the top-level attached HTML catalog quickstart visible before the helper chain narrows again.

This keeps the Windows full-use attached localhost route aligned with the newer catalog-side attached-page quickstart without reopening the broader suite-catalog, replay-route, or wrapper-heavy safe-route notes first.

If you want that narrower Windows full-use attached-page plus catalog bridge printed directly, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that same context directly in both helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the broader Windows headed runbook, reopen the dedicated Windows full-use attached-page route, then move immediately into `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` when the next replay is already known to stay on the attached localhost compatibility path and you want the suite-catalog-side attached-page bridge surfaced before the helper chain narrows into replay shortcuts or the safe-route map.

From there, prefer one of these narrower follow-ups before reopening the broader wrapper-heavy safe route:

- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact sequence when the broader Windows runbook already made attached localhost follow-up obvious and no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:

- the next follow-up is already on the attached localhost compatibility lane
- the replay does not need the broader Google-only router helpers reprinted first
- you want the Windows full-use attached-page route helper, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the suite-catalog-side attached-page bridge visible before the helper chain narrows again

## Route variants

If the replay still needs the broader Google-shaped attached-page surface first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the replay still needs the broader issue-specific attached-page surface checker and flow helper visible before it drops to the shorter attached-page shortcut or replay-shortcuts surface.

If the next replay should stay pinned to the known three-page compatibility bundle before widening back into the broader issue `#3` helper stack, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the current saved or attached page set is already the known three-page bundle and you want that same locked input set preserved through the Windows full-use attached-page route, the top-level catalog quickstart, and the bundle-aware validation helper chain.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the shorter Windows full-use helper chain first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_windows_full_use_attached_html_route.ps1`

Use this first when the broader Windows headed runbook already narrowed replay to attached localhost follow-up and you want the shorter route map plus the nearby attached-page notes printed together before the helper chain narrows again.

2. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this next when the attached localhost branch is already in focus and you want the compact top-level attached-page quickstart plus the suite-catalog-side attached-page bridge surfaced before the route narrows again.

3. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the route should keep the suite-catalog-side attached-page bridge visible before it drops to the shorter attached-page shortcut, replay shortcuts, or the safe-route map.

4. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

5. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

6. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and the next helper surface should keep that replay state aligned before narrowing again.

7. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

8. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the attached-page branch is already out of the way and you want the current wrapper-heavy issue `#3` commands printed in one place before the next fresh replay or reuse-current-outputs step.

## Practical rule

When `docs/WINDOWS_FULL_USE.md` or `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` has already narrowed the next replay to attached localhost follow-up, reopen `show_google_issue3_windows_full_use_attached_html_route.ps1` first, then surface `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` before widening back into the broader helper chain.

- no pinned bundle inputs and no saved replay state yet: go from the Windows full-use attached-page route to the top-level attached-page quickstart, then the catalog quickstart, then the suite-catalog attached-page bridge, then the shorter attached-page shortcut, then replay shortcuts, then the safe-route map
- broader Google-shaped attached-page surface still matters more than the generic shortcut chain: go from `-ChangeArea google-attached-html` to the catalog quickstart, then the suite-catalog attached-page bridge, then the Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the Windows full-use attached-page route and the catalog quickstart with that same context first, then choose replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
