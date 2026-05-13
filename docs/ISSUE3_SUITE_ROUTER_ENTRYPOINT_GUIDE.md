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

After the top-level suite router, print the compact issue `#3` suite-router
bridge first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

Then print the current issue `#3` next-step helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
`show_google_issue3_suite_router_next_steps.ps1`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Which helper should come next

The current default is:

- `show_google_issue3_suite_router_handoff.ps1` immediately after the top-level suite router when the broader issue `#3` replay context still needs to be re-established before picking the narrower next helper
- `show_google_issue3_replay_shortcuts.ps1` once the bridge and next-step helper confirm that no pinned bundle inputs or saved summary are already in play
- `show_google_issue3_replay_route.ps1` when a `SummaryPath` is already available and the replay should stay narrow on the current saved-output context
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the current three-page compatibility set

Use `show_google_issue3_replay_route.ps1` whenever you want the broader
attached-bundle branch, the current safe-route map, and the repo-root-aware
runner next-step helper printed together before narrowing again.

Use `show_google_issue3_replay_shortcuts.ps1` after replay-route when you want
the narrower shortcut surface for the attached-bundle branch, bundle-first
helper, and safe-route entrypoints before choosing a wrapper-heavy next step.

## Read-first helper order

Use this compact sequence when the replay begins from the higher-level suite
router and no pinned bundle or saved summary has forced a narrower path yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when a saved summary is already in play and the replay
should stay on the current saved-output context before narrowing further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

Use this compact sequence when the replay should stay pinned to the current
attached three-page compatibility bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

## Keep these references nearby

- `docs/WINDOWS_FULL_USE.md` for the broader Windows headed runbook
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge into replay shortcuts
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and fresh replay entrypoints
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the safe-route handoff emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`

## Practical rule

Start from the top-level headed validation suite router, move immediately into
`show_google_issue3_suite_router_handoff.ps1`, then let
`show_google_issue3_suite_router_next_steps.ps1` pick between replay shortcuts,
replay route, or the bundle-first helper.

- no saved summary and no explicit bundle paths: go straight from the bridge and next-step helper to replay shortcuts
- saved summary already present: go to replay route first, then narrow into replay shortcuts only if needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
