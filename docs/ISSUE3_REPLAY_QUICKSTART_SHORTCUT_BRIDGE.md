# Issue #3 Replay Quickstart Shortcut Bridge

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay back to issue `#3`, and you want the shortest stable next helper without reopening the longer router and safe-route notes first.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Default shortcut-first route

Use this route when the top-level suite router already made issue `#3` obvious and no saved summary or pinned bundle inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the shortcut-first entrypoint first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Top-level attached-page route

If the replay is already narrowed to the attached localhost HTML route and you want the broader top-level attached-page chain kept visible before the helper surface collapses back to the shorter shortcut flow, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly on the top-level, suite-router, and suite-catalog attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that top-level attached-page route before the broader replay shortcuts when:
- the current replay is centered on the three attached localhost compatibility pages
- the bundle is not pinned yet and the broader top-level attached-page helpers should stay visible
- you still want the suite-router attached-page quickstart and the suite-catalog attached-page bridge visible before the narrower attached-page shortcut surface
- you still want the top-level router, attached-page route, and shortcut-first bridge to remain easy to reopen

## Attached-page branch

If the replay is already narrowed past the top-level attached-page route and you want the shorter attached-page bridge kept visible before widening back into the broader helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use that attached-page branch before the broader replay shortcuts when:
- the current replay is centered on the three attached localhost compatibility pages
- the bundle is not pinned yet and the narrower attached-page helper should stay visible
- you still want the suite-catalog attached-page bridge available before the attached-page shortcut collapses the route further
- you still want the top-level router, attached-page route, and shortcut-first bridge to remain easy to reopen

## When To Widen

Reopen one of these helpers only when the narrower shortcut surface is no longer enough:
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the broader replay-route helper is already open and you want the smaller follow-up surface first
- `show_google_issue3_suite_router_next_steps.ps1` when you still want the explicit executable matrix before choosing the next branch
- `show_google_issue3_replay_route.ps1` when the attached-bundle route, saved summary state, and runner next-step helper should stay visible together
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the known three-page compatibility set
- `show_google_issue3_safe_route_entrypoints.ps1` when the next step is ready to move back into the wrapper-heavy safe-route helpers

## Practical rule

Start from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`, then jump into `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and the replay does not need the wider catalog bridge reprinted. Reopen the top-level attached-page quickstart and top-level attached-page bridge first when the replay is already centered on the attached localhost pages, then narrow into the suite-router attached-page quickstart, the suite-catalog attached-page bridge, and the attached-page shortcut helper. Widen back into replay-route, the next-step matrix, or the safe-route map only when the narrower shortcut surface stops being enough.