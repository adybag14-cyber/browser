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

If the broader Windows headed runbook already made attached localhost replay the next obvious branch, reopen the dedicated Windows full-use attached-page route first so that wider runbook surface stays aligned with the narrower issue `#3` helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that same context directly in the Windows full-use helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the current replay still needs the broader Google-shaped attached-page surface before the bundle is pinned, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

If the current replay is already narrowed to the attached localhost HTML route itself and you want the shortest top-level bridge into the attached-page helper chain, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

If the current replay is already narrowed to the attached localhost HTML route from the broader validation router and you want the shortest router-side bridge into the newer top-level attached-page quickstarts before reopening the broader issue `#3` helper chain, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that same context directly in the validation-router attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the next replay should stay pinned to the known attached three-page compatibility bundle, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

## Default next helper

After the top-level suite router, print the top-level shortcut-first entrypoint first when you want the shortest current bridge back into the issue `#3` replay chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is already entering from the broader Windows full-use attached-page route, print the validation-router attached-page quickstart first so the Windows-first branch and the narrower attached-page helper chain stay in the same order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

If the replay is already narrowed to the attached localhost HTML route from the top-level suite router and you want the shortest bridge into the newer top-level attached-page quickstarts before deciding whether to continue into the broader top-level attached-page bridge, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map, print the same validation-router attached-page quickstart first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the validation-router attached-page quickstart too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

After the validation-router attached-page quickstart has re-established the narrower attached-page branch, print the compact top-level attached-page quickstart when you want the shortest top-level attached-page bridge before deciding whether to continue into the broader top-level attached-page bridge, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the top-level attached-page quickstart too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` immediately after the top-level suite router when you want the shortest current bridge back into the issue `#3` helper chain.
- `show_google_issue3_windows_full_use_attached_html_route.ps1` immediately after `docs/WINDOWS_FULL_USE.md` has already made the attached localhost branch obvious and you want the broader Windows-first route kept aligned with the newer attached-page helpers.
- `show_google_issue3_validation_router_attached_html_quickstart.ps1` immediately after `show_headed_validation_suites.ps1 -ChangeArea attached-html` or the Windows full-use attached-page route when you want the shortest router-side bridge from the main validation catalog into the newer top-level attached-page quickstarts before widening into the broader top-level attached-page bridge, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route entrypoints.
- `show_google_issue3_top_level_attached_html_quickstart.ps1` immediately after the validation-router attached-page quickstart when you want the shortest top-level attached-page bridge before choosing whether to widen into the top-level attached-page bridge, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route entrypoints.
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` after the top-level attached-page quickstart when the route should keep the broader top-level attached-page bridge visible before narrowing again.
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` after the top-level attached-page quickstart when the route should keep the suite-router-side attached-page bridge visible before choosing the shorter attached-page surfaces.
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` after the suite-router attached-page quickstart when the route should keep the suite-catalog-side attached-page bridge visible before dropping to the attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when the replay is already narrowed to the attached localhost HTML route and should stay on the attached-page-specific bridge before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this compact sequence when the replay should stay pinned to the current attached three-page compatibility bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use this compact sequence when saved-summary state, repo-root overrides, or pinned bundle inputs already matter and the replay should keep the broader Google flow aligned before narrowing further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Keep these references nearby

- `docs/WINDOWS_FULL_USE.md` for the broader Windows headed runbook.
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` for the Windows-first attached localhost route.
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` for the compact top-level attached-page bridge.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the broader top-level attached-page bridge.
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the suite-router-side attached-page bridge.
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` for the dedicated suite-catalog attached-page bridge.
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge from the top-level shortcut helper into replay shortcuts.
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and fresh replay entrypoints.
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the safe-route handoff emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`.

## Practical rule

Start from the top-level headed validation suite router, then move immediately into `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and no saved summary or pinned bundle inputs need to take precedence first.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: run `show_google_issue3_windows_full_use_attached_html_route.ps1` first, then `show_headed_validation_suites.ps1 -ChangeArea attached-html`, then the validation-router attached-page quickstart, then the top-level attached-page quickstart, then the broader top-level attached-page bridge, then the suite-router and suite-catalog attached-page bridges before widening again.
- broader issue `#3` router already surfaced the attached localhost branch: go from `-SuiteName google-recommended` or `-ChangeArea google-input` to the top-level shortcut helper when the route is still generic, or go directly to the validation-router attached-page quickstart when attached localhost follow-up is already the next obvious branch.
- current replay already narrowed to the attached localhost HTML route: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` first, then keep the validation-router attached-page quickstart, the top-level attached-page quickstart, the broader top-level attached-page bridge, the suite-router attached-page quickstart, and the suite-catalog attached-page bridge visible before choosing between the attached-page shortcut, replay shortcuts, or the safe-route map.
- broader Google-shaped attached-page surface still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` first, then the top-level attached-page quickstart, then the Google attached-page entrypoint before narrowing further.
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path.
- saved summary or repo-root override already present: reopen the validation-router attached-page quickstart with that same context first, then choose replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed.

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
