# Issue #3 Production Execution Attached HTML Route

Use this note when `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md` is your
starting point and the next headed replay for issue `#3` is already narrowed to
attached or saved localhost HTML follow-up.

This is the shortest written bridge from the production execution guide into the
newer Windows-first surface check, the Windows-to-validation-router bridge, the
Windows-first catalog quickstart, the replay-side attached-html quickstart, the
validation-router attached-page quickstart, the smaller top-level bridges, the
suite-router and suite-catalog bridges, and the pinned three-page
compatibility bundle route.

## Goal

Keep the current attached-page route visible without reopening the full issue
`#3` note chain by hand.

Prefer this sequence when the production guide already pointed you at attached
localhost follow-up after the bounded Google-style and shared Enter-order gates
are green.

## Default read-first route

Use this compact sequence when no explicit bundle inputs, saved summary, or
non-default repo root need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the next replay should keep the Windows-first surface check,
its broader validation-router bridge, the Windows-side catalog quickstart, the
replay-side attached-html quickstart, the validation-router attached-page
quickstart, and the attached-page helper surface visible for as long as
practical before dropping back into the wrapper-heavy safe-route chain.

## When To Use Each Helper

1. `show_google_issue3_windows_full_use_attached_html_route.ps1`

Use this when the production execution guide or `docs/WINDOWS_FULL_USE.md`
already made attached localhost follow-up the next obvious branch.

2. `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`

Use this next when the broader Windows-first route is already obvious and you
want the route-level fail-fast surface check rerun before the route narrows
again.

3. `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`

Use this when the broader Windows-first route should stay aligned with the newer
validation-router attached-page bridge before the smaller attached-page helpers
reopen.

4. `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`

Use this when you want the Windows-side catalog quickstart visible before the
route narrows into the replay-side attached-html quickstart, the
validation-router attached-page bridge, the top-level attached-page notes, the
suite-catalog bridge, or the shorter replay surfaces.

5. `show_google_issue3_windows_replay_attached_html_quickstart.ps1`

Use this when the broader Windows-first route is still the best mental model,
but the next replay should stay on the narrower replay-side attached-page
ladder before the route narrows again.

6. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when you want the broader validation-router attached-page bridge kept
visible beside the narrower attached-page helpers before the route narrows
again.

7. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this when `show_headed_validation_suites.ps1 -ChangeArea attached-html`
already chose the broader attached-page compatibility route and you want the
broader attached-page flow helper plus the compact attached-page quickstarts
kept visible together.

8. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when you want the shortest top-level attached-page bridge first.

9. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when you want the broader top-level attached-page bridge reprinted
before the shorter helper surfaces.

10. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level attached-page bridge and the
suite-catalog-side attached-page bridge surfaced together.

11. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the replay should stay closer to the suite-router-side
attached-page branch before widening again.

12. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog-side attached-page bridge should stay visible
before narrowing again.

13. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the replay is already clearly inside attached-page follow-up and
you want the shortest issue `#3` bridge before widening into replay shortcuts,
the next-step matrix, or the safe-route helper.

14. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when the current pages are still the known three-page compatibility
bundle and you want that pinned route preserved before widening back into the
broader helper chain.

## Bundle-first route

When explicit `InputPath` values are already pinned to the known three-page
compatibility bundle, keep the route locked to that bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Preserve replay context

If a non-default repo root, a saved summary, or pinned bundle inputs are already
in play, carry that same context through the Windows-first bridge and the
quickstart surface first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Broader attached-page follow-up

When the replay still needs the broader attached-page or Google-shaped helper
surface instead of the shorter top-level bridge, start with one of these first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

## Companion notes

Keep these nearby when you want the written route beside the commands:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Practical rule

If the production execution guide already pushed the replay toward attached
localhost follow-up, keep the route on the Windows-first surface check, then
its validation-router bridge, then the Windows-side catalog quickstart, then
the replay-side attached-html quickstart, then the validation-router
attached-page quickstart before reopening the smaller attached-page helper
surface. Only reopen the longer validation-chain notes after the replay has
narrowed back into the wrapper-heavy safe-route path.