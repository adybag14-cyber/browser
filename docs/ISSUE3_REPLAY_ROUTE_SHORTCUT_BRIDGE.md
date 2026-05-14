# Issue #3 Replay-Route Shortcut Bridge

Use this note when issue `#3` work is already inside the replay-route helper and the next replay should move quickly into the shorter attached-page, replay-shortcuts, bundle-first, or safe-route follow-up without reopening the broader route notes first.

If you want the shortest replay-route follow-up, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`

## Goal

Start from `show_google_issue3_replay_route.ps1`, then hand off immediately into `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the route is already known to stay inside the narrower issue `#3` helper chain.

From there, prefer one of these shorter follow-ups before reopening the broader safe-route notes:

- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this route when the replay-route helper is already open and you want the narrowest stable bridge back into the attached-page shortcut, replay-shortcuts surface, and return-to-safe-route helpers.

## Preserve replay context

If the replay is already carrying a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the replay-route shortcut helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

After `show_google_issue3_replay_route_shortcut_entrypoint.ps1`, prefer one of these branches first:

1. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the attached-page compatibility route kept visible before you widen back into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

2. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the narrower compact helper surface before deciding whether to widen into the bundle-first helper or the safe-route map.

3. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

4. Safe-route entrypoints map

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the replay-route helper is already out of the way and you want the current wrapper-heavy issue `#3` commands, notes, and runner-state helper surfaced in one place before the next fresh replay or reuse-current-outputs step.

## Bundle-first alternate route

Use this alternate sequence when the current saved or attached pages are still the pinned three-page compatibility bundle and the replay should stay there first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when:

- the current replay inputs are still the known three-page compatibility set
- you want the pinned bundle route exercised before reopening the broader safe-route chain
- the next useful decision depends on whether the attached-page bundle still reproduces the current headed issue `#3` state

## Practical rule

Once `show_google_issue3_replay_route.ps1` has already narrowed the route, prefer `show_google_issue3_replay_route_shortcut_entrypoint.ps1` before reopening the wider handoff notes again.

- no pinned bundle inputs and no saved replay state yet: go straight from replay route to the replay-route shortcut helper, then attached HTML shortcut, then replay shortcuts, then the safe-route map
- saved summary or repo-root override already present: reopen the replay-route shortcut helper with that same context first, then choose replay shortcuts or the safe-route map only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- attached-page follow-up still matters more than the general shortcut chain: reopen the attached HTML shortcut first, then widen into replay shortcuts or the safe-route map only after that attached-page route is clear

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.