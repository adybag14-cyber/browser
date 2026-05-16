# Issue #3 Windows Validation Chain

This note captures the current bounded replay path for issue `#3` on `fork/headed-mode-foundation`.

Use it when the Windows headed validation lane needs to resume without rediscovering which helper should run next.

## Read-first discovery

When you want to re-enter issue `#3` from the top-level headed validation catalog before choosing a narrower wrapper, start with:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1
```

If you want the broader Google route, the attached three-page bundle branch, and the current safe-route shortcuts printed together in one helper before you decide which way to continue, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use `-SuiteName google-recommended` when you want the one-command localhost-first runner plus its nearby helper surfaced quickly.

Use `-ChangeArea google-input` when the next replay may need one of the narrower title, homepage-fixture, submit-path, submit-timing, shared Enter-order, attached-page, or live-trace slices instead of the broader recommended runner.

Use `show_google_input_validation_flow.ps1` when you want the bounded localhost, title, homepage-fixture, submit-path, submit-timing, shared Enter-order, attached-page, and safe-route patch-handoff order printed before deciding whether the next replay should stay broad or drop to a narrower helper.

Use `show_google_issue3_replay_shortcuts.ps1` when you want the broader Google route, the attached three-page bundle branch, and the return-to-safe-route helpers printed on one stable command surface before you commit to the next replay path.

Use `-ChangeArea attached-html` when attached localhost compatibility follow-up is already the next obvious branch and you want the route-level surface check, the broader Windows-full-use route, the Windows full-use validation-router bridge, the Windows full-use attached-html catalog quickstart, the replay-side attached-html quickstart, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, the broader suite-catalog guide, the suite-catalog attached-page bridge, the Google-shaped attached-page flow, the top-level shortcut bridge, and the replay-route shortcut surfaced before the wrapper-heavy safe-route notes narrow the replay again.

When the current saved or attached inputs are the known three-page compatibility bundle, also open the attached bundle route directly from the higher-level router before widening into the wrapper-heavy Google-only helpers, and keep the bundle-first helper, fail-fast surface checks, pinned manual checklist, and reusable fixed-list proof path visible on the same locked inputs:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'
```

After that read-first discovery pass, prefer the safe-route wrapper entrypoints below when the work is specifically resuming the saved runner-output handoff chain.

## Top-level attached-page route

When the replay is already narrowed to the attached localhost HTML branch and you want the route-level surface check, the broader Windows-full-use and replay-side attached-page chain, and the narrower top-level attached-page chain kept visible before the route collapses back to the shorter shortcut helpers, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context on the broader Windows-full-use, replay-side attached-page, validation-router, and top-level attached-page helpers first:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these nearby when you want the written route beside the helper output:
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` when the broader validation router already narrowed the replay toward the attached localhost branch
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md` when the shorter top-level shortcut ladder should stay visible before the replay narrows again
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` when the replay started from `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md` when the broader Windows runbook-side validation-router bridge should stay visible before the top-level chain narrows again
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md` when the broader Windows runbook-side attached-page catalog route should stay visible before the top-level chain narrows again
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` when the replay-side route needs the broader Windows replay ladder kept visible beside the narrower top-level attached-page chain
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` when the replay-side attached-page quickstart should stay visible before the route narrows into the compact top-level helpers
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md` when the broader suite-catalog guide should stay visible beside the replay-side and top-level attached-page ladders
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` when the suite-catalog-side attached-page bridge should stay visible before replay shortcuts or safe-route helpers
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` when the current attached-page follow-up is already Google-shaped and should stay visible before the helper chain narrows again
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`, `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`, and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md` when the current attached inputs are already the known three-page compatibility bundle and you want the bundle-first helper, pinned checklist, and reusable proof path kept visible before the route widens back into the issue `#3` safe helpers
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` when the replay-route shortcut companion surface should stay visible before the route collapses into the shorter attached-page helper chain
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` when the route is ready to narrow back toward the suite-router side

Use the replay-side attached-html quickstart first when the broader Windows full-use route still needs to stay visible beside the narrower top-level chain.

Use the compact top-level quickstart first when no bundle inputs, saved summary, or non-default repo root need to take precedence after that broader Windows-side route is already in view.

Use the broader top-level attached-page entrypoint next when you want the top-level bridge, suite-router attached-page quickstart, attached-page shortcut, replay shortcuts, next-step matrix, and safe-route map reopened from one place before deciding how far to narrow.

Use the suite-catalog guide when you want the broader suite-catalog route map reprinted before the replay narrows back through the attached-page bridge.

Use the suite-catalog attached-page bridge when you want the suite-catalog-side attached-page route kept visible beside the replay-side and top-level ladders without reopening the full validation catalog first.

Use the Google attached-page flow when the current attached inputs are already Google-shaped and you want that narrower route kept visible before the helper chain drops back into the shorter attached-page and replay-route shortcuts.

Use the top-level shortcut-first helper when the broader top-level bridge is already visible but the route should keep the shorter top-level shortcut surface open before dropping into the attached-page shortcut, replay shortcuts, or the replay-route shortcut bridge.

Use the replay-route shortcut helper when the replay is already inside the narrower issue `#3` helper chain and you want the replay-route companion surface reopened before widening back into replay shortcuts, the next-step matrix, or the safe-route map.

When the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, reopen the broader Windows runbook route, its validation-router bridge, the Windows-side attached-html catalog quickstart, and the replay-side attached-html quickstart before the validation-router attached-page quickstart and the top-level attached-page chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

Use that broader Windows-first route when you want the Windows full-use entrypoint, its newer validation-router bridge, the Windows-side attached-html catalog step, the replay-side attached-html quickstart, the validation-router attached-page quickstart, the top-level attached-page helpers, the broader suite-catalog guide, the suite-catalog attached-page bridge, the Google-shaped attached-page flow, the top-level shortcut bridge, and the replay-route shortcut to describe the same attached-page re-entry order before the route narrows back toward replay shortcuts or the wrapper-heavy safe path.

Return to the broader validation chain only after the attached-page route has clarified the next replay state again.

## Context-preserving lane handoffs

Once the current replay already has a chosen checkout, browser binary, host, and input text, move from the generic suite catalog to the narrower flow helpers that preserve that context in their printed follow-up commands.

Use these lane-specific helpers directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -InputText '<input-text>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -SharedInputText '<input-text>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_trace_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -InputText '<input-text>' -LeaveOpen
```

Use the submit-timing helper first when the bounded keydown, keypress, and submit-ordering path still needs confirmation on the current checkout.

Use the shared Enter-order helper next when the reduced-home and shared form-controls gates need to stay on the same host and input text before another live replay.

Use the live-trace helper last when the bounded localhost and shared gates are already green and you want the reduced-home or live Google capture to keep the same replay context instead of reconstructing it by hand.

## Attached three-page bundle route

Use the attached bundle route before the wrapper-heavy issue `#3` safe route when the current work item is still the pinned three-page compatibility bundle and you want the bundle-first helper, fail-fast surface checks, pinned manual checklist, and reusable fixed-list proof path kept on the same locked inputs.

Why this route comes first in that case:
- it keeps the bundle-first helper, surface check, checker, flow helper, delegated localhost runner, pinned manual checklist, and reusable fixed-list proof path pinned to the same locked input set
- it avoids widening back into the broader Google-only wrapper chain before the current bundle replay has clarified the next failure state
- it gives the next Windows replay one stable route for the attached compatibility targets before returning to the narrower safe-route entrypoints

Use these commands in order:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'
```

Return to `show_google_issue3_safe_route_entrypoints.ps1` only after the bundle replay or the reusable fixed-list proof path makes the next runner-output, handoff, or Google-style input state clear again. When that return still needs the same pinned bundle path, reopen `show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'` or `show_google_issue3_replay_shortcuts.ps1 -InputPath '<bundle-html-or-folder>'` first, or pass the same `-InputPath` into the safe-route entrypoints helper so the next wrapper stays on the locked bundle instead of falling back to auto-discovery.

## One-command safe-route entrypoints map

When the replay is already narrowing into the wrapper-heavy issue `#3` handoff chain and you want the current safe-route entrypoints in one place before choosing the next narrower helper, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

When the replay is still pinned to the known attached three-page bundle, prefer reopening `show_google_issue3_replay_shortcuts.ps1 -InputPath '<bundle-html-or-folder>'` first. That helper now carries the same pinned bundle path into `show_google_issue3_safe_route_entrypoints.ps1`, so the safe-route entrypoint map stays on the locked input set instead of widening back out to auto-discovery.

Use this helper when you want the current:
- fresh replay command
- reuse-current-outputs command
- refresh-status safe-path route
- handoff-safe helper
- summary-guide safe helper
- runner-wiring safe helper
- runner-patch next-step helper for `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`

## Goal

Keep the next Windows replay on the newest strict-mode-safe wrapper first, preserve the current runner-patch guidance in the saved artifacts, and only reopen the stricter raw helper after the corresponding safe checkpoint reports that the saved state is ready.

## Preferred entrypoints

Use the smallest wrapper that matches the current state instead of starting from a raw helper by default.

1. Fresh replay plus final safe-route patch handoff
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```
Use this as the default fresh Windows replay entrypoint when the current issue `#3` outputs may be stale or missing and you want one command that:
- reruns the recommended validation flow
- preserves the final runner patch handoff artifact
- keeps the follow-up split between `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`

2. Top-level route plus preserved runner-patch guidance
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```
Use this when the current saved outputs are already present and you want to reopen the strict-mode-safe validation route plus preserved runner-output patch guidance without another broader replay first.

3. Summary-contract recovery plus safe-route reopen
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_summary_contract_safe_route.ps1
```
Use this when older or partially repaired saved outputs still need summary-contract cleanup before the safe route should be trusted again.

4. Fresh replay plus runner-output contract repair
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1
```
Use this when the next replay should regenerate the current outputs, normalize the runner-output contract, and immediately confirm whether the raw wiring audit is ready.

5. Fresh replay plus runner-output patch-target guidance
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
```
Use this when the next replay is likely to end in a direct runner-side patch and you want one artifact that preserves the exact patch-target lines.

6. Fresh replay plus runner-output wiring safe-route reopen
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
```
Use this when the next replay should regenerate or repair the runner-output contract and only reopen the raw wiring audit after the safe wrapper says the saved summary is ready.

## Raw runner

The underlying runner is still:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1
```

Use it directly when you intentionally want a broader regeneration pass. In normal issue `#3` replay loops, prefer one of the wrappers above so the next-step guidance stays on the current safe route.

Notes:
- The runner writes the saved summary, manifest, bundle, handoff, and refresh artifact paths into `tmp-browser-smoke\\headed-probe`.
- When Google-style attached HTML fixtures are present in the configured search roots, the runner auto-detects them and keeps the manual follow-up on that local fixture set.

## Safe-first checkpoints

Use these helpers before reopening narrower raw audits:

1. Summary and artifact health
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_summary_guide_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_artifact_bundle_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_artifact_bundle_safe_path_route.ps1
```

2. Manifest, refresh, and handoff routing
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_manifest_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_refresh_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_refresh_status_safe_path_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_handoff_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_handoff_safe_refresh_route.ps1
```

3. Runner-output contract and wiring
```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## When to reopen raw helpers

Only trust the stricter raw helper after its safe wrapper says the state is ready:

- `show_google_issue3_validation_manifest.ps1` after `show_google_issue3_validation_manifest_safe.ps1` reports `safe-to-run-manifest-guide`.
- `show_google_issue3_validation_refresh_status.ps1` after `show_google_issue3_validation_refresh_status_safe.ps1` reports `safe-to-run-existing-helper`.
- `show_google_issue3_validation_handoff.ps1` after `show_google_issue3_validation_handoff_safe.ps1` reports `safe-to-run-handoff`, or after the handoff safe refresh route reports `ready-for-handoff`.
- `show_google_issue3_validation_artifact_bundle.ps1` after `show_google_issue3_validation_artifact_bundle_safe.ps1` reports `safe-to-run-existing-helper`, or after the bundle safe path route reports `ready-for-bundle-follow-up`.
- `show_google_issue3_runner_output_wiring_status.ps1` after `run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1` reports `runner-output-fully-wired`, or after the runner-output safe chain reports `ready-for-runner-output-wiring` and you intentionally want the raw helper by itself.
- `show_google_issue3_runner_output_patch_handoff.ps1` after `show_google_issue3_runner_output_patch_targets_safe_route.ps1` or `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` reports `ready-for-runner-patch`.
- `show_google_issue3_runner_output_patch_targets.ps1` only after `show_google_issue3_runner_output_patch_targets_safe.ps1` or `show_google_issue3_runner_output_patch_targets_safe_route.ps1` reports that the raw patch-target helper itself is still the next safe checkpoint.
- `show_google_issue3_runner_output_wiring_status_safe.ps1` directly when the safe-route patch-target or safe-route patch-handoff chain reports `already-direct`, instead of reopening another runner patch step first.

## If the runner-output contract still needs a patch

Stay on the wrapper and safe-route chain instead of starting from the raw patch-target helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_patch_targets_safe_route.ps1
```

When current outputs may be stale or missing, prefer the fresh replay handoff wrapper first. Use the show-only safe-route wrapper when you already trust the current saved outputs and only need to reopen the narrower guidance chain.

If the safe route still says the raw patch-target helper is the next safe checkpoint, let that helper be reopened through the safe-route wrapper instead of launching it by hand first.

If the safe-route patch-handoff wrapper reports `already-direct`, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
```

and skip the direct runner patch loop for that replay.

## When the runner source is already wired

If `show_google_issue3_runner_output_wiring_status.ps1` reports `saved-artifacts-stale-runner-already-wired`, do not patch `scripts/windows/run_google_issue3_recommended_validation.ps1` again as the first move.

Treat that status as a saved-output recovery problem instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1
```

If you need the narrower repair step without reopening the wider safe route yet, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\repair_google_issue3_runner_output_contract.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
```

If you want one combined replay that repairs the runner-output contract and only reopens the raw wiring audit when the safe gate says the summary is ready, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
```

If `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` reports `already-direct`, go straight to the safe wiring audit. If it reports `runner-already-wired-regenerate-outputs`, follow its emitted regeneration or repair command before reopening the safe wiring audit.

Only come back to the raw runner-output wiring audit after the safe wiring helper routes there again. The goal is to regenerate or normalize the saved summary and manifest before spending another replay on a direct runner patch that is already present in source.

Patch target:
- `scripts/windows/run_google_issue3_recommended_validation.ps1`

When the top-level wrapper reports `ready-for-runner-patch`, open its combined artifact first:
- `tmp-browser-smoke\\headed-probe\\google-issue3-validation-safe-route-runner-patch-wrapper.json`

When the runner-output repair plus patch-target wrapper is the entrypoint, its combined artifact is:
- `tmp-browser-smoke\\headed-probe\\google-issue3-recommended-validation-repair-runner-output-patch-targets.json`

When the safe-route patch-handoff wrapper is the entrypoint, its combined artifact is:
- `tmp-browser-smoke\\headed-probe\\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json`

When the patch handoff helper is the entrypoint, its artifact is:
- `tmp-browser-smoke\\headed-probe\\google-issue3-runner-output-patch-handoff.json`

Use the preserved summary and manifest snippet lines from the newest wrapper or patch-handoff artifact before reopening lower-level helpers by hand.

Verify after any runner-output patch:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status.ps1
```

Use the combined safe-route wrapper first when you want the repair flow and reopened raw audit state preserved in one artifact. Keep the standalone safe and raw wiring commands for narrower follow-ups when the current outputs are already trustworthy.

## Direct Runner Patch Checklist

When the runner still needs a direct contract fix, patch both saved output objects inside `scripts/windows/run_google_issue3_recommended_validation.ps1`, not just one of them.

Keep `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` open beside this checklist during the source edit. Use that focused note as the source of truth for artifact order, nullable `$null` handling, blank-path handling, and post-patch verification; use this section to keep the replay loop on the current safe-route wrappers.

Required direct fields in both the summary artifact and the manifest artifact:
- `refresh_chain_artifact_path`
- `refresh_chain_artifact_error`
- `handoff_artifact_path`
- `handoff_artifact_error`

Patch rules:
- Use the values emitted by `show_google_issue3_runner_output_patch_targets_safe_route.ps1`, `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`, or `show_google_issue3_runner_output_patch_handoff.ps1` instead of inventing paths.
- Keep the error fields present even when the value is empty or `$null`; the newer audits distinguish between a missing field and a recorded empty value.
- Recheck both object writers after editing. The helper-chain audits treat the summary and manifest as separate contracts.
- If the raw wiring audit reports `saved-artifacts-stale-runner-already-wired`, stop the direct patch loop and move back to output regeneration or repair instead of reapplying the same source edit.
- If the safe-route patch-handoff wrapper reports `already-direct`, skip the source patch and move straight to the safe wiring audit.

Recommended patch loop:
1. Run `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`.
2. If the wrapper reports `ready-for-runner-patch`, open the newest safe-route patch-handoff artifact and copy the suggested field lines for both saved output objects in `scripts/windows/run_google_issue3_recommended_validation.ps1`.
3. If the wrapper reports `already-direct`, skip the runner patch and reopen `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1`.
4. If the wrapper reports `runner-already-wired-regenerate-outputs`, follow its emitted regeneration or repair command before reopening the safe wiring audit.
5. Otherwise, if you are intentionally reusing current saved outputs, run `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1` or `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_patch_targets_safe_route.ps1`.
6. Rerun `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1`.
7. Prefer `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1` so the safe contract wrapper reruns first and the raw audit only reopens when the saved summary is ready.
8. If you intentionally need the narrower checks by themselves, verify with `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1`, then confirm with `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status.ps1`.
9. Prefer `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_refresh_status_safe_path_route.ps1` so the safe checkpoint reopens the raw refresh-status helper for you and carries the replay straight into the next handoff-safe step when the refresh chain is ready.
10. If you intentionally need the narrower raw helper by itself, continue into `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_refresh_status.ps1` only after the safe checkpoint reports `safe-to-run-existing-helper`.

## Practical rule

If two helpers disagree:
- prefer the wrapper over the raw command when a wrapper already exists for that checkpoint
- prefer `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` as the default fresh replay entrypoint; use `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1` when reusing current saved outputs is intentional
- if a `safe_path_route` wrapper already exists for the current checkpoint, prefer it when you want the safe helper and its bounded raw follow-up reopened in one step
- if the current saved or attached inputs are already the known three-page compatibility bundle, prefer `show_google_issue3_attached_bundle_first_entrypoint.ps1`, `check_attached_html_target_bundle_validation_surface.ps1`, `check_attached_html_target_bundle.ps1`, `show_attached_html_target_bundle_validation_flow.ps1`, `run_attached_html_target_bundle_validation.ps1 -Wait`, `check_local_html_fixture_validation_surface.ps1`, and `tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'` before widening back into the wrapper-heavy safe-route helpers
- if attached localhost follow-up is already obvious from `show_headed_validation_suites.ps1 -ChangeArea attached-html` or from `docs/WINDOWS_FULL_USE.md`, reopen `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`, `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`, `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, `show_google_issue3_windows_replay_attached_html_quickstart.ps1`, `show_google_issue3_validation_router_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`, `show_google_issue3_suite_catalog_entrypoints.ps1`, `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`, `show_google_attached_html_validation_flow.ps1`, `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, and `show_google_issue3_replay_route_shortcut_entrypoint.ps1` before dropping into the compact top-level attached-page bridge, the attached-page shortcut, or the broader safe-route notes
- otherwise prefer the helper with `safe` in the name unless the safe helper explicitly says the raw helper is ready
- if the raw wiring audit says `saved-artifacts-stale-runner-already-wired`, prefer saved-output regeneration or repair over another direct runner patch
- if the safe-route patch-handoff wrapper says `already-direct`, go straight to the safe wiring audit
- if the safe-route patch-handoff wrapper says `runner-already-wired-regenerate-outputs`, regenerate or repair the saved outputs before another direct runner patch attempt
