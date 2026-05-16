# Issue #3 Windows Replay Attached HTML Bundle-First Bridge

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` or `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` already narrowed the next replay to the attached localhost HTML lane and the current run should stay pinned to the known three-page compatibility bundle before widening back into the broader issue `#3` safe-route helpers.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the replay-side attached-page ladder, rerun the replay quickstart surface check first, keep the broader attached-page localhost flow and the dedicated Google-shaped attached-page flow visible long enough to confirm that the replay should stay on the pinned three-page bundle, then narrow into the compact bundle-suite surface, the replay-route shortcut, the bundle-first helper, the pinned bundle flow helper, the delegated localhost runner, and the fixed-list screenshot-and-title proof path without reopening the broader wrapper-heavy issue `#3` route too early.

## Default read-first route

Use this route when the replay is already near the attached localhost branch and the next likely branch is the pinned three-page compatibility bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'
```

Use that route when:
- the replay is already centered on the attached localhost compatibility pages
- you want the replay-side surface check, the broader attached-page localhost flow, the dedicated Google-shaped attached-page flow, the replay-route helper family, the compact bundle-suite surface, the bundle-first helper, and the delegated bundle runner kept on one compact path
- you want the three headed validation suite change areas kept visible long enough to confirm that the replay should stay pinned to the bundle before the route narrows further

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or explicit bundle inputs, keep that same context attached to the narrower bundle-first follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -RepoRoot '<repo-root>' -FixturePaths '<bundle-html-or-folder>'
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

- `show_google_issue3_windows_replay_attached_html_quickstart.ps1`: use when the replay is already narrowed to the attached localhost lane and you want the replay-side ladder reprinted before bundle narrowing.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`: use when you want the compact suite-level bundle branch surfaced directly from the broader validation router before the replay-route family takes over.
- `show_attached_html_validation_flow.ps1`: use when the broader attached-page localhost flow still needs to stay visible before the bundle decision.
- `show_google_attached_html_validation_flow.ps1`: use when the current attached inputs are already Google-shaped and you still want that narrower guide visible before the pinned bundle branch.
- `show_google_issue3_replay_route.ps1`: use when you want the fuller replay-route helper family printed before the route narrows again.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use when the replay-route helper is already open and you want the shortest bridge before the compact bundle-suite surface and bundle-first helper.
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`: use when you want the compact bundle-suite surface reprinted before the bundle-first helper so the pinned bundle lane stays visible beside the broader attached-page fallbacks.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when the replay should stay on the pinned three-page compatibility set before reopening the broader helper chain.
- `show_attached_html_target_bundle_validation_flow.ps1`: use when you want the exact bundle checker and delegated runner printed before execution.
- `run_attached_html_target_bundle_validation.ps1 -Wait`: use when the next useful decision depends on the pinned bundle replay outcome, not on a wider wrapper pass.
- `chrome-local-html-fixture-probe.ps1`: use after the bundle route is green when you want tighter screenshot-and-title proof for the same pinned inputs.

## Practical rule

Only jump straight to the bundle-first helper when the replay-side attached-html ladder has already made the pinned three-page compatibility bundle the next obvious branch.

- replay reopened from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`: rerun the replay-side surface check first, then reopen the replay-side attached-html quickstart, the attached bundle suite surface, the replay-route shortcut, and the bundle-first helper before the delegated runner takes over
- broader attached-page context still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html`, `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`, `show_attached_html_validation_flow.ps1`, and `show_google_attached_html_validation_flow.ps1` before the replay-route shortcut and the compact bundle-suite surface so the broader fallbacks stay visible
- explicit bundle paths already pinned: reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`, `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`, and `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` before `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` and the bundle-first helper so the exact three-page compatibility set stays visible while the replay stays locked to the bundle flow
- after the bundle runner finishes: prefer the fixed-list local fixture proof when you want tighter screenshot-and-title evidence for the same pinned inputs, and only widen back into the broader safe-route helpers after the bundle route makes the next failure state clear

Only reopen the longer validation-chain or wrapper-heavy safe-route notes after the pinned bundle route has clarified whether the next replay should stay on the same saved-page set.
