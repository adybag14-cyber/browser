# Issue #3 Validation-Router Attached HTML Target-Bundle Bridge

Use this note when issue `#3` replay is re-entering from the broader headed validation router and the next run should stay pinned to the known three-page attached HTML compatibility bundle before widening back into the broader helper chain.

Keep these companion notes nearby:

- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`

## Goal

Start from the broader validation-router surfaces, rerun the validation-router attached-html guard, keep both the broader attached-page localhost flow and the narrower Google-shaped attached-page flow visible long enough to confirm that the replay should stay on the pinned three-page bundle, then hand off directly into the bundle-first helper, the bundle surface checks, the bundle flow helper, and the delegated localhost runner.

## Default read-first route

Use this route when the next replay is already leaning toward the known three-page compatibility set and no non-default repo root, saved summary, or explicit bundle override needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the broader validation router already made attached localhost follow-up obvious
- the replay still benefits from seeing both the broader attached-page helper and the dedicated Google-shaped attached-page helper before the route locks onto pinned bundle inputs
- the next useful branch should stay on the known three-page compatibility set instead of widening back into replay shortcuts or the wrapper-heavy safe route

## Windows-first re-entry

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first route kept aligned before the bundle-first handoff, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
```

Use that route when the broader Windows full-use runbook already made attached localhost follow-up the next obvious branch and you want the route-level surface check, the Windows-to-validation-router bridge, the broader attached-page flow helper, the narrower Google-shaped attached-page flow helper, and the bundle-first handoff visible together before the delegated bundle runner takes over.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the validation-router quickstart and the narrower bundle-first handoff:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through the narrower helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when the broader validation router is still the right starting point and you want the shortest bridge before bundle-only helpers take over.

2. `show_attached_html_validation_flow.ps1`

Use this when the broader attached-page localhost flow still needs to stay visible before the bundle decision.

3. `show_google_attached_html_validation_flow.ps1`

Use this when the current attached inputs already include a Google-like page and you want the narrower Google-shaped helper lane visible before the bundle-first handoff.

4. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when the replay should stay on the pinned three-page compatibility set before widening back into the broader helper chain.

5. `show_attached_html_target_bundle_validation_flow.ps1`

Use this when you want the exact bundle checks, helper, and delegated localhost runner printed before execution.

6. `run_attached_html_target_bundle_validation.ps1 -Wait`

Use this when the next useful decision depends on the pinned bundle replay outcome, not on a wider wrapper pass.

## Practical rule

Once the broader validation router already made attached localhost follow-up obvious, rerun the validation-router attached-html guard first, then reopen the broader attached-page localhost helper and the narrower Google-shaped attached-page helper before the route locks onto the pinned three-page bundle. Stay on the bundle-first branch until the checker, bundle flow helper, or delegated runner makes the next failure state clear, and only widen back into the broader issue `#3` helper chain after that narrower pinned-bundle route has done its job.
