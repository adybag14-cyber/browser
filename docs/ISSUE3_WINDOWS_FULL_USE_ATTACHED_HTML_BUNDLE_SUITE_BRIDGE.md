# Issue #3 Windows Full-Use Attached HTML Bundle-Suite Bridge

Use this note when `docs/WINDOWS_FULL_USE.md` already made attached localhost follow-up the next obvious issue `#3` branch and the current replay is likely to stay on the known three-page attached HTML compatibility bundle.

The goal here is to keep the broader Windows-first route visible long enough to confirm that the replay really should stay pinned to the bundle, then hand off into the compact bundle-suite surface before the narrower bundle-first helper and delegated runner take over.

Start from the broader Windows-first helper when you want the route printed directly from that context:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
```

If the replay already carries a non-default checkout, a saved summary, or explicit bundle inputs, preserve that same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the Windows full-use attached-page lane, rerun the route-level fail-fast checker first, keep the Windows-to-validation-router bridge, the Windows-side attached-html catalog quickstart, and the replay-side attached-html quickstart visible long enough to confirm that the next replay should stay pinned to the current three-page compatibility bundle, then surface the compact bundle-suite helper before the narrower bundle-first helper, bundle flow, and delegated localhost runner take over.

## Default read-first route

Use this sequence when the next replay is already close to the known three-page compatibility bundle and you want the compact bundle-suite handoff printed before execution:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the broader Windows-full-use route is still the right starting point
- the current replay is already likely to stay on the pinned three-page bundle
- you want the compact bundle-suite surface visible before the narrower bundle-first bridge takes over
- the next useful decision depends on the pinned bundle replay outcome rather than on reopening the broader safe-route stack

## Keep the broader attached-page flows nearby

If the current replay still needs the broader attached-page or Google-shaped attached-page fallbacks visible before the bundle decision locks in, reopen these sidecars before the compact bundle-suite helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

Use that route when the bundle-first lane is likely but you still want the broader attached-page recovery path visible beside it before the replay narrows fully.

## Preserve replay context

If a non-default repo root, a saved summary, or explicit bundle paths are already in play, keep that same context attached to the narrower helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

- `show_google_issue3_windows_full_use_attached_html_route.ps1`: use when the broader Windows-first route still needs to stay visible before bundle-only replay.
- `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`: use when the Windows-first route should keep the validation-router handoff visible before the bundle lane narrows further.
- `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`: use when the Windows-side catalog step should stay visible before the replay-side attached-page ladder and the compact bundle-suite handoff.
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1`: use when the broader Windows-first route has already narrowed to the replay-side attached-page ladder and you want that replay context visible before the compact bundle-suite handoff.
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`: use when you want the smallest issue `#3` bundle-focused surface before the narrower bundle-first helper or delegated runner takes over.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when the replay should stay pinned to the known three-page compatibility set before widening back into the broader helper chain.
- `show_attached_html_target_bundle_validation_flow.ps1`: use when you want the exact bundle checker and delegated runner printed before execution.
- `run_attached_html_target_bundle_validation.ps1 -Wait`: use when the next useful decision depends on the pinned bundle replay outcome.

## Practical rule

When `docs/WINDOWS_FULL_USE.md` already made attached localhost follow-up the next obvious issue `#3` branch, rerun the route-level surface check first, then keep the Windows full-use route, the Windows-to-validation-router bridge, the Windows-side attached-html catalog quickstart, and the replay-side attached-html quickstart visible before the compact bundle-suite helper. Only after that compact suite-level handoff is in view should the route narrow into `show_google_issue3_attached_bundle_first_entrypoint.ps1`, `show_attached_html_target_bundle_validation_flow.ps1`, and the delegated bundle runner.

If the broader attached-page or Google-shaped attached-page fallbacks still matter, reopen them before the bundle-suite helper so the replay can still step back cleanly without reopening the whole wrapper-heavy safe-route family. Only widen back into the longer validation-chain notes after the pinned bundle route has made the next failure state clear.
