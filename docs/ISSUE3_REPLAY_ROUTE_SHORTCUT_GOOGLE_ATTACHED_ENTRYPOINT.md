# Issue #3 Replay-Route Shortcut Google Attached Entrypoint

Use this note when issue `#3` work is already inside the replay-route shortcut helper and the next replay should stay on the narrower Google-shaped attached localhost branch before widening back into replay shortcuts, the bundle-first path, or the wrapper-heavy safe-route helpers.

This guide complements:

- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the replay-route shortcut surface, keep the broader Google-shaped attached-page flow visible long enough to confirm the route still fits the current inputs, rerun the issue-specific Google attached-page checker, then use the dedicated Google attached-page entrypoint before the replay narrows again.

Use this note when:

- the replay-route helper is already open
- the attached localhost inputs still look Google-shaped
- you want the narrower issue `#3` Google attached-page branch visible before dropping back into replay shortcuts or the safe-route map

## Default read-first route

Use this compact route when no saved summary, non-default repo root, or explicit bundle pin should take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- the replay-route shortcut is already trusted enough to stay inside the narrower issue `#3` helper chain
- the broader Google-shaped attached-page flow still matters more than the generic attached-page fallback
- you want the issue-specific checker and entrypoint visible before replay shortcuts or the safe-route map take over

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or explicit attached-page inputs, keep that same context on the narrower Google branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_replay_route_shortcut_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<attached-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<attached-html-or-folder>' -PreferredInitialPage '<preferred-page>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<attached-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at the current replay outputs
- one attached page should stay first instead of relying on auto-discovery

## Bundle-aware alternate route

If the current inputs are still the known three-page compatibility bundle, keep the pinned bundle route visible beside the narrower Google attached-page helper before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the current replay should stay pinned to the Google Safety Centre, Anthropic job application, and UAP encounters pages
- the narrower issue-specific Google attached-page helper still helps, but the exact bundle must stay visible before widening into replay shortcuts or the safe-route map

## Pick the next helper quickly

1. `show_google_attached_html_validation_flow.ps1`

Use this first when the broader Google-shaped attached-page flow still needs to stay visible before the issue-specific route narrows.

2. `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`

Use this next when the compact Google issue `#3` attached-page surface may have drifted and should fail fast before you trust the narrower entrypoint.

3. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the route is already confirmed and you want the shortest issue-specific Google attached-page bridge back into the narrower helper chain.

4. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this when no pinned bundle inputs, saved summary, or non-default repo root need to take precedence and you want the shortcut-first helper immediately after the issue-specific Google branch.

5. `show_google_issue3_replay_shortcuts.ps1`

Use this when the replay is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

6. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or the replay should stay on the known three-page compatibility bundle before widening back into the broader issue `#3` chain.

7. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the narrower attached-page branch is out of the way and you want the wrapper-heavy commands, notes, and runner-state helpers surfaced in one place.

## Practical rule

Once `show_google_issue3_replay_route_shortcut_entrypoint.ps1` is already open and the current attached localhost inputs still look Google-shaped, prefer `show_google_attached_html_validation_flow.ps1`, `check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1`, and `show_google_issue3_google_attached_html_entrypoint.ps1` before dropping back into replay shortcuts or the safe-route map.

- no pinned bundle inputs and no saved replay context yet: go from the replay-route shortcut helper to the broader Google-shaped attached-page flow, then the issue-specific checker, then the issue-specific entrypoint, then the shortcut-first helper, then replay shortcuts
- broader attached localhost fallback still matters: keep `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` and `show_attached_html_validation_flow.ps1` nearby beside this note so the generic attached-page route stays easy to reopen
- explicit bundle paths already pinned: reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`, `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`, and `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` before the bundle-first helper so the exact three-page compatibility set stays visible while the replay stays on the bundle-aware path
- saved summary or repo-root override already present: keep that same replay context attached to the issue-specific checker and entrypoint first, then choose contextual flow, replay shortcuts, bundle-first, or the safe-route map only as needed

Only widen back into the longer validation-chain notes after the narrower Google attached-page bridge has taken the replay as far as it can go.