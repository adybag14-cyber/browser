# Issue #3 Replay Quickstart Shortcut Bridge

Use this note when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay back to issue `#3`, and you want the shortest stable next helper without reopening the longer router and safe-route notes first.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
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

## Windows replay attached-page ladder

If `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay to the attached localhost branch and you want the shortest helper ladder that matches that Windows replay surface without reopening the broader router notes first, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the Windows replay attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that Windows replay attached-page ladder when:
- the replay was already narrowed from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` into the attached localhost branch
- you want the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, and the attached-page shortcut surfaced from one Windows-replay-side helper
- the broader Windows full-use attached-page route should remain easy to reopen before you widen back into replay shortcuts, the contextual flow, the bundle-first helper, or the safe-route map

## Top-level attached-page route

If the replay is already narrowed to the attached localhost HTML route and you want the broader top-level attached-page chain kept visible before the helper surface collapses back to the shorter shortcut flow, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly on the change-area, validation-router, top-level, suite-router, and suite-catalog attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that top-level attached-page route before the broader replay shortcuts when:
- the current replay is centered on the three attached localhost compatibility pages
- the bundle is not pinned yet and the broader attached-page helpers should stay visible
- you still want the attached-html change-area quickstart, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, and the suite-catalog attached-page bridge visible before the narrower attached-page shortcut surface
- you still want the top-level router, attached-page route, and shortcut-first bridge to remain easy to reopen

## Broader validation-router surfacing

Because `show_headed_validation_suites.ps1` now surfaces the issue `#3` validation-router attached-page quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the bundle-first helper directly from the broader `google-recommended`, `google-input`, and attached-page change-area entrypoints, reopen one of those broader router surfaces first when attached localhost follow-up has already become the next obvious branch but the replay has not been narrowed to the shorter helper chain yet.

Use this route when you want the attached-page branch surfaced directly from the broader validation catalog before you drop into the shorter issue-specific helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that broader router-first route when:
- the broader issue `#3` validation catalog already made attached localhost follow-up obvious
- you still want the attached-html change-area quickstart, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, and the suite-catalog attached-page bridge visible before replay shortcuts or the attached-page shortcut collapse the route again
- the bundle-first helper should remain easy to reopen from that same broader router surface before you widen into the wrapper-heavy safe route

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`, `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`, and `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md` nearby or print the two Windows-side companion helpers first so the broader Windows runbook route, its newer Windows-first catalog quickstart, and the narrower attached-page bridge stay aligned before you follow the same attached-html change-area, validation-router attached-page quickstart, top-level attached-page quickstart, top-level attached-page bridge, and top-level attached-page catalog quickstart sequence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
```

If the replay is already clearly inside `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` and the next move is to keep that shorter attached-page ladder together, prefer `show_google_issue3_windows_replay_attached_html_quickstart.ps1` before you widen back into the broader replay shortcuts or safe-route map.

If the current pages are still the pinned three-page compatibility bundle, reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` first and keep `show_google_issue3_attached_bundle_first_entrypoint.ps1` nearby before widening back into the broader replay shortcuts or safe-route map.

## Attached-page branch

If the replay is already narrowed from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` and you want that same Windows-side attached-page ladder reprinted from one compact helper before choosing the narrower attached-page bridge, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

If the replay is already narrowed past the top-level attached-page route and you want the shorter attached-page bridge kept visible before widening back into the broader helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
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
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1` when `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already pointed at the attached localhost branch and you want the shorter validation-router, top-level, catalog, and attached-page shortcut ladder reprinted from one Windows-replay-side helper before replay shortcuts or the safe-route map.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the broader validation catalog should reprint the attached-page route before the issue-specific helper chain narrows again.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` when the broader router should reopen on the pinned three-page bundle branch first.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the broader replay-route helper is already open and you want the smaller follow-up surface first.
- `show_google_issue3_suite_router_next_steps.ps1` when you still want the explicit executable matrix before choosing the next branch.
- `show_google_issue3_replay_route.ps1` when the attached-bundle route, saved summary state, and runner next-step helper should stay visible together.
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the known three-page compatibility set.
- `show_google_issue3_safe_route_entrypoints.ps1` when the next step is ready to move back into the wrapper-heavy safe-route helpers.

## Practical rule

Start from `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`, then reopen `show_headed_validation_suites.ps1 -SuiteName google-recommended`, `show_headed_validation_suites.ps1 -ChangeArea google-input`, or `show_headed_validation_suites.ps1 -ChangeArea attached-html` first when the broader validation catalog has already made attached localhost follow-up the next obvious branch. If the replay is already clearly inside the narrower Windows replay attached-page branch, run `show_google_issue3_windows_replay_attached_html_quickstart.ps1` first so the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, and the attached-page shortcut stay on one helper surface before you narrow further.

If the replay is already reopening from `-ChangeArea attached-html`, run `show_google_issue3_attached_html_change_area_quickstart.ps1` first, then `show_google_issue3_validation_router_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, then `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` before narrowing into the suite-router attached-page quickstart, the suite-catalog attached-page bridge, or the attached-page shortcut helper.

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, print `show_google_issue3_windows_full_use_attached_html_route.ps1` and `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1` before that narrower attached-page sequence so the broader Windows-first route stays aligned with the replay quickstart shortcut bridge.

Widen back into replay-route, the next-step matrix, or the safe-route map only when the narrower shortcut surface stops being enough.