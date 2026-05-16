# Issue #3 Suite-Catalog Attached HTML Replay-Route Bridge

Use this note when issue `#3` replay is already inside the suite-catalog attached HTML route and the next useful move is to widen slightly into the suite-router handoff or the replay-route helper before dropping back into the narrower attached-page ladder.

This is the smallest written bridge for that handoff. Keep it nearby when `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` already made the attached-page lane obvious, but the replay still needs the broader replay-route helper family or the suite-router handoff reprinted before you choose the next narrow helper.

## Read-first helpers

Start with the compact suite-catalog attached-page bridge first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Then reopen the slightly broader handoff surfaces before narrowing again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Use that order when the attached localhost lane is already clear but you still want the suite-router handoff, replay-route helper, replay-route shortcut, bundle-first branch, and safe-route map visible beside the suite-catalog attached-page route.

## Keep these notes nearby

- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`
- `docs/ISSUE3_REPLAY_ROUTE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the suite-catalog attached-page surface, keep the suite-catalog guide and the replay-side attached-page ladder visible, then widen just enough to reopen the suite-router handoff and replay-route helper before deciding whether the next move should be the replay-route shortcut, the attached-page shortcut, replay shortcuts, contextual flow, the pinned bundle branch, or the safe-route map.

## Default route

Use this route when no pinned bundle inputs, saved summary output, or non-default repo root need to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- the replay is already clearly inside issue `#3` attached localhost follow-up
- the suite-catalog attached-page bridge is already the active narrow surface
- you want the suite-router handoff and replay-route helper reprinted before the route collapses into the shorter replay shortcuts or widens into the safe-route wrappers

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached while you widen into the handoff helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Bundle-first variant

If the current inputs are still the pinned three-page compatibility bundle and the replay should stay on that locked route even while you widen slightly, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known Google Safety Centre, Anthropic application, and UAP encounters pages should stay explicit while the suite-catalog attached-page route widens into the replay-route family.

## Practical rule

Prefer this bridge only after `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` is already the active helper surface.

- the next replay still needs the suite-router-side framing: reopen `show_google_issue3_suite_router_handoff.ps1` first
- the next replay needs the broader replay-route family and replay-route shortcut beside the attached-page lane: reopen `show_google_issue3_replay_route.ps1` next
- the route is already narrow enough to stay inside compact helpers: skip this note and drop straight to `show_google_issue3_replay_route_shortcut_entrypoint.ps1` or `show_google_issue3_replay_shortcuts.ps1`
- explicit bundle paths are already pinned: keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` nearby and stay on the bundle-first branch before widening into the broader safe-route path

Only reopen the longer validation-chain notes after the route has narrowed as far as it can through the suite-catalog attached-page bridge, the suite-router handoff, the replay-route helper, and the smaller replay shortcuts.