# Issue #3 Replay-Route Shortcut Entrypoint

Use this note when issue `#3` replay is already inside `show_google_issue3_replay_route.ps1` and you want the shortest written handoff into the narrower attached-page shortcut, replay-shortcuts, bundle-first, or safe-route helpers.

If you want the matching helper first, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from a saved summary, or from explicit attached-bundle paths, preserve that same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Start from the broader replay-route helper, then reopen the shortest attached-page and replay-shortcut surfaces without losing the current repo-root, saved-summary, or pinned bundle-input context. Keep the attached-page shortcut, the suite-router shortcut bridge, the compact replay-shortcuts helper, the bundle-first branch, and the safe-route map aligned before the route widens again.

## Default read-first route

Use this route when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:

- the broader replay-route helper already made issue `#3` obvious
- the next step should stay on the shorter attached-page shortcut surface before replay shortcuts or the safe-route map
- you still want the suite-router shortcut bridge and the next-step matrix visible before the route widens again

## Bundle-first alternate route

If the current saved or attached pages are still the pinned three-page compatibility bundle, keep that route fixed first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the next useful choice depends on whether the known three-page compatibility bundle still reproduces the current headed issue `#3` state.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the shortcut entrypoint first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the route is already narrow enough to stay inside the shortest attached-page bridge before replay shortcuts, the next-step matrix, or the safe-route map.

2. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this when the broader suite-router shortcut bridge should stay visible beside the attached-page shortcut before the replay narrows again.

3. `show_google_issue3_replay_shortcuts.ps1`

Use this when issue `#3` is already clearly narrowed and you want the tightest compact helper surface before choosing between the next-step matrix, contextual flow, bundle-first, or the safe-route map.

4. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you want the executable branch matrix reprinted after the replay-route shortcut bridge is confirmed.

5. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and the next helper should keep that replay state aligned.

6. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit bundle paths are already pinned or when the replay should stay on the known three-page compatibility set before widening back into the broader Google-only helper chain.

7. `show_google_issue3_safe_route_entrypoints.ps1`

Use this only after the attached-page shortcut and replay-shortcuts surfaces have already clarified that the wrapper-heavy safe route is the next useful layer.

## Practical rule

Only use this shortcut note after `show_google_issue3_replay_route.ps1` is already the current helper surface.

- no pinned bundle inputs and no saved replay state yet: jump from the replay-route helper into the attached-page shortcut surface first, then keep replay shortcuts and the next-step matrix nearby
- broader suite-router shortcut bridge still matters: keep the suite-router shortcut entrypoint visible before replay shortcuts or the safe-route map
- saved summary or repo-root override already present: reopen this note with that same context first, then choose the narrower follow-up
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path

Only reopen the longer validation-chain notes after the route has narrowed as far as it can go through the shortcut-first helper family.
