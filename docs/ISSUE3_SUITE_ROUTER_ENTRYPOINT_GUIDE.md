# Issue #3 Suite Router Entrypoint Guide

This note is the shortest bridge from the top-level headed validation suite map into the current issue `#3` replay helpers.

Use it when you start from `show_headed_validation_suites.ps1` and want the next helper chosen quickly without reopening the longer Windows runbook or the full wrapper-heavy safe-route notes first.

## Start points

Use either of these top-level headed validation router entrypoints first when the replay is broadly entering issue `#3`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

If the replay is already running from a non-default checkout, keep that same repo-root context attached to those top-level entrypoints:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -SuiteName 'google-recommended'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -ChangeArea 'google-input'"
```

If you still want the broader suite-catalog re-entry surface printed before the shorter suite-router bridge takes over, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that same context directly in the suite-catalog helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md` nearby when you want the written companion for that broader suite-catalog re-entry helper before the route narrows back into the shorter suite-router-side bridge.

If the broader Windows headed runbook already made attached localhost replay the next obvious branch, reopen the dedicated Windows full-use attached-page route first so that wider runbook surface stays aligned with the narrower issue `#3` helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that same context directly in the Windows full-use helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md` nearby when you want the written bridge from that Windows-first route into the validation-router attached-html quickstart before the helper chain narrows again.

Keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md` nearby too when you want the compact Windows-full-use-to-catalog bridge visible before the replay-side attached-page quickstart and the top-level helper chain.

If the current replay still needs the broader Google-shaped attached-page surface before the bundle is pinned, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

If the current replay is already narrowed to the attached localhost HTML route itself and you want the shortest attached-page-specific bridge from the main validation catalog before the route widens into the validation-router or replay-side ladders, keep this change-area entrypoint nearby too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

If the replay is already narrowed to that same attached localhost route and you want the newer compact handoff visible immediately before the validation-router quickstart, keep this companion helper nearby too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
```

If the next replay should stay pinned to the known attached three-page compatibility bundle, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

## Default next helper

After the top-level suite router, print the top-level shortcut-first entrypoint first when you want the shortest current bridge back into the general issue `#3` replay chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is already entering from `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the shortest attached-page handoff before the broader validation-router or replay-side ladders take over, print the attached-html change-area quickstart first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the attached-html change-area quickstart too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is already entering from the broader Windows full-use attached-page route, or from `show_headed_validation_suites.ps1 -ChangeArea attached-html` after the change-area quickstart is already in view, print the validation-router attached-page quickstart next so the Windows-first route, the route guard, the Windows-side catalog quickstart, and the narrower replay-side ladder stay aligned:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the validation-router attached-page quickstart too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay should keep the replay-side attached-page ladder visible before it narrows into the top-level helper family, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the replay-side attached-page quickstart too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

After the validation-router and replay-side quickstarts have re-established the narrower attached-page branch, print the compact top-level attached-page quickstart, then the top-level attached-page catalog quickstart, and then the suite-catalog-to-top-level attached-page catalog quickstart when you want the shortest top-level bridge plus the suite-catalog-side bridge visible before the route narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on those compact top-level helpers too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the route should keep the broader top-level attached-page bridge visible before narrowing again, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

If the route should keep the suite-router-side attached-page bridge visible before choosing the shorter attached-page or replay surfaces, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

If the route should keep the suite-catalog-side attached-page bridge visible before choosing the shorter attached-page or replay surfaces, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If the route is already narrow enough and you want the tightest current helper surface immediately, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

## Which helper should come next

The current default is:

- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` immediately after the top-level suite router when you want the shortest current bridge back into the general issue `#3` helper chain.
- `show_google_issue3_windows_full_use_attached_html_route.ps1` immediately after `docs/WINDOWS_FULL_USE.md` has already made the attached localhost branch obvious and you want the broader Windows-first route kept aligned with the newer attached-page helpers.
- `show_google_issue3_attached_html_change_area_quickstart.ps1` immediately after `show_headed_validation_suites.ps1 -ChangeArea attached-html` when you want the shortest attached-page handoff plus the broader attached-page flow helper visible before the validation-router and replay-side ladders narrow the route again.
- `show_google_issue3_validation_router_attached_html_quickstart.ps1` immediately after the Windows full-use attached-page route or the attached-html change-area quickstart when you want the shortest validation-router-side bridge from the main validation catalog into the narrower attached-page helper ladder.
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1` immediately after the validation-router attached-page quickstart when you want the replay-side attached-page ladder visible before the top-level quickstarts and the suite-catalog-side compact bridge.
- `show_google_issue3_top_level_attached_html_quickstart.ps1` immediately after the replay-side attached-page quickstart when you want the shortest top-level attached-page bridge back on screen before the route narrows again.
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` immediately after the top-level attached-page quickstart when you want the compact top-level attached-page plus suite-catalog-side bridge visible before choosing whether to widen into the broader top-level attached-page bridge, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route entrypoints.
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1` immediately after the top-level attached-page catalog quickstart when you want the replay-side attached-page ladder, the top-level catalog quickstart, and the suite-catalog-side bridge kept visible on one compact surface before the route narrows again.
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` after the suite-catalog-to-top-level catalog quickstart when the route should keep the broader top-level attached-page bridge visible before narrowing again.
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` after the suite-catalog-to-top-level catalog quickstart when the route should keep the suite-router-side attached-page bridge visible before choosing the shorter attached-page surfaces.
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` after the suite-catalog-to-top-level catalog quickstart when the route should keep the suite-catalog-side attached-page bridge visible before dropping to the attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.
- `show_google_issue3_replay_shortcuts.ps1` as the direct next helper once the route is already narrow enough and you want the tightest shortcut surface before deciding whether to widen into replay route, the bundle-first helper, or the safe-route entrypoints.
- `show_google_issue3_suite_router_next_steps.ps1` once the route is already known and you want the executable branch matrix reprinted before choosing the narrower replay surface.
- `show_google_issue3_contextual_flow.ps1` when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the current three-page compatibility set.
- `show_google_issue3_safe_route_entrypoints.ps1` once the attached-page branch is already out of the way and you want the current wrapper-heavy issue `#3` commands plus the runner-state helper surfaced in one place before the next fresh replay or reuse-current-outputs step.

