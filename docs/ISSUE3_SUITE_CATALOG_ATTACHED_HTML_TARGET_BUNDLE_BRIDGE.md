# Issue #3 Suite-Catalog Attached HTML Target-Bundle Bridge

Use this note when the next issue `#3` replay is still being chosen from `show_headed_validation_suites.ps1` and the attached three-page compatibility bundle is already the likely next branch.

This note keeps the suite-catalog route, the broader attached-page follow-up helpers, the compact bundle-suite surface, the replay-route bridge, and the narrower bundle-first helper visible together before the route drops into the delegated bundle runner.

Keep these companion notes nearby:
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the suite catalog, confirm that the replay really should stay on the attached-page lane, keep the broader attached-page and Google-shaped attached-page flows visible long enough to confirm that the current run should stay pinned to the three-page compatibility bundle, then narrow into the compact bundle-suite surface, the narrower bundle-first helper, the pinned bundle flow helper, and the delegated localhost runner.

## Read-first route

Use this route when the current replay is still starting from the higher-level validation catalog:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:
- the replay is still being chosen from `show_headed_validation_suites.ps1`
- the three-page compatibility bundle is already the likely next attached-page branch
- you want the broader attached-page flow helper and the dedicated Google attached-page flow helper visible beside the compact bundle-suite helper before the route narrows into the delegated bundle runner

## Preserve replay context

If the replay already carries a non-default checkout, a saved summary path, or explicit bundle paths, keep that same context attached while the route narrows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

Use that form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`: use when the suite catalog should stay visible while the route narrows.
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`: use when you want the compact bundle-suite surface reprinted beside the broader attached-page fallbacks.
- `show_attached_html_validation_flow.ps1`: use when the broader attached-page localhost route still matters before the bundle branch locks in.
- `show_google_attached_html_validation_flow.ps1`: use when the current attached inputs are already Google-shaped and you still want that narrower flow visible before bundle-first replay.
- `show_google_issue3_replay_route.ps1`: use when the next replay should stay close to the current issue `#3` helper ladder before the route narrows further.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`: use when the replay should stay pinned to the known three-page bundle before reopening the broader helper chain.
- `show_attached_html_target_bundle_validation_flow.ps1`: use when you want the exact bundle checker and delegated runner printed before execution.
- `run_attached_html_target_bundle_validation.ps1 -Wait`: use when the next useful decision depends on the pinned bundle replay outcome rather than another broader wrapper pass.

## Practical rule

If the replay is still starting from the suite catalog, prefer reopening the attached-page and bundle-specific catalog surfaces first so the broader attached-page helpers stay visible beside the compact bundle-suite surface. Only jump straight to the bundle-first helper when the current replay is already clearly pinned to the known three-page compatibility set and the broader catalog route no longer adds useful context.