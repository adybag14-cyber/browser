# Issue #3 Replay Discovery Attached HTML Bridge

Use this note when issue `#3` work is re-entering from the replay-discovery side and the attached localhost HTML route is already the right branch.

This keeps the suite-catalog attached-page route visible before the replay narrows back into the shorter issue-specific helper chain.

Keep these companion notes nearby:
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Read-first route

Start here when the replay is already centered on the attached localhost compatibility pages and you want the catalog-side attached-page bridge before reopening the narrower issue `#3` helpers:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the suite-catalog surface already made the attached-page lane obvious and you want the written bridge to match the current helper order.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the suite-catalog attached-page helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:
- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
Use this first when the replay is already on the suite-catalog attached-page branch and you want the shortest issue-specific attached-page bridge.

2. `show_google_issue3_google_attached_html_entrypoint.ps1`
Use this when the broader Google-shaped attached-page surface checker and flow helper still need to stay visible before narrowing again.

3. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
Use this when you want the attached-page compatibility route kept visible before you widen back into replay shortcuts or the safe-route map.

4. `show_google_issue3_replay_shortcuts.ps1`
Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen into the bundle-first helper or the safe-route map.

5. `show_google_issue3_safe_route_entrypoints.ps1`
Use this when the attached-page helper branch is already out of the way and you want the wrapper-heavy issue `#3` commands, notes, and runner-state helper surfaced in one place before the next fresh replay or reuse-current-outputs step.

## Bundle-first variant

If the current pages are still the pinned three-page compatibility bundle, keep the replay on that locked route before widening back into the broader helper chain:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the known three-page compatibility set should stay pinned all the way through the suite-catalog helper, the bundle-first branch, the flow helper, and the delegated localhost runner before widening back into the broader issue `#3` helper stack.

## Practical rule

Once the replay-discovery side has already narrowed the work to the attached localhost HTML follow-up, prefer `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` before reopening the longer validation-chain notes again.

- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the suite-catalog attached-page helper, then the Google attached-page entrypoint, then the attached-page shortcut, then replay shortcuts, then the safe-route map
- Google-specific attached-page surface still matters more than the generic shortcut chain: go from `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` to `show_google_issue3_google_attached_html_entrypoint.ps1` before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the suite-catalog attached-page helper with that same context first, then choose replay shortcuts or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