## Read-first helper order

Use this compact sequence when the replay begins from the higher-level suite router and no pinned bundle or saved summary has forced a narrower path yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this sequence when the replay is being reopened from `docs/WINDOWS_FULL_USE.md` and the broader runbook has already narrowed the next step to attached localhost follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when the replay is already narrowed to the attached localhost HTML route and should stay on the attached-page-specific bridge before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when the replay still needs the broader Google-shaped attached-page surface before narrowing further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this compact sequence when the replay should stay pinned to the current attached three-page compatibility bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use this compact sequence when saved-summary state, repo-root overrides, or pinned bundle inputs already matter and the replay should keep the broader Windows and validation-router attached-page surfaces aligned before narrowing further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Keep these references nearby

- `docs/WINDOWS_FULL_USE.md` for the broader Windows headed runbook.
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` for the Windows-first attached localhost route.
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md` for the Windows-to-validation-router attached-page bridge.
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md` for the compact Windows-full-use-to-catalog bridge before the replay-side and top-level quickstarts.
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the broader replay guide.
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` for the replay-side attached-page ladder.
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the validation-router-side attached-page quickstart.
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md` for the shortest attached-html handoff reopened directly from `show_headed_validation_suites.ps1 -ChangeArea attached-html`.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` for the compact top-level attached-page bridge.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md` for the compact top-level plus suite-catalog attached-page bridge.
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md` for the replay-side plus top-level-catalog compact bridge before the suite-catalog attached-page helper narrows further.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the broader top-level attached-page bridge.
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the suite-router-side attached-page bridge.
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md` for the broader suite-catalog re-entry surface that now sits beside this shorter suite-router guide.
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` for the dedicated suite-catalog attached-page bridge.
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge from the top-level shortcut helper into replay shortcuts.
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and the larger safe-route ordering.
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the safe-route handoff emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`.

## Practical rule

Start from the top-level headed validation suite router, then move immediately into `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and no saved summary or pinned bundle inputs need to take precedence first.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: run `show_google_issue3_windows_full_use_attached_html_route.ps1` first, then the route-level surface check, then the Windows-to-validation-router bridge, then the Windows full-use attached-html catalog quickstart, then the validation-router attached-page quickstart, then the replay-side attached-page quickstart, then the top-level attached-page quickstart, then the top-level attached-page catalog quickstart, then the suite-catalog-to-top-level attached-page catalog quickstart, then the broader top-level attached-page bridge, then the suite-router and suite-catalog attached-page bridges before widening again.
- broader issue `#3` router already surfaced the attached localhost branch: go from `-SuiteName google-recommended` or `-ChangeArea google-input` to the top-level shortcut helper when the route is still generic, reopen `show_google_issue3_suite_catalog_entrypoints.ps1` plus `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md` when you want the broader suite-catalog re-entry surface kept visible before the narrower suite-router-side ladder, or go directly to the attached-html change-area quickstart when attached localhost follow-up is already the next obvious branch, then reopen the validation-router attached-page quickstart, the replay-side attached-page quickstart, and the suite-catalog-to-top-level attached-page catalog quickstart as soon as the route needs the narrower helper ladder back on screen.
- current replay already narrowed to the attached localhost HTML route: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` first, then keep the attached-html change-area quickstart, the validation-router attached-page quickstart, the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the broader top-level attached-page bridge, the suite-router attached-page quickstart, and the suite-catalog attached-page bridge visible before choosing between the attached-page shortcut, replay shortcuts, or the safe-route map.
- broader Google-shaped attached-page surface still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` first, then the validation-router attached-page quickstart, then the replay-side attached-page quickstart, then the top-level attached-page quickstart, then the top-level attached-page catalog quickstart, then the suite-catalog-to-top-level attached-page catalog quickstart, then the Google attached-page entrypoint before narrowing further.
- explicit bundle paths already pinned: stay on the validation-router attached-page quickstart, then the replay-side attached-page quickstart, then the suite-catalog-to-top-level attached-page catalog quickstart before the bundle-first helper so the pinned bundle route stays visible before widening back into the broader Google-only path.
- saved summary or repo-root override already present: reopen the attached-html change-area quickstart, the validation-router attached-page quickstart, the replay-side attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, and the broader suite-catalog re-entry helper with that same context first, then choose replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed.

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
