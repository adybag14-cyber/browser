# Issue #3 Suite Router Attached HTML Target-Bundle Surface

Use this note when the current issue `#3` replay is already reopening from `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` and you want the main validation-router surface, the compact bundle-suite helper, the broader attached-page flow helper, and the dedicated Google-shaped attached-page flow helper kept visible together before the route narrows into bundle-only execution.

Keep these nearby when the replay may still widen back into the broader attached-page ladders before it commits to the pinned three-page bundle:

- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`

Keep `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md` especially close when the replay is still arriving from the broader validation router and may need the higher-level issue `#3` helper order reprinted before the bundle branch takes over. Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` close when the current pages are already the known three-page compatibility set and you want the pinned bundle lane explained before you delegate to the bundle runner.

## Goal

Start from the main validation-router `attached-html-target-bundle` change-area output when the pinned three-page compatibility route is already the likely next move, but you still want the broader attached-page suite surfaces and the attached-page flow helpers kept visible beside it.

Use the dedicated bundle-suite helper immediately after that router surface when you want the same branch narrowed into a smaller issue `#3` handoff without losing the broader attached-page and Google-shaped attached-page follow-up ladders.

## Read-first commands

Use this sequence when the replay is already close to the pinned three-page bundle but should still keep the broader attached-page route visible before bundle-only execution:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the current attached pages are still the known three-page compatibility bundle or are very likely to narrow to it next
- you want the main `attached-html-target-bundle` validation-router surface reprinted before the compact bundle helper takes over
- you want the broader attached-page suite surface and the narrower Google-shaped attached-page suite surface kept visible beside the pinned bundle lane
- you want the broader attached-page flow helper and the dedicated Google-shaped attached-page flow helper visible before the replay delegates to the bundle runner

## Re-open the broader suite router first

If the replay is still arriving from the higher-level issue `#3` router and you want that broader helper order reprinted before the bundle branch narrows again, start here:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

Use that route when:

- the replay has not yet committed to the pinned bundle branch
- the higher-level validation-router output still matters more than the narrower bundle-first helper
- you want the `google-input`, `attached-html`, `google-attached-html`, and `attached-html-target-bundle` router surfaces visible in one truthful order before bundle-only execution begins

## Top-level and replay-side re-entry

If the replay is already reopening from the top-level attached-page bridge or from the replay-route bundle bridge, keep those companion notes visible long enough to hand off into the bundle-suite surface before the bundle-first helper takes over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use that route when:

- the replay already narrowed through the broader top-level or replay-side helper family
- you want the dedicated bundle-suite surface visible before the route collapses into the narrower bundle-first helper
- explicit bundle inputs may already be pinned and should stay attached while the replay chooses whether to stay on the bundle lane or widen back into the broader attached-page flow helpers

## Preserve replay context

If the replay already carries a non-default checkout, a saved summary, or explicit attached-page inputs, keep that same context attached to the router surface and the narrower helpers:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -ChangeArea 'attached-html-target-bundle'"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` already points at a non-default checkout
- `SummaryPath` already captures the current replay outputs
- explicit `InputPath` values should stay pinned through the router surface, the compact bundle-suite helper, the bundle-first helper, the replay-route bridge, and the delegated bundle runner without falling back to auto-discovery

## Practical rule

Prefer the main `attached-html-target-bundle` validation-router surface first when the replay is still choosing between the broader attached-page ladders and the pinned three-page bundle. Prefer the dedicated bundle-suite helper immediately after that when the route is already close enough to bundle-only validation that you want the smallest issue `#3` handoff which still keeps the broader attached-page and Google-shaped attached-page follow-up helpers visible.

If the replay is still broadly entering issue `#3`, reopen `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md` before this note so the higher-level helper order stays visible. If the replay is already committed to the known three-page compatibility set, reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` or `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` next so the pinned bundle lane stays easy to re-run once the router surface makes the next failure state clear.
