# Issue #3 Suite-Catalog Attached HTML Bridge

Use this note when issue `#3` work is re-entering from the suite-catalog surface and you want the attached localhost HTML route kept visible before the replay narrows into the shorter issue-specific helper chain.

If you want the compact suite-catalog attached-page bridge first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Start from `docs/WINDOWS_FULL_USE.md` through `show_google_issue3_windows_full_use_attached_html_route.ps1`, or from the suite-catalog `attached-html`, `google-attached-html`, or `attached-html-target-bundle` router surfaces. When the replay is still coming directly from the broader Windows runbook or the top-level attached-page quickstart, reopen `show_google_issue3_top_level_attached_html_quickstart.ps1` before `show_google_issue3_suite_router_attached_html_quickstart.ps1` so the shorter top-level attached-page bridge stays visible before you narrow into `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`.

From there, prefer one of these narrower follow-ups before reopening the broader wrapper-heavy safe route:

- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`

## Windows full-use and top-level surfacing

When the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first route plus the shorter top-level attached-page re-entry kept visible before the suite-catalog bridge narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use that route when the broader Windows headed runbook already made attached localhost follow-up the next obvious issue `#3` branch and you want the Windows-full-use helper, the shorter top-level attached-page quickstart, the suite-router attached-page quickstart, and the suite-catalog attached-page bridge aligned on one read-first path.

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the attached-page compatibility lane is already in focus from the suite router and you want the shorter top-level attached-page quickstart and the suite-catalog attached-page bridge both visible before you drop the suite-router-side bridge or narrow into the shorter issue `#3` replay surfaces.

## Suite-catalog router variants

If you want the broader Google-shaped attached-page surface first, start with:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the next replay still needs the Google-style attached-page surface checker and flow helper kept visible before you drop to the shorter attached-page shortcut or replay shortcuts.

If the current pages are still the pinned three-page compatibility bundle, start with:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the known three-page compatibility set should stay pinned all the way through the top-level attached-page quickstart, the suite-router attached-page quickstart, the suite-catalog helper, the bundle-first branch, flow helper, and delegated localhost runner before widening back into the broader issue `#3` helper stack.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the top-level attached-page quickstart first, then carry it into the suite-router attached-page helper and the suite-catalog attached-page helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. Windows full-use attached HTML route

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
```

Use this when the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first attached-page route helper surfaced before the shorter top-level attached-page quickstart and the suite-catalog bridge.

2. Top-level attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

Use this when the broader Windows runbook or suite router already made attached localhost follow-up obvious and you want the shorter top-level attached-page bridge visible before you narrow into the suite-router attached-page quickstart or the suite-catalog bridge.

3. Google attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use this when the replay still needs the broader Google-shaped attached-page surface checker and flow helper before narrowing again.

4. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the attached-page compatibility route kept visible before you widen back into replay shortcuts, the next-step matrix, or the safe-route map.

5. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen into the next-step matrix, contextual flow, bundle-first helper, or safe-route map.

6. Suite-router next-step matrix

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Use this when you want the executable branch matrix reprinted after the suite-catalog attached-page bridge before choosing the narrower replay surface.

7. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use this when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.

8. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Once `show_headed_validation_suites.ps1` has already narrowed the route to attached localhost HTML follow-up from the suite-catalog side, prefer `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_suite_router_attached_html_quickstart.ps1`, and then `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` before reopening the longer validation-chain notes again.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: go from `show_google_issue3_windows_full_use_attached_html_route.ps1` to `show_headed_validation_suites.ps1 -ChangeArea attached-html`, then the top-level attached-page quickstart, then the suite-router attached-page quickstart, then the suite-catalog attached-page helper before narrowing into the issue-specific attached-page bridge or replay shortcuts
- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the suite-router attached-page quickstart, then the top-level attached-page quickstart, then the suite-catalog attached-page helper, then the Google attached-page entrypoint, then the attached-page shortcut, then replay shortcuts, then the safe-route map
- Google-specific attached-page surface still matters more than the generic shortcut chain: go from `-ChangeArea google-attached-html` to the suite-router attached-page quickstart, then the top-level attached-page quickstart, then the suite-catalog attached-page helper, then the Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the top-level attached-page quickstart and the suite-router attached-page quickstart with that same context first, then the suite-catalog attached-page helper, then choose replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
