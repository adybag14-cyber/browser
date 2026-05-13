# Issue #3 Suite Router Entrypoint Guide

This note is the shortest bridge from the top-level headed validation suite map
into the current issue `#3` replay helpers.

Use it when you start from `show_headed_validation_suites.ps1` and want the
next helper chosen quickly without reopening the longer Windows runbook or the
full wrapper-heavy safe-route notes first.

## Start points

Use either of these top-level headed validation router entrypoints first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

If the replay is already running from a non-default checkout, keep that same
repo-root context attached to those top-level entrypoints:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -SuiteName 'google-recommended'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -ChangeArea 'google-input'"
```

If the next replay should stay pinned to the known attached three-page
compatibility bundle, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

## Default next helper

After the top-level suite router, print the suite-catalog bridge first when you
want the exact top-level router entrypoints, the Google flow helper, the
next-step matrix, and the current replay helpers reprinted together on one
compact surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Then print the current issue `#3` next-step helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
both helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Which helper should come next

The current default is:

- `show_google_issue3_suite_catalog_entrypoints.ps1` immediately after the top-level suite router when you want the widest compact bridge back into the current issue `#3` helper chain
- `show_google_issue3_suite_router_next_steps.ps1` once the route is already known to stay inside issue `#3` and you want the fastest executable matrix before choosing the narrower branch
- `show_google_issue3_google_flow_context_bridge.ps1` when `RepoRoot`, `BrowserExe`, `Host`, a saved `SummaryPath`, or pinned bundle inputs already matter and you still want the broader Google flow kept aligned with the newer issue `#3` helper chain before narrowing again
- `show_google_issue3_replay_shortcuts.ps1` once the matrix confirms that no pinned bundle inputs or saved summary are already in play
- `show_google_issue3_replay_route.ps1` when a `SummaryPath` is already available and the replay should stay narrow on the current saved-output context
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the current three-page compatibility set
- `show_google_issue3_suite_router_handoff.ps1` when you explicitly want the broader read-first bridge reprinted after the catalog helper or matrix has already narrowed the likely route
- `show_google_issue3_safe_route_entrypoints.ps1` once replay-route, replay-shortcuts, the broader handoff helpers, or the context bridge have already confirmed the current branch and you want the current safe-route commands plus the runner-state helper printed before the next fresh replay or reuse-current-outputs step

Use `show_google_issue3_replay_route.ps1` whenever you want the broader
attached-bundle branch, the current safe-route map, and the repo-root-aware
runner next-step helper printed together before narrowing again.

Use `show_google_issue3_replay_shortcuts.ps1` after replay-route when you want
the narrower shortcut surface for the attached-bundle branch, bundle-first
helper, and safe-route entrypoints before choosing a wrapper-heavy next step.

Use `show_google_issue3_google_flow_context_bridge.ps1` before replay-route,
replay-shortcuts, or the safe-route entrypoints when the replay still needs the
broader `show_google_input_validation_flow.ps1` ladder, but the route also has
to preserve repo root, browser path, host, saved-summary state, or pinned
attached-bundle inputs all the way through the newer issue `#3` helpers.

Use `show_google_issue3_safe_route_entrypoints.ps1` after replay-route,
replay-shortcuts, the broader suite-router handoff, or the context bridge when
you want the current safe-route commands, notes, and runner next-step helper
surfaced in one place before choosing between the fresh replay wrapper and the
reuse-current-outputs wrapper.

## Read-first helper order

Use this compact sequence when the replay begins from the higher-level suite
router and no pinned bundle or saved summary has forced a narrower path yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when saved-summary state, repo-root overrides,
browser-path selection, host overrides, or pinned bundle inputs already matter
and the replay should keep the broader Google flow aligned before narrowing
further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_flow_context_bridge.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host 127.0.0.1 -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this compact sequence when the replay should stay pinned to the current
attached three-page compatibility bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use this compact sequence when you explicitly want the broader bridge helper
reprinted before choosing between replay-route, replay-shortcuts, the
bundle-first helper, or the safe-route map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

## Keep these references nearby

- `docs/WINDOWS_FULL_USE.md` for the broader Windows headed runbook
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md` for the wider prose bridge from the top-level validation catalog into the current helper chain
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge into replay shortcuts
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and fresh replay entrypoints
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the safe-route handoff emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`

## Practical rule

Start from the top-level headed validation suite router, move immediately into
`show_google_issue3_suite_catalog_entrypoints.ps1`, then let
`show_google_issue3_suite_router_next_steps.ps1` pick between replay shortcuts,
replay route, the bundle-first helper, the context bridge, or the safe-route
entrypoints.

- no saved summary and no explicit bundle paths: go straight from the catalog helper and next-step matrix to replay shortcuts, then open the safe-route entrypoints helper before the next wrapper-heavy replay step
- saved summary, browser path, repo-root override, host override, or pinned bundle inputs already present: use the context bridge first so the broader Google flow and the newer issue `#3` helper chain keep the same replay context aligned before narrowing again
- saved summary already present and the replay is already narrowed: go to replay route first, then narrow into replay shortcuts and the safe-route entrypoints helper only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- broader read-first bridge still needed: reopen `show_google_issue3_suite_router_handoff.ps1` after the catalog helper or matrix has already re-established the likely route, then continue into the safe-route entrypoints helper when the replay is ready for the wrapper-heavy branch

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
