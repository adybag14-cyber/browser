# Issue #3 Attached HTML Target-Bundle Suite Surface

Use this note when issue `#3` replay is already close to the known three-page attached HTML compatibility bundle and you want the compact suite-level route printed with both the broader attached-page helper flow and the full Google-shaped attached-page validation route still visible beside it.

Keep these nearby when the route may still reopen from a broader validation surface before it locks onto the pinned three-page bundle:

- `docs/HEADED_MODE_ROADMAP.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` especially close when the replay is already pinned to the exact three-page bundle, keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md` close when the broader attached-page route has already made the bundle lane the next likely branch and you want the shortest read-first bridge visible before the route narrows into bundle-first execution, keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` close when one of those pages makes the Google-shaped attached-page route the next likely follow-up, keep `docs/HEADED_MODE_ROADMAP.md` close when the replay is being rediscovered from the higher-level validation catalog first, keep `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` and `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` close when the replay is re-entering from the broader Windows-first ladders, and keep the top-level attached-html notes plus `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` close when the replay is already narrowing from the top-level or replay-route surfaces before it commits to the pinned bundle lane.

## Goal

Start from the dedicated suite-surface helper when the current replay is already near `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` and you want the bundle surface, the broader attached-page suite surfaces, the broader attached-page flow helper, and the full Google-shaped attached-page validation route visible in one compact place before the replay narrows into bundle-only execution.

If the route is still reopening from the suite-catalog side first, keep the suite-catalog guide and the suite-catalog attached-page bridge visible long enough to confirm that the pinned bundle lane is still the right next branch before this narrower suite-surface helper takes over. If the route is already reopening from the top-level attached-html helpers, keep the compact top-level quickstart, the bundle quickstart, and the broader top-level bridge visible long enough to confirm that the replay should stay on the pinned bundle lane before this suite-surface helper takes over.

## Current default next helper

The live helper chooses its immediate next command from replay context:

- No explicit bundle paths are pinned yet: `check_attached_html_target_bundle_validation_surface.ps1`
- Explicit bundle input paths are already pinned: `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Treat that recommendation order as the source of truth for this note. If the note and the helper drift again, refresh the note to the helper output rather than the other way around.

## Read-first commands

Use this compact suite-level route when the attached bundle is the likely next move but you still want the neighboring suite and flow surfaces printed beside it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the current attached pages are still the known three-page compatibility bundle or are very likely to narrow to it next
- you want the `attached-html-target-bundle` change-area output reprinted with the broader attached-page suite surface and the Google-shaped attached-page suite surface still visible beside it
- you want the fail-fast Google attached-page surface and asset-closure checks visible before the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, and the delegated Google-shaped attached-page runner take over
- you want the broader attached-page flow helper plus the full Google-shaped attached-page validation route kept in view before the replay locks onto the delegated bundle validation runner

## Validation-catalog re-entry

If the replay is still being chosen from the main validation catalog and you want the compact bundle-focused suite surface reprinted before the narrower bundle-first helper takes over, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

Use that route when:

- the higher-level validation catalog or roadmap still needs to stay visible before the replay narrows into the pinned bundle lane
- you want the broader attached-page and Google-shaped attached-page routes surfaced beside the compact bundle-focused suite helper rather than rediscovered later
- you want the fail-fast Google attached-page surface and asset-closure checks carried forward before the narrower bundle-first helper takes over
- you want the top-level attached-page bridge, the dedicated suite-surface helper, the bundle-first helper, the replay-route helpers, and the delegated Google-shaped runner aligned with the same broader catalog-first route that the surrounding bundle-reference and roadmap notes already describe

## Suite-catalog re-entry

If the replay is still arriving from the suite-catalog side and you want the bundle-focused suite surface reopened only after the broader attached-page handoff is visible again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use that route when:

- the suite-catalog surface still matters more than the narrower bundle-first route
- you want the suite-catalog guide, the suite-catalog attached-page bridge, and the dedicated bundle suite-surface helper printed in one truthful order before bundle-only execution begins
- the replay may still widen back into the broader attached-page or Google-shaped attached-page ladders if the pinned three-page bundle is no longer the right next branch

## Top-level attached-html re-entry

If the replay is already reopening from the top-level attached-html route and the known three-page compatibility bundle now looks like the most likely next branch, keep the top-level quickstart, the bundle quickstart, and the broader top-level bridge visible long enough to hand off into the bundle-focused suite surface before the narrower bundle-first helper takes over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- the replay already narrowed through the top-level attached-html quickstart or bridge
- you want the bundle quickstart, the compact top-level route, and the broader top-level bridge kept visible beside the dedicated bundle suite surface before the replay collapses into the narrower bundle-first helper
- explicit bundle paths are already pinned and should stay attached to the top-level helper chain while the replay decides whether to stay on the bundle lane or widen back into the broader attached-page flow helpers

## Use the dedicated helper first

Prefer the dedicated suite-surface helper first when you want the smallest issue `#3` command surface that still keeps the bundle lane connected to the broader attached-page follow-up ladders:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

That helper is the best starting point when:

- the replay is already close to bundle-only validation and the broader route context only needs a compact reminder
- you want the `attached-html-target-bundle`, `attached-html`, and `google-attached-html` suite commands kept together beside the broader attached-page flow helper and the full Google-shaped attached-page validation route
- you want the top-level attached-html bridge, bundle surface checker, bundle flow helper, bundle runner, bundle-first entrypoint, replay route, and replay shortcuts printed on one smaller issue `#3` surface before you choose the next replay branch

## Narrower issue #3 re-entry

If explicit bundle paths or replay context are already pinned, keep the narrower issue `#3` helper chain nearby before the delegated bundle runner takes over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the next replay decision still depends on preserving explicit bundle inputs, a saved summary path, or a non-default repo root while the bundle lane remains the most likely next branch.

## Preserve replay context

If the replay already carries a non-default checkout, a saved summary, or pinned bundle inputs, keep that same context attached to the suite-surface helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` already points at a non-default checkout
- `SummaryPath` already captures the current replay outputs
- explicit `InputPath` values should stay pinned through the top-level re-entry, the suite-catalog side re-entry, the dedicated bundle suite surface, the narrower bundle-first helper, and the replay-route helpers without relying on auto-discovery

## Practical rule

Prefer the dedicated suite-surface helper when the replay is already close to the attached bundle lane and only needs a compact re-entry surface before bundle-only validation. Reopen the broader `attached-html` or `google-attached-html` suite surfaces first only when the replay still needs the wider attached-page route visible before it commits to the pinned three-page bundle. When the replay is being rediscovered from the higher-level validation catalog, reopen that catalog context first, then use this note and the dedicated suite-surface helper to keep the bundle lane aligned with the broader catalog-first guidance before narrowing into the bundle-first helper.

If the replay has already made the bundle lane the next obvious branch, reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md` beside this note before narrowing into the bundle-first helper so the shorter read-first bridge stays visible.

If the replay is still arriving from the suite-catalog side, reopen `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`, then `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`, then `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` before narrowing into the bundle-first helper.

If the replay is already arriving from the top-level attached-html route, reopen `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`, then `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`, then `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` before narrowing into the bundle-first helper.

Once the bundle runner or the broader attached-page helpers make the next failure state clear, widen back into the broader issue `#3` helper chain instead of keeping the replay artificially pinned to the bundle lane.
