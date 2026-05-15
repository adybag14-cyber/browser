# Issue #3 Replay-Route Shortcut Bridge

Use this note when issue `#3` work is already inside the replay-route helper and the next replay should move quickly into the shorter attached-page, replay-shortcuts, bundle-first, or safe-route follow-up without reopening the broader route notes first.

If you want the shortest replay-route follow-up, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`

## Goal

Start from `show_google_issue3_replay_route.ps1`, then hand off immediately into `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the route is already known to stay inside the narrower issue `#3` helper chain.

From there, prefer one of these shorter follow-ups before reopening the broader safe-route notes:

- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this route when the replay-route helper is already open and you want the narrowest stable bridge back into the attached-page shortcut, replay-shortcuts surface, and return-to-safe-route helpers.

## Broader validation-router surfacing

Because `show_headed_validation_suites.ps1` now surfaces the issue `#3` top-level attached HTML route, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the bundle-first helper directly from the broader `google-recommended`, `google-input`, and `attached-html` entrypoints, reopen one of those broader router surfaces first when attached localhost follow-up is already the next obvious branch but the replay has not been narrowed to `show_google_issue3_replay_route.ps1` yet.

Use this route when you want the attached-page re-entry surfaced directly from the broader validation catalog before you drop into the replay-route helper and its shorter shortcut bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use that broader router-first route when:

- the broader issue `#3` validation catalog already made attached localhost follow-up obvious
- you still want the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, and the top-level attached-page catalog quickstart visible before the replay-route helper narrows again
- the suite-catalog attached-page bridge, the bundle-first helper, and the broader Windows-first catalog route should remain easy to reopen from that same broader router surface before you widen into the wrapper-heavy safe route

If you are reopening the attached localhost route from `docs/WINDOWS_FULL_USE.md` first, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` and `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md` nearby or print their companion helpers first so the broader Windows runbook route, its Windows-first catalog quickstart, and the narrower replay-route bridge stay aligned before following the same validation-router attached-page quickstart, top-level attached-page quickstart, top-level attached-page bridge, top-level attached-page catalog quickstart, and replay-route sequence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
```

If the current pages are still the pinned three-page compatibility bundle, reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` first and keep `show_google_issue3_attached_bundle_first_entrypoint.ps1` nearby before widening back into replay-route or the broader safe-route map.

## Attached-page-first alternate route

Use this alternate sequence when the replay-route helper is already open but the next decision still needs the broader attached localhost HTML bridges kept visible before you collapse back to the tighter shortcut chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the current replay is still centered on the attached localhost compatibility pages and you want the broader attached-page bridges, the validation-router attached-page quickstart, and the top-level attached-page catalog quickstart printed before reopening the tighter replay-shortcuts surface.

## Preserve replay context

If the replay is already carrying a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the replay-route shortcut helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

Use this when the replay-route helper is already out of the way and you want the shorter top-level attached-page bridge before replay shortcuts, the bundle-first helper, or the safe-route map.

2. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when you want the suite-catalog-side attached-page bridge kept visible before widening into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

3. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the attached-page compatibility route kept visible before you widen back into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

4. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the narrower compact helper surface before deciding whether to widen into the bundle-first helper or the safe-route map.

5. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

6. Safe-route entrypoints map

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the replay-route helper is already out of the way and you want the current wrapper-heavy issue `#3` commands, notes, and runner-state helper surfaced in one place before the next fresh replay or reuse-current-outputs step.

## Bundle-first alternate route

Use this alternate sequence when the current saved or attached pages are still the pinned three-page compatibility bundle and the replay should stay there first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when:

- the current replay inputs are still the known three-page compatibility set
- you want the pinned bundle route exercised before reopening the broader safe-route chain
- the next useful decision depends on whether the attached-page bundle still reproduces the current headed issue `#3` state

## Practical rule

Only jump straight to `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when `show_google_issue3_replay_route.ps1` is already open or the replay has already been narrowed to that point.

- attached localhost follow-up is obvious from the broader validation catalog or from `docs/WINDOWS_FULL_USE.md`, but replay-route is not open yet: reopen the broader attached-page router first, then `show_google_issue3_validation_router_attached_html_quickstart.ps1`, then the top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, then `show_google_issue3_replay_route.ps1`, then the replay-route shortcut helper; when the route is reopening from `docs/WINDOWS_FULL_USE.md`, print `show_google_issue3_windows_full_use_attached_html_route.ps1` and `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1` before that narrower validation-router sequence
- no pinned bundle inputs and no saved replay state yet, and replay-route is already open: go straight from replay route to the replay-route shortcut helper, then attached HTML shortcut, then replay shortcuts, then the safe-route map
- the attached localhost compatibility route still needs a broader bridge first after replay-route is already open: go from the replay-route shortcut helper to the validation-router attached-page quickstart, the top-level attached HTML entrypoint, or the suite-catalog attached HTML entrypoint before narrowing to the attached HTML shortcut and replay shortcuts
- saved summary or repo-root override already present: reopen the replay-route shortcut helper with that same context first, then choose replay shortcuts or the safe-route map only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- attached-page follow-up still matters more than the general shortcut chain: reopen the attached HTML shortcut first, then widen into replay shortcuts or the safe-route map only after that attached-page route is clear

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
