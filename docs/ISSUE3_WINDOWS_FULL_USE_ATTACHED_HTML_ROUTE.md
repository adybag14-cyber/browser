# Issue #3 Windows Full-Use Attached HTML Route

Use this note when you are starting from `docs/WINDOWS_FULL_USE.md` and the next headed replay is already centered on the attached localhost HTML compatibility pages for issue `#3`.

This keeps the shortest current attached-page-first command path in one place without reopening the broader suite-catalog, replay-route, or wrapper-heavy safe-route notes first.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`

## Default read-first route

Use this compact sequence when the top-level Windows runbook already made the attached-page follow-up obvious and no saved summary, repo-root override, or pinned bundle path needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:

- the current follow-up is already on the attached localhost compatibility lane
- the replay does not need the broader Google-only router helpers reprinted first
- you want the compact top-level attached-page quickstart kept visible before the suite-router quickstart and top-level attached-page bridge narrow the helper chain again

## Preserve replay context

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, keep that same context attached to the narrower helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## If the bundle is already pinned

If the next replay should stay on the known three-page compatibility bundle before widening back into the broader issue `#3` helper stack, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the current saved or attached page set is already the known three-page bundle and you want that same locked input set preserved through the surface check, helper branch, flow helper, and delegated localhost runner.

## Pick the next helper quickly

1. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this first when the broader Windows runbook already narrowed replay to attached localhost follow-up and you want the shortest top-level attached-page bridge kept visible before the helper chain narrows again.

2. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this next when the route is already narrowed to attached localhost HTML from the suite-router side and you want the shortest attached-page-first bridge.

3. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this next when the replay should keep the broader top-level attached-page bridge visible before widening into replay shortcuts, the replay-route shortcut, or the safe-route map.

4. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

5. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the attached-page branch is already out of the way and you want the current wrapper-heavy issue `#3` commands printed in one place before the next fresh replay or reuse-current-outputs step.

## Practical rule

When `docs/WINDOWS_FULL_USE.md` has already narrowed the next replay to attached localhost follow-up, reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` first, then prefer the top-level attached-page quickstart, the suite-router attached-page quickstart, and the top-level attached-page bridge before reopening the broader helper chain.
