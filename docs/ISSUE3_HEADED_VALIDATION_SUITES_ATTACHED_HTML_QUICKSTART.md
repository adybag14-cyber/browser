# Issue #3 Headed Validation Suites Attached HTML Quickstart

Use this note when issue `#3` replay starts from the main headed validation suite router and the next replay is already narrowed to the attached localhost compatibility route.

Keep these companion notes nearby:
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from one of the attached-page entrypoints printed by `show_headed_validation_suites.ps1`, then move immediately into the narrower issue `#3` attached-page helper chain without rebuilding the route by hand.

Prefer these headed validation suite entrypoints:
- `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
- `show_headed_validation_suites.ps1 -SuiteName google-attached-html`
- `show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle`

From there, use the smaller issue `#3` attached-page helpers in this order:
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact route when no non-default repo root, saved summary, or explicit bundle input list needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the main suite router has already narrowed replay to attached localhost follow-up and you want the top-level attached-page quickstart plus the suite-router attached-page quickstart kept visible before the route widens again.

## Google-shaped attached-page variant

If the replay still needs the broader Google-shaped attached-page helper visible before it narrows again, start from this route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the broader Google-specific surface checker and flow helper still matter more than the shortest attached-page shortcut.

## Pinned three-page bundle variant

If the current replay should stay pinned to the known three-page compatibility bundle, use this route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the attached localhost replay should remain locked to the current three-page bundle all the way through the bundle-first helper and delegated localhost runner.

## Preserve replay context

If replay already has a non-default repo root, saved summary, or explicit input list, keep that same context attached from the main suite router onward:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then pick the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving route when:
- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when the main suite router has already narrowed replay to attached localhost follow-up and you want the shortest top-level bridge first.

2. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when you want the newer suite-router attached-page bridge printed immediately after the top-level quickstart before deciding between the catalog bridge, Google-shaped helper, attached-page shortcut, replay shortcuts, next-step matrix, bundle-first helper, or safe-route map.

3. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when you want the broader top-level attached-page bridge reprinted before the shorter follow-up helpers.

4. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when you want the suite-catalog-side attached-page bridge reprinted before widening back out.

5. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the Google-shaped attached-page surface still needs to stay visible before replay narrows again.

6. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the shortest attached-page compatibility bridge before widening back into replay shortcuts, the next-step matrix, or the safe-route map.

7. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

8. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you want the executable next-step matrix reprinted after the top-level and suite-router quickstarts.

9. `show_google_issue3_contextual_flow.ps1`

Use this when repo root, summary path, or pinned input context already matters and the next helper surface should keep that replay state aligned.

10. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

11. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the route has already narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical rule

Once `show_headed_validation_suites.ps1` has already narrowed the route to attached localhost follow-up, prefer `show_google_issue3_top_level_attached_html_quickstart.ps1` and then `show_google_issue3_suite_router_attached_html_quickstart.ps1` before reopening the longer validation-chain notes.

- attached localhost route already obvious: go from `-ChangeArea attached-html` to the top-level quickstart, then the suite-router quickstart, then the attached-page bridge or shortcut helpers
- Google-specific attached-page flow still matters: go from `-ChangeArea google-attached-html` to the same quickstarts, then the Google attached-page entrypoint
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader helper chain
- saved summary or repo-root override already present: reopen the same quickstarts with that context first, then choose replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
