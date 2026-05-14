# Issue #3 Attached HTML Change-Area Route

Use this note when the next headed replay is already centered on the generic attached localhost HTML compatibility lane for issue `#3` and you want the shortest read-first route from `show_headed_validation_suites.ps1 -ChangeArea attached-html` into the narrower issue-specific helper chain.

This keeps the generic attached-page branch, the shorter attached-page shortcut, and the pinned bundle-first fallback on one page without reopening the broader Windows runbook or the larger replay-route notes first.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`

## Default read-first route

Use this compact sequence when no saved summary, repo-root override, or pinned bundle paths need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:

- the replay is already on the generic attached-page compatibility lane
- the broader Google-only helper chain does not need to be reprinted first
- you want the shorter attached-page bridge before the replay shortcuts or wrapper-heavy safe-route entrypoints

## Preserve replay context

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, keep that same context attached to the narrower helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## If the bundle is already pinned

If the current saved or attached pages are still the known three-page compatibility set, stay on the pinned route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when you want the same locked bundle inputs preserved through the bundle surface checks, the bundle-first helper, the delegated flow helper, and the localhost runner before widening back into the broader issue `#3` helper stack.

## If the Google-shaped attached route matters more

If the next replay still needs the Google-shaped attached-page surface checker and flow helper kept visible before you narrow into the generic shortcut chain, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Then drop back to the generic attached-page shortcut or replay shortcuts only after the broader Google-shaped attached-page surface is no longer the main question.

## Pick the next helper quickly

1. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this first when the route is already narrowed to attached localhost HTML from the suite-router side and you want the shortest attached-page-first bridge.

2. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this next when the replay should keep the top-level attached-page bridge visible before widening into replay shortcuts, the replay-route shortcut, or the safe-route map.

3. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the generic attached-page compatibility route kept visible before you widen back into replay shortcuts, the next-step matrix, or the safe-route map.

4. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

5. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the attached-page branch is already out of the way and you want the current wrapper-heavy issue `#3` commands printed in one place before the next fresh replay or reuse-current-outputs step.

## Practical rule

Once `show_headed_validation_suites.ps1 -ChangeArea attached-html` has already narrowed the replay to the generic attached localhost compatibility lane, prefer the suite-router attached-page quickstart, then the top-level attached-page bridge, then the attached-page shortcut before reopening the broader helper chain again.

- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the suite-router attached-page quickstart, then the top-level attached-page bridge, then the attached-page shortcut, then replay shortcuts, then the safe-route map
- Google-shaped attached-page surface still matters: go from `-ChangeArea google-attached-html` to the suite-router attached-page quickstart, then the Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the suite-router attached-page quickstart with that same context first, then choose the narrower follow-up that matches the current replay state

Only reopen the longer validation-chain notes after the route has already narrowed into the wrapper-heavy safe path.
