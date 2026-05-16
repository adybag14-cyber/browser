# Issue #3 Replay-Shortcuts To Windows Replay Attached HTML Bridge

Use this note when issue `#3` work is already inside `show_google_issue3_replay_shortcuts.ps1`, but the next replay should stay on the Windows replay attached-page ladder before widening back into the broader safe-route helpers.

If you want the shortest helper for that handoff, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
```

If the replay is already running from a non-default checkout, from a saved summary, or from explicit attached-bundle paths, preserve that same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `show_google_issue3_replay_shortcuts.ps1`, then hand off into the shorter Windows replay attached-page ladder so the replay-side fail-fast check, the broader Windows-first route, the Windows-side catalog step, the broader attached-page route, the pinned attached-bundle suite surface, the broader Google-shaped attached-page flow, the newer top-level shortcut bridge, the replay-route shortcut bridge, the newer replay-route bundle-first bridge, the compact bundle-suite surface, the newer suite-router shortcut-first entrypoint, the written suite-router shortcut bridge, the broader suite-router entrypoint guide, the suite-catalog helper, the compact suite-router handoff and next-step matrix, the smaller replay-route companion, the runner-state next-step helper, and the narrower attached-page quickstarts stay visible before the route collapses into the shortest attached-page shortcut or widens back into the safe-route map.

From there, prefer one of these narrower follow-ups before reopening the wrapper-heavy safe-route stack:

- `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `show_google_issue3_validation_router_attached_html_quickstart.ps1`
- `show_google_issue3_attached_html_change_area_quickstart.ps1`
- `show_google_attached_html_validation_flow.ps1`
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
- `show_google_issue3_suite_catalog_entrypoints.ps1`
- `show_google_issue3_suite_router_handoff.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_replay_route.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_runner_patch_next_step.ps1 -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first route

Use this route when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Use that route when:

- the replay is already clearly inside issue `#3` and the next choice should stay on the replay-side attached-page ladder for another step
- you want both the replay-quickstart and broader route-level fail-fast checks rerun before trusting the narrower attached-page sequence
- you still want the broader Windows route, the Windows-to-validation-router bridge, the Windows-side catalog step, the broader attached-page route, the broader attached-page and Google-shaped flow helpers, the pinned attached-bundle suite surface, the newer top-level shortcut bridge, the replay-route shortcut bridge, the replay-route bundle-first bridge note, the compact bundle-suite helper, the newer suite-router shortcut-first entrypoint, the written suite-router shortcut bridge, the broader suite-router entrypoint guide, the suite-catalog helper, the compact suite-router handoff and next-step matrix, and the smaller replay-route companion easy to reopen before the helper surface narrows further

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the bridge helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle
- you want the newer top-level shortcut, replay-route shortcut, compact bundle-suite, suite-router, suite-catalog, replay-route, or runner-state follow-ups to stay on the same pinned context instead of reopening generically

## Bundle-first alternate route

Use this alternate sequence when the current saved or attached pages are still the pinned three-page compatibility bundle and the replay should stay there first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the current replay inputs are still the known three-page compatibility set
- the next useful choice depends on whether the pinned bundle path still reproduces the current headed issue `#3` state
- you still want the higher-level pinned attached-bundle surface, the compact bundle-suite surface, and the pinned bundle reference nearby before the broader Google-only safe-route stack is reopened
- the broader Google-only safe-route stack should stay closed until the bundle route clarifies the next replay state

## Practical rule

Only use this bridge after `show_google_issue3_replay_shortcuts.ps1` is already the current helper surface.

- broader Windows-first attached-page route still matters: keep the route-level fail-fast check, the Windows full-use route, the Windows-to-validation-router bridge, and the Windows-side catalog step in front of the replay-side quickstart
- broader attached-page or pinned attached-bundle checkpoints still matter: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` or `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` before the narrower issue-specific attached-page helpers take over
- replay-side attached-page ladder is already the best mental model: jump straight from this bridge to `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- replay still needs one broader attached-page checkpoint after the replay-side quickstart: widen to `show_google_issue3_validation_router_attached_html_quickstart.ps1`, `show_google_issue3_attached_html_change_area_quickstart.ps1`, or `show_google_attached_html_validation_flow.ps1` before the top-level attached-page helpers take over
- top-level, suite-router, suite-catalog, or replay-route follow-up is already the next obvious move: reopen `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, `show_google_issue3_suite_catalog_entrypoints.ps1`, or `show_google_issue3_replay_route_shortcut_entrypoint.ps1` before you widen all the way back into replay shortcuts or the safe-route map
- runner-state follow-up is already known from the current summary output: reopen `show_google_issue3_runner_patch_next_step.ps1` with the reported state before you widen back into the broader wrapper notes
- saved summary or repo-root override already present: reopen the bridge with that same context first, then choose the next narrower helper
- explicit bundle paths already pinned: keep `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`, `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`, and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` nearby before you stay on the bundle-first helper

Only reopen the longer validation-chain notes after the route has narrowed as far as it can go through the attached-page ladder.
