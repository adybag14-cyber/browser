# Issue #3 Suite Router Entrypoint Guide

This note is the shortest written bridge from the top-level headed validation suite map into the current issue `#3` replay helpers.

Use it when you start from `show_headed_validation_suites.ps1` and want the next helper chosen quickly without reopening the full Windows runbook or the wrapper-heavy safe-route notes first, while still keeping the attached-page branch, the issue-specific Google-shaped attached-page checker and bridge, the dedicated Google-shaped attached-page flow, the suite-router handoff bridge, the replay-route shortcut bridge, and the bundle-aware branch visible before the route narrows too far.

## Keep Nearby

- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Start Points

Use either top-level validation router entrypoint first when the replay is broadly entering issue `#3`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

If the replay is already running from a non-default checkout, keep that same repo-root context attached to those entrypoints:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -SuiteName 'google-recommended'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -ChangeArea 'google-input'"
```

If you still want the broader suite-catalog surface before the shorter suite-router bridge takes over, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

## Windows-First Re-entry

If `docs/WINDOWS_FULL_USE.md` already made attached localhost replay the next obvious branch, reopen the Windows-side attached-page route first so that broader runbook surface stays aligned with the narrower issue `#3` helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
```

If repo root, summary path, or explicit attached bundle paths are already pinned, preserve that same context directly on those helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Attached-Page Re-entry

If the current replay still needs the broader Google-shaped attached-page surface before the bundle is pinned, keep this change-area entrypoint nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

If the current replay is already narrowed to the attached localhost HTML route itself and you want the shortest attached-page-specific bridge from the main validation catalog, keep these nearby too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_handoff_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

If the replay is already running from a non-default checkout or from explicit attached bundle paths, preserve that same context on the issue-specific checker, the Google-shaped flow helper, the issue-specific entrypoint helper, and the suite-router handoff checker too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_handoff_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Pinned Bundle Re-entry

If the next replay should stay pinned to the known attached three-page compatibility bundle, reopen the bundle change-area route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

If the replay is already close to that pinned bundle branch and you want the smallest suite-level bundle re-entry before the narrower bundle-first helper takes over, surface the compact bundle-suite helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

When repo root, summary path, or explicit bundle paths are already pinned, preserve that same context on the compact bundle-suite helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Default Next Helper

After the top-level suite router, print the suite-router shortcut-first entrypoint first when you want the shortest current bridge back into the general issue `#3` replay chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

When the replay is running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context on the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is already entering from `show_headed_validation_suites.ps1 -ChangeArea attached-html`, prefer the suite-router attached-page quickstart as the shortest bridge before the broader validation-router or replay-side ladders take over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

If the replay is already entering from `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`, prefer the issue-specific Google attached-page entrypoint first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

If the replay is already narrow enough and you want the tightest current helper surface immediately, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

If replay-route follow-up is already open and you want the shorter replay-route-specific bridge visible before the bundle-first helper or safe-route map takes over, print:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

## Practical Rule

Start from the top-level headed validation suite router, then move immediately into `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and no saved summary or pinned bundle inputs need to take precedence first.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: run the Windows full-use attached-page route first, then the Windows-to-validation-router bridge, then the Windows attached-page catalog quickstart, then the validation-router attached-page quickstart, then the replay-side attached-page quickstart, then the suite-router attached-page quickstart, then the issue-specific Google attached-page entrypoint, then the suite-router shortcut-first helper before widening into replay shortcuts, replay-route follow-up, or the safe-route map.
- broader issue `#3` router already surfaced the attached localhost branch: go from `-SuiteName google-recommended` or `-ChangeArea google-input` to the suite-router shortcut helper when the route is still generic, reopen `show_google_issue3_suite_catalog_entrypoints.ps1` when you want the broader suite-catalog re-entry surface kept visible first, or go directly to the suite-router attached-page quickstart when attached localhost follow-up is already the next obvious branch.
- current replay already narrowed to the attached localhost HTML route: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` first, then keep the attached-html change-area quickstart, the broader attached-page flow helper, the issue-specific Google attached-page checker, the dedicated Google-shaped attached-page flow helper, the issue-specific Google attached-page bridge, the suite-router handoff checker, the suite-router handoff bridge, and the suite-router attached-page quickstart visible before choosing between replay shortcuts, the replay-route shortcut helper, the bundle-first branch, or the safe-route map.
- broader Google-shaped attached-page surface still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` first, then `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`, then `show_google_attached_html_validation_flow.ps1`, then `show_google_issue3_google_attached_html_entrypoint.ps1`, then the suite-router handoff checker and handoff helper, and only then narrow into the shortcut-first or replay-shortcuts helpers.
- explicit bundle paths already pinned: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` first, then keep the compact bundle-suite helper visible before `show_google_issue3_attached_bundle_first_entrypoint.ps1` so the exact three-page compatibility set stays in view while the replay remains locked to the bundle flow.
- saved summary or repo-root override already present: pass the same replay context through the suite-router shortcut helper, the suite-router attached-page quickstart, the issue-specific checker, the issue-specific entrypoint, and the replay-route shortcut helper first, then choose replay shortcuts, contextual flow, the bundle-first helper, or the safe-route map only as needed.

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
