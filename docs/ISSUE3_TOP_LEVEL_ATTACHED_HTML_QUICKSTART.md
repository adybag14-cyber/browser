# Issue #3 Top-Level Attached HTML Quickstart

Use this note when issue `#3` replay is already narrowed to the top-level attached localhost route and you want the shortest top-level bridge into the newer attached-page helper chain before widening back into the broader replay stack.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `show_headed_validation_suites.ps1 -SuiteName google-recommended`, `show_headed_validation_suites.ps1 -ChangeArea google-input`, `show_headed_validation_suites.ps1 -ChangeArea attached-html`, `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`, or `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`, then move immediately into `show_google_issue3_top_level_attached_html_quickstart.ps1` when the next replay is already known to stay on the attached-page follow-up path.

From there, prefer one of these narrower follow-ups before reopening the broader wrapper-heavy safe route:
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Broader validation-router surfacing

Because `show_headed_validation_suites.ps1` now surfaces the issue `#3` top-level attached HTML route, the compact top-level attached-page quickstart, and the bundle-first helper directly from the broader `google-recommended` and `google-input` entrypoints, reopen one of those broader router surfaces first when attached localhost follow-up has become the next obvious branch but the replay has not been narrowed to `-ChangeArea attached-html` yet.

Use this route when you want the attached-page branch surfaced directly from the broader validation catalog before you drop into the shorter issue-specific attached-page helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when:
- the broader issue `#3` router already made attached localhost follow-up obvious
- you still want the compact top-level attached-page quickstart and the broader top-level attached-page bridge visible before the suite-router attached-page quickstart narrows the route again
- the bundle-first helper should remain easy to reopen from that same top-level surface before you widen back into the wrapper-heavy path

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the top-level validation catalog has already narrowed replay to attached localhost follow-up and you want the top-level attached-page bridge, the newer suite-router attached-page quickstart, and the top-level attached-page catalog quickstart kept visible before the route widens again.

## Catalog quickstart route

If you want the compact top-level attached-page quickstart and the suite-catalog attached-page bridge kept visible together before the helper chain narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:
- the attached localhost branch is already in focus and you want the suite-catalog-side bridge surfaced beside the compact top-level quickstart
- the replay still benefits from seeing the broader suite-catalog attached-page route before dropping into the shorter attached-page shortcut or replay shortcuts
- you want the written quickstart to stay aligned with the newer catalog-side helper chain that already exists on the live branch

## Top-level router variants

If the replay still needs the broader Google-shaped attached-page surface first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the replay still needs the Google-specific attached-page surface checker and flow helper kept visible before dropping to the shorter attached-page shortcut or replay shortcuts.

If the broader Windows headed runbook already reopened the attached localhost branch, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` nearby and reprint that dedicated attached-page route helper before you drop into the compact top-level attached-page quickstart:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when the replay is being reopened from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows runbook, the dedicated attached-page helper, and this compact top-level quickstart to stay in the same read-first order before the helper chain narrows again.

If the current pages are still the pinned three-page compatibility bundle, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the known three-page compatibility set should stay pinned from the top-level router into the bundle-first branch before widening back into the broader issue `#3` helper stack.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the top-level attached-page quickstart first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

1. Top-level attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use this when you want the broader top-level attached-page bridge reprinted before the shorter follow-up helpers.

2. Suite-router attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use this when the route should keep the newer suite-router attached-page bridge visible before choosing between the catalog quickstart, the catalog bridge, the Google-shaped attached-page helper, the attached-page shortcut, replay shortcuts, the next-step matrix, bundle-first helper, or safe-route map.

3. Top-level attached HTML catalog quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
```

Use this when you want the compact top-level attached-page quickstart and the suite-catalog attached-page bridge kept visible together before the route narrows again.

4. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when you want the suite-catalog-side attached-page bridge printed immediately after the top-level quickstart or the catalog quickstart so the route stays visible before widening again.

5. Google attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use this when the replay still needs the broader Google-shaped attached-page surface checker and flow helper before narrowing again.

6. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the attached-page compatibility route kept visible before widening back into replay shortcuts, the next-step matrix, or the safe-route map.

7. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen into the next-step matrix, contextual flow, bundle-first helper, or safe-route map.

8. Suite-router next-step matrix

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Use this when you want the executable branch matrix reprinted after the top-level quickstart before choosing the narrower replay surface.

9. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use this when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.

10. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

11. Safe-route entrypoints

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the route has already narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical rule

Once `show_headed_validation_suites.ps1` has already narrowed the route to attached localhost HTML follow-up from the top-level side, prefer `show_google_issue3_top_level_attached_html_quickstart.ps1` before reopening the longer validation-chain notes again.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: go from `show_google_issue3_windows_full_use_attached_html_route.ps1` to the top-level attached-page quickstart, then the top-level attached-page bridge, then the suite-router attached-page quickstart, then the catalog quickstart or suite-catalog attached-page bridge, or the attached-page shortcut before widening again
- broader issue `#3` router already surfaced the attached localhost branch: go from `-SuiteName google-recommended` or `-ChangeArea google-input` to the top-level attached-page quickstart, then the top-level attached-page bridge or the suite-router attached-page quickstart, then the catalog quickstart or catalog bridge, or the attached-page shortcut before widening again
- broader router already surfaced the attached localhost branch and you want the generic attached-page route printed too: go from `-ChangeArea attached-html` to the top-level attached-page quickstart, then the top-level attached-page bridge, then the suite-router attached-page quickstart, then the catalog quickstart or replay shortcuts, then the safe-route map
- Google-specific attached-page surface still matters more than the generic shortcut chain: go from `-ChangeArea google-attached-html` to the top-level attached-page quickstart, then the Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the top-level attached-page quickstart with that same context first, then choose the catalog quickstart, replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
