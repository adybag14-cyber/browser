# Issue #3 Suite Router Entrypoint Guide

This note is the shortest bridge from the top-level headed validation suite map into the current issue `#3` replay helpers.

Use it when you start from `show_headed_validation_suites.ps1` and want the next helper chosen quickly without reopening the longer Windows runbook or the full wrapper-heavy safe-route notes first, while still keeping the broader attached-page flow and the dedicated Google-shaped attached-page flow visible before the route narrows too far.

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

If the replay is already narrowed to that same attached localhost route and you still want the broader attached-page flow plus the dedicated Google-shaped attached-page flow visible before the validation-router or replay-side ladders take over, keep these companion helpers nearby too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

If the replay is already running from a non-default checkout or from explicit attached bundle paths, preserve that same context directly on the Google-shaped flow helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` nearby when you want the written companion for that narrower Google-shaped attached-page flow before the route falls back into the compact attached-page helpers.

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

If the replay is already entering from the broader Windows full-use attached-page route, or from `show_headed_validation_suites.ps1 -ChangeArea attached-html` after the change-area quickstart is already in view, print the validation-router attached-page quickstart next so the Windows-first route, the route guard, the Windows-side catalog quickstart, the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, and the narrower replay-side ladder stay aligned:

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
- `show_google_issue3_attached_html_change_area_quickstart.ps1` immediately after `show_headed_validation_suites.ps1 -ChangeArea attached-html` when you want the shortest attached-page handoff plus the broader attached-page flow helper and the dedicated Google attached-page flow helper visible before the validation-router and replay-side ladders narrow the route again.
- `show_google_issue3_validation_router_attached_html_quickstart.ps1` immediately after the Windows full-use attached-page route or the attached-html change-area quickstart when you want the shortest validation-router-side bridge from the main validation catalog into the narrower attached-page helper ladder while keeping the broader attached-page flow and the dedicated Google-shaped attached-page flow in view.
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

Use this compact sequence when the replay is already narrowed to the attached localhost HTML route and should stay on the attached-page-specific bridge while keeping the broader attached-page flow helper and the dedicated Google-shaped attached-page flow visible before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
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