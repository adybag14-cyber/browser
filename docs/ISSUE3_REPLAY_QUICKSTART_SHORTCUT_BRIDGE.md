# Issue #3 Replay Quickstart Shortcut Bridge

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay back to issue `#3`, and you want the shortest stable next helper without reopening the longer router and safe-route notes first.

Keep these companion notes nearby:
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`, then hand off into the compact issue `#3` helper ladder without losing the broader Windows full-use attached-page route, the Windows-to-validation-router bridge, the Windows-side attached-page catalog quickstart, the replay-shortcuts-to-Windows-replay bridge, the replay-side attached-page quickstart, the broader attached-page flow helper, the Google-shaped attached-page flow helper, the attached-page change-area quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the newer top-level shortcut bridge, the replay-route shortcut bridge, the compact bundle-suite surface, the suite-catalog helper, the suite-router handoff, the suite-router next-step matrix, the replay-route companion, and the runner-state follow-ups before the route widens back into the safe-route map.

## Default shortcut-first route

Use this route when the top-level suite router already made issue `#3` obvious and no saved summary or pinned bundle inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:
- the replay is already clearly inside issue `#3`, but you still want the broader Windows-side and attached-page ladders visible before the route narrows again
- you still want the newer top-level shortcut bridge, replay-route shortcut bridge, compact bundle-suite surface, suite-catalog helper, suite-router handoff, suite-router next-step matrix, and replay-route companion easy to reopen from the same compact surface
- the runner-state helpers should remain nearby before you widen back into the wrapper-heavy safe-route notes

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the shortcut-first entrypoint first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Direct Windows validation-bridge route

If the shorter replay surface still needs the direct Windows-to-validation-router handoff visible before the replay-side attached-page ladder narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that bridge-first route when:
- the replay is already inside `show_google_issue3_replay_shortcuts.ps1`
- you want the direct Windows-side validation-router handoff and the replay-shortcuts-to-Windows-replay bridge reprinted before the narrower replay-side quickstart
- you still want both the broader attached-page flow helper and the narrower Google-style attached-page guide visible before the top-level attached-page helpers take over

## Windows replay attached-page ladder

If `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay to the attached localhost branch and you want the shortest helper ladder that matches that Windows replay surface without reopening the broader router notes first, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the Windows replay attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that Windows replay attached-page ladder when:
- the replay was already narrowed from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` into the attached localhost branch
- you want the direct Windows validation bridge, the replay-shortcuts-to-Windows-replay bridge, the suite-catalog guide, the validation-router attached-page quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow guide, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, and the attached-page shortcut surfaced from one Windows-replay-side helper or easy to reopen beside it
- the broader Windows full-use attached-page route, its validation-router bridge, and its Windows-side catalog quickstart should remain easy to reopen before you widen back into the top-level shortcut bridge, replay shortcuts, the contextual flow, the bundle-first helper, or the safe-route map

## Top-level attached-page route

If the replay is already narrowed to the attached localhost HTML route and you want the broader top-level attached-page chain kept visible before the helper surface collapses back to the shorter shortcut flow, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly on the change-area, validation-router, top-level, suite-router, and suite-catalog attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that top-level attached-page route before the broader replay shortcuts when:
- the current replay is centered on the three attached localhost compatibility pages
- the bundle is not pinned yet and the broader attached-page helpers should stay visible
- you still want the attached-html change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow guide, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, and the suite-catalog attached-page bridge visible before the narrower attached-page shortcut surface
- you still want the top-level router, attached-page route, the dedicated Google-shaped attached-page route, top-level shortcut bridge, shortcut-first bridge, and suite-catalog guide to remain easy to reopen

## Broader validation-router surfacing

Because `show_headed_validation_suites.ps1` now surfaces the issue `#3` validation-router attached-page quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the bundle-first helper, and the dedicated Google-style attached-page flow helper directly from the broader `google-recommended`, `google-input`, and attached-page change-area entrypoints, reopen one of those broader router surfaces first when attached localhost follow-up has already become the next obvious branch but the replay has not been narrowed to the shorter helper chain yet.

Use this route when you want the attached-page branch surfaced directly from the broader validation catalog before you drop into the shorter issue-specific helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that broader router-first route when:
- the broader issue `#3` validation catalog already made attached localhost follow-up obvious
- you still want the suite-catalog guide, the attached-html change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow guide, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, and the suite-catalog attached-page bridge visible before replay shortcuts or the attached-page shortcut collapse the route again
- the bundle-first helper should remain easy to reopen from that same broader router surface before you widen into the wrapper-heavy safe route

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`, `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`, `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`, `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`, `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`, `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`, `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`, and `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md` nearby or print the route guard plus the Windows-side companion helpers first so the broader Windows runbook route, its fail-fast surface check, its validation-router bridge, its newer Windows-first catalog quickstart, its replay-shortcuts-to-Windows-replay bridge, its replay-side attached-html quickstart, its suite-catalog guide, and the narrower attached-page bridge stay aligned before you follow the same attached-html change-area, broader attached-page flow, Google attached-page flow, validation-router attached-page quickstart, top-level attached-page quickstart, top-level attached-page bridge, top-level attached-page catalog quickstart, and suite-catalog-to-top-level attached-page catalog quickstart sequence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

If the replay is already clearly inside `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` and the next move is to keep that shorter attached-page ladder together, prefer `show_google_issue3_windows_replay_attached_html_quickstart.ps1` before you widen back into the broader replay shortcuts or safe-route map.

If the current pages are still the pinned three-page compatibility bundle, reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` first and keep `show_google_issue3_attached_bundle_first_entrypoint.ps1` nearby before widening back into the broader replay shortcuts or safe-route map.

## Compact follow-up surface

If the replay already sits inside the replay quickstart shortcut chain and you only need the newer narrow follow-ups reprinted before choosing the next move, reopen whichever of these matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use that compact follow-up surface when:
- the route still needs the newer top-level shortcut bridge or replay-route shortcut bridge before collapsing back into the shorter attached-page helper chain
- the compact bundle-suite surface should stay visible before the bundle-first helper or delegated bundle runner takes over
- the suite-catalog command map, suite-router handoff, suite-router next-step matrix, or replay-route companion should stay visible before you widen back into replay shortcuts or the safe-route map
- the replay already carries repo root, summary, or pinned bundle state and the contextual helper should keep that state aligned before the next narrower command

## Runner-state follow-up

If the replay quickstart shortcut bridge is already open and the next useful move depends on runner state rather than another navigation note, use one of these:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```

Use that runner-state route when:
- the current issue `#3` outputs may be stale or missing and you want the fresh safe-route replay to regenerate the current handoff artifact first
- a saved `SummaryPath` already exists and the current outputs are still trusted, so the wrapper should reopen against those outputs before you widen into a broader regeneration pass
- the route needs the runner decision-table guidance or output-patch rules nearby before the wrapper-heavy safe-route helpers take over

## Pinned bundle branch

If the current pages are still the known three-page compatibility bundle and you want that exact route kept visible before replay shortcuts widens back into the wrapper-heavy safe path, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that pinned bundle branch when:
- the current replay inputs are still the known three-page compatibility set
- you want the higher-level bundle change-area route, the compact bundle-suite surface, and the bundle-first entrypoint visible together before widening back into replay shortcuts or the safe-route map
- the attached-page flow should stay pinned to the same fixed inputs until the bundle run clarifies the next replay state
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` should stay nearby while the route remains locked to the bundle-first branch

## Attached-page branch

If the replay is already narrowed from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` and you want that same Windows-side attached-page ladder reprinted from one compact helper before choosing the narrower attached-page bridge, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

If the replay is already narrowed past the top-level attached-page route and you want the shorter attached-page bridge kept visible before widening back into the broader helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use that attached-page branch before the broader replay shortcuts when:
- the current replay is centered on the three attached localhost compatibility pages
- the bundle is not pinned yet and the narrower attached-page helper should stay visible
- you still want the suite-catalog-to-top-level attached-page catalog quickstart and the suite-catalog attached-page bridge available before the attached-page shortcut collapses the route further
- you still want the top-level router, attached-page route, top-level shortcut bridge, shortcut-first bridge, and suite-catalog guide to remain easy to reopen

## When To Widen

Reopen one of these helpers only when the narrower shortcut surface is no longer enough:
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1` when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already pointed at the attached localhost branch and you want the shorter direct Windows validation bridge, replay-shortcuts-to-Windows-replay bridge, suite-catalog guide, validation-router attached-page quickstart, broader attached-page flow helper, Google attached-page flow guide, top-level attached-page quickstart, broader top-level attached-page bridge, top-level attached-page catalog quickstart, suite-catalog-to-top-level attached-page catalog quickstart, suite-catalog attached-page bridge, and attached-page shortcut ladder reprinted from one Windows-replay-side helper before replay shortcuts or the safe-route map.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the broader validation catalog should reprint the attached-page route before the issue-specific helper chain narrows again.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` when the broader router should reopen on the pinned three-page bundle branch first and you want `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` plus `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` nearby before widening again.
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1` when the replay-side attached-html ladder plus the top-level attached-page catalog route should stay visible together before you choose between the suite-catalog bridge, the attached-page shortcut, replay shortcuts, or the safe-route map.
- `show_google_issue3_suite_catalog_entrypoints.ps1` when the broader suite-catalog route should stay visible before the replay falls back into the narrower attached-page bridge.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the broader replay-route helper is already open and you want the smaller follow-up surface first.
- `show_google_issue3_suite_router_handoff.ps1` when the compact handoff surface should stay visible before the route narrows into the shorter shortcut helpers.
- `show_google_issue3_suite_router_next_steps.ps1` when you still want the explicit executable matrix before choosing the next branch.
- `show_google_issue3_replay_route.ps1` when the attached-bundle route, saved summary state, runner-state helper, and replay-route shortcut companion should stay visible together.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the known three-page compatibility set.
- `show_google_issue3_runner_patch_next_step.ps1`, `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`, or `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1` when the next useful step depends on runner state rather than another attached-page note.
- `show_google_issue3_safe_route_entrypoints.ps1` when the next step is ready to move back into the wrapper-heavy safe-route helpers.

## Practical rule

Start from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`, then reopen `show_headed_validation_suites.ps1 -SuiteName google-recommended`, `show_headed_validation_suites.ps1 -ChangeArea google-input`, `show_headed_validation_suites.ps1 -ChangeArea attached-html`, or `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` first when the broader validation catalog has already made attached localhost follow-up the next obvious branch.

If the replay is already clearly inside the narrower Windows replay attached-page branch, run `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, then `show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1`, then `show_google_issue3_windows_replay_attached_html_quickstart.ps1` so the direct Windows validation bridge, the replay-shortcuts-to-Windows-replay bridge, the suite-catalog guide, the validation-router attached-page quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow guide, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, and the attached-page shortcut stay on one coherent replay-side ladder before you narrow further.

If the replay is already reopening from `-ChangeArea attached-html`, run `show_google_issue3_suite_catalog_entrypoints.ps1` first when the broader suite-catalog surface should stay visible, then `show_google_issue3_attached_html_change_area_quickstart.ps1`, then `show_attached_html_validation_flow.ps1`, then `show_google_attached_html_validation_flow.ps1`, then `show_google_issue3_validation_router_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, then `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`, then `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`, before narrowing into the suite-router attached-page quickstart, the attached-page shortcut helper, or replay shortcuts.

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, print `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, `show_google_issue3_windows_full_use_attached_html_route.ps1`, `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, `show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1`, and `show_google_issue3_windows_replay_attached_html_quickstart.ps1` before that narrower attached-page sequence so the broader Windows-first route stays aligned with the replay quickstart shortcut bridge.

If the current replay is already pinned to the three-page compatibility bundle, reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`, then `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`, then `show_google_issue3_attached_bundle_first_entrypoint.ps1` before replay shortcuts or the safe-route map widens back out.

If the next useful move depends on runner state instead of another routing note, reopen `show_google_issue3_runner_patch_next_step.ps1`, `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`, or `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1` before the wider safe-route map so the current handoff status stays grounded in the same replay context.

Widen back into replay-route, the next-step matrix, or the safe-route map only when the narrower shortcut surface stops being enough.
