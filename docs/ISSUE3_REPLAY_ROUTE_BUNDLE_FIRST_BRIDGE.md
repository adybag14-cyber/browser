# Issue #3 Replay-Route Bundle-First Bridge

Use this note when issue `#3` replay is already near `show_google_issue3_replay_route.ps1` and the next run should stay pinned to the known three-page attached HTML compatibility bundle before widening back into the broader safe-route helpers.

Start with the replay-route helper when you still want the current issue `#3` command surface printed before the bundle route narrows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

If the replay already carries a non-default checkout, a saved summary, or explicit bundle inputs, preserve that context directly in the replay-route helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the replay-route helper, keep the broader attached-page localhost flow and the dedicated Google-shaped attached-page flow visible long enough to confirm that the current replay really should stay on the pinned three-page bundle, then narrow into the compact bundle-suite surface, the bundle-first helper, the compact bundle quickstart, the bundle flow helper, the delegated localhost runner, the proof entrypoint, and the fixed-list proof path without reopening the broader wrapper-heavy issue `#3` route too early.

## Default read-first route

Use this sequence when the current replay is already close to the replay-route helper and the next likely branch is the pinned three-page compatibility bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'
```

Use that route when you want the replay-route helper, the narrower replay-route shortcut, the broader attached-page localhost flow, the dedicated Google-shaped attached-page flow, the compact bundle-suite surface, the bundle-first helper, the compact bundle quickstart note, the pinned bundle flow helper, the delegated localhost runner, the proof entrypoint, and the fixed-list screenshot-and-title proof kept on one compact branch.

## Router-first re-entry

If the replay has not narrowed all the way to `show_google_issue3_replay_route.ps1` yet, reopen the broader attached-page router surfaces first so the bundle-first path stays rediscoverable before the route collapses:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
```

Use that route when the broader validation catalog or replay-route family is still choosing the next branch and you want the broader attached-page helper chain, the Google-shaped attached-page helper chain, the compact bundle-suite surface, and the pinned bundle branch visible together before the delegated bundle runner takes over.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or explicit bundle paths, keep that same context attached to the narrower bundle-first follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -RepoRoot '<repo-root>' -FixturePaths '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`: use when the replay-route helper is already open and you want the shortest bridge before bundle-first narrowing.
- `show_attached_html_validation_flow.ps1`: use when the broader attached-page localhost flow still needs to stay visible before the bundle decision.
- `show_google_attached_html_validation_flow.ps1`: use when the current attached inputs are already Google-shaped and you still want that narrower flow guide visible before the bundle branch.
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`: use when you want the compact bundle-suite surface reprinted before the bundle-first helper so the pinned bundle lane stays visible beside the broader attached-page and Google-shaped attached-page fallbacks.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when the replay should stay on the pinned three-page compatibility set before reopening the broader helper chain. Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md` nearby when you want the compact suite-level and quickstart notes beside that helper before the delegated bundle runner takes over.
- `show_attached_html_target_bundle_validation_flow.ps1`: use when you want the exact bundle checker and delegated runner printed before execution.
- `run_attached_html_target_bundle_validation.ps1 -Wait`: use when the next useful decision depends on the pinned bundle replay outcome, not on a wider wrapper pass.
- `show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1`: use immediately after the delegated bundle runner when you want the narrower proof-only handoff printed before the fixed-list fixture surface check and screenshot-and-title probe.
- `chrome-local-html-fixture-probe.ps1`: use after the bundle route is green when you want tighter screenshot-and-title proof for the same pinned inputs.

## Practical rule

Only jump straight to the bundle-first helper when the current replay inputs are already pinned or when the broader attached-page and replay-route surfaces have already made the three-page compatibility bundle the next obvious branch.

- replay-route already open and explicit bundle paths already pinned: go from the replay-route helper to the replay-route shortcut, reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`, then use the compact bundle-suite surface helper, the bundle-first helper, the bundle flow helper, the delegated runner, the proof entrypoint, and the fixed-list proof path
- replay-route already open but broader attached-page context still matters: reopen `show_attached_html_validation_flow.ps1` and `show_google_attached_html_validation_flow.ps1` before the compact bundle-suite surface and bundle-first helper so the broader attached-page recovery path stays visible
- broader validation catalog still choosing the next branch: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html`, `-ChangeArea google-attached-html`, and `-ChangeArea attached-html-target-bundle` before the replay-route shortcut and the compact bundle-suite surface so the broader router and the pinned bundle branch stay aligned
- after the bundle runner finishes: prefer `show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1`, then the fixed-list local fixture proof, when you want tighter screenshot-and-title evidence for the same pinned inputs, and only widen back into the broader safe-route helpers after the bundle route makes the next failure state clear

Only reopen the longer validation-chain or wrapper-heavy safe-route notes after the pinned bundle route has clarified whether the next replay should stay on the same saved-page set.