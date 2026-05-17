# Issue #3 Suite-Router Handoff Replay-Route Bundle Bridge

Use this note when issue `#3` replay is re-entering from the suite-router handoff and the next run should keep the replay-route shortcut and the pinned three-page attached HTML bundle on one compact branch before widening back into the broader safe-route helpers.

This note pairs with:

- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`

If you want the suite-router handoff first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

If the replay already carries a non-default checkout, a saved summary, or explicit bundle inputs, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Goal

Start from the suite-router handoff, keep the replay-route shortcut visible, then narrow into the compact attached-html target-bundle suite surface, the replay-route bundle-first bridge, the bundle-aware flow helper, the shorter bundle-first helper, and the delegated localhost runner without losing the pinned three-page compatibility context.

## Default read-first route

Use this sequence when the suite router already made issue `#3` obvious and the next likely branch is the pinned attached-page bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when you want the suite-router handoff, the replay-route helper, the replay-route shortcut, the compact bundle-suite helper, the fail-fast pinned-bundle surface checker, the bundle-aware flow helper, the shorter bundle-first helper, and the delegated runner kept on one smaller branch.

## Router-first re-entry

If the replay has not narrowed all the way to the suite-router handoff yet, reopen the broader attached-page router surfaces first so the bundle branch stays easy to rediscover:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use that route when the broader validation catalog is still choosing the next branch and you want the suite-router handoff plus the pinned bundle route visible together before the delegated bundle runner takes over.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or explicit bundle paths, keep that same context attached to the narrower bundle-first follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

- `show_google_issue3_replay_route.ps1`: use when you still want the broader replay-route helper printed between the suite-router handoff and the shorter replay-route shortcut.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use when the replay-route family is already open and you want the shortest bridge into the pinned bundle lane.
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`: use when you want the compact bundle-suite helper reprinted before the surface checker, bundle-aware flow, and bundle-first helper.
- `check_attached_html_target_bundle_validation_surface.ps1`: use when the pinned three-page route should fail fast before the bundle runner takes over.
- `show_attached_html_target_bundle_validation_flow.ps1`: use when you want the printed bundle-aware helper ladder kept visible before execution.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when the replay should stay on the pinned three-page compatibility set before widening back into the broader issue `#3` path.
- `run_attached_html_target_bundle_validation.ps1 -Wait`: use when the next useful decision depends on the pinned bundle replay outcome, not on a wider wrapper pass.

## Practical rule

Once the suite router already made issue `#3` obvious, prefer the suite-router handoff, then the replay-route shortcut, then the compact bundle-suite helper, then the pinned-bundle surface checker, then the bundle-aware flow helper, and then the shorter bundle-first helper before reopening the longer validation-chain or safe-route notes.

- broader router context still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` and `-ChangeArea attached-html-target-bundle` before the suite-router handoff so the wider catalog and the pinned bundle branch stay aligned
- replay-route already open: keep `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` and `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` nearby so the shorter replay-route bridge and the bundle-first bridge stay on the same route
- explicit bundle paths already pinned: keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` nearby and leave `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`, `check_attached_html_target_bundle_validation_surface.ps1`, `show_attached_html_target_bundle_validation_flow.ps1`, and `show_google_issue3_attached_bundle_first_entrypoint.ps1` in front of the delegated runner so the known three-page compatibility set stays fixed

Only reopen the longer validation-chain or wrapper-heavy safe-route notes after the pinned bundle branch has clarified whether the next replay should stay on the same saved-page set.