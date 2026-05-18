# Issue #3 Suite-Router Shortcut-First Entrypoint

Use this note when issue `#3` replay is already clearly inside the suite-router branch and you want the shortest written bridge into the narrower replay helpers before the route widens again.

This note matches `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`

## Goal

Start from the top-level suite router, the attached-page shortcut surface, or the Google-shaped attached-page branch, then move into `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when the next replay is already known to stay inside issue `#3` and the main decision is between the replay shortcuts, contextual flow, the next-step matrix, the pinned bundle-first branch, or the safe-route map.

Use this note when:
- the route is already clearly inside issue `#3` and you want the narrowest suite-router-side bridge first
- the replay may still widen into the attached-page shortcut, but you do not want to reopen the longer attached-page notes too early
- you still want the replay quickstart, suite-router bridge, suite-catalog guidance, and the issue-specific Google attached-page bridge easy to reach from one written entrypoint

## Shortcut-First Bridge

If you want the shortest suite-router-side issue `#3` bridge, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this when the higher-level router already made it clear that the replay stays inside issue `#3`, but you still want the attached-page shortcut, replay shortcuts, and bundle-first branch close at hand.

## Broader Router Surfacing

If you want the broader suite-router surfaces visible before the shortcut-first bridge narrows the route, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
python .\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py --root '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay is still re-entering from the shared validation catalog and you want the broader Google lane, the lighter sidecar-bundle audit, the broader Google-shaped attached-page surface checker, the issue-specific Google attached-page checker, and the issue-specific Google attached-page bridge reprinted before the suite-router shortcut-first bridge hands off to the narrower issue `#3` helpers.

## Attached HTML Handoff

If attached localhost follow-up is already the next obvious branch, keep the attached-page shortcut visible before the route drops back into the narrower replay helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay is already centered on the attached-page compatibility branch and you want the dedicated attached-page shortcut plus the suite-router shortcut-first bridge kept on the same written ladder before the route narrows into the tighter replay surface.

If the replay still needs the broader Google-shaped attached-page surface before the route narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
python .\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py --root '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay still needs the lighter sidecar-bundle audit, the broader Google-specific attached-page surface checker, and the issue-specific Google attached-page checker and bridge visible before it collapses back into the shorter issue `#3` route.

## Bundle-First Route

If the current pages are still the pinned three-page compatibility bundle, keep that route visible first instead of narrowing through the shortcut-first bridge too early:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay explicit before the replay widens back into the broader issue `#3` helper chain.

## Preserve Replay Context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the helper you reopen next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the route:

```powershell
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

## Pick The Next Helper Quickly

1. `show_google_issue3_replay_shortcuts.ps1`

Use this as the default follow-up when the route is already clearly inside issue `#3` and no attached-page-specific bridge needs to stay visible first.

2. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the replay is already narrowed to attached-page follow-up and you want the dedicated attached-page shortcut kept visible before the route collapses into the tighter replay surface.

3. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle state already matters and the next helper should keep that replay context aligned.

4. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after the suite-router shortcut-first bridge before choosing the narrower replay surface.

5. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

6. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the route has already narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical Rule

Start from the top-level headed validation suite router, then use `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3`. If attached localhost follow-up becomes the next obvious branch, reopen `show_google_issue3_attached_html_shortcut_entrypoint.ps1` first and only then return to the suite-router shortcut-first bridge before replay shortcuts.

- route already clearly inside issue `#3` with no attached-page-specific bridge needed yet: go straight to `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then replay shortcuts, then the safe-route entrypoints helper
- route already narrowed to attached localhost compatibility follow-up: go straight to `show_google_issue3_attached_html_shortcut_entrypoint.ps1`, then `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then replay shortcuts, then the next-step matrix or safe-route map
- route already narrowed to the Google-shaped attached localhost branch: rerun the sidecar-bundle audit, `check_google_attached_html_validation_surface.ps1`, `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`, reopen `show_google_issue3_google_attached_html_entrypoint.ps1`, then `show_google_issue3_attached_html_shortcut_entrypoint.ps1`, then `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then replay shortcuts
- saved summary or repo-root override already present: reopen the matching compact helper with that same context first, then widen into contextual flow, the next-step matrix, or the bundle-first helper only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
