# Issue #3 Attached HTML Flow Helper Route

Use this note when issue `#3` replay is already centered on attached localhost
follow-up and you want the broader attached-page flow helper visible before the
route narrows into the smaller top-level, shortcut, or bundle-first helpers.

This note is intended to stay aligned with
`show_attached_html_validation_flow.ps1` and the attached-html issue `#3`
helpers on `fork/headed-mode-foundation`.

Keep these companion notes nearby:

- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the broader attached localhost route, keep
`show_attached_html_validation_flow.ps1` visible as the read-first flow map,
and then choose the smallest issue `#3` helper that matches the current replay
state.

Use the broader attached-page flow helper when:

- the replay is already centered on attached localhost pages but the exact next
  issue `#3` helper is not settled yet
- you want the generic attached-page surface visible before choosing between
  validation-router, top-level, suite-router, shortcut, replay-shortcuts, or
  bundle-first follow-up
- the route should stay readable for local headed-page testing without jumping
  straight into the wrapper-heavy safe-route layer

## Read-First Route

Use this sequence when attached localhost follow-up is already obvious and you
want the broader attached-page flow helper printed before the route narrows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- `show_headed_validation_suites.ps1 -ChangeArea attached-html` already made
  the attached-page branch obvious
- you still want the broader attached-page flow map printed before the route
  narrows into the shorter issue `#3` helpers
- the replay is not yet ready to jump straight to the attached-page shortcut or
  the bundle-first path

## Windows-First Re-entry

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, keep the
broader Windows bridge visible before the attached-page flow helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

Use that route when the broader Windows runbook already made attached localhost
follow-up obvious and you want the Windows-side bridge plus the generic
attached-page flow helper visible together before the issue `#3` helpers narrow
again.

## Bundle-First Route

If the current pages are still the known three-page compatibility set, keep the
bundle-first helper visible before widening back into the broader attached-page
flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when explicit `InputPath` values are already pinned or when the
next replay should stay on the locked three-page compatibility bundle before it
widens back into the broader issue `#3` helper chain.

## Choosing The Next Helper

1. `show_google_issue3_validation_router_attached_html_quickstart.ps1`
   Use this when you still want the broader validation-router bridge visible.
2. `show_google_issue3_top_level_attached_html_quickstart.ps1`
   Use this when the route should stay compact before reopening the broader
   top-level bridge.
3. `show_google_issue3_top_level_attached_html_entrypoint.ps1`
   Use this when the broader top-level attached-page bridge should be reprinted
   before narrowing again.
4. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
   Use this when the compact top-level route and the suite-catalog-side bridge
   should stay visible together.
5. `show_google_issue3_suite_router_attached_html_quickstart.ps1`
   Use this when the route should stay on the suite-router side of the
   attached-page ladder before the shortcut layer.
6. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
   Use this when the attached-page path is already clear and you want the
   shortest bridge before replay shortcuts.
7. `show_google_issue3_replay_shortcuts.ps1`
   Use this when the route is already clearly inside issue `#3` and you want
   the narrowest helper surface before widening again.
8. `show_google_issue3_attached_bundle_first_entrypoint.ps1`
   Use this when explicit bundle inputs are already pinned.

## Practical Rule

Once the replay is already centered on attached localhost follow-up, prefer the
change-area quickstart and `show_attached_html_validation_flow.ps1` before you
collapse into the smaller issue `#3` helper ladder. Only reopen the longer
validation-chain notes after the route has narrowed into the wrapper-heavy safe
path.
