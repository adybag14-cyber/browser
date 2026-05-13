# Issue #3 Suite Router Next Steps

Issue `#3` now has several small read-first helpers that sit between the top-level
Windows validation router and the narrower safe-route replay chain.

This note is the compact decision guide for choosing the right next helper after
opening one of the higher-level validation entrypoints.

## Start here

Open one of the high-level issue `#3` entrypoints first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

If you want the helper to choose the fastest correct follow-up for you, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

## Next-step matrix

Use these defaults after the top-level router:

1. `show_headed_validation_suites.ps1 -SuiteName google-recommended`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1`

2. `show_headed_validation_suites.ps1 -ChangeArea google-input`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1`

3. `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1`

4. `show_google_issue3_suite_router_handoff.ps1`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1`

5. `show_google_issue3_replay_route.ps1`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1`

6. Safe-route wrapper emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>`

## Preserve replay context

When the replay is already using a non-default checkout, a saved summary, or a
pinned three-page compatibility bundle, carry that same context through the
next helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

That same context should stay attached when you reopen the handoff, replay
route, replay shortcuts, attached-bundle-first helper, safe-route entrypoints,
or runner next-step helper.

## When to choose each branch

- Use `show_google_issue3_suite_router_handoff.ps1` when you want the broadest issue `#3` read-first surface before the replay narrows.
- Use `show_google_issue3_replay_route.ps1` when issue `#3` is already confirmed and you want the compact bridge that keeps the bundle path, safe-route map, and runner next-step helper together.
- Use `show_google_issue3_replay_shortcuts.ps1` when you want the narrower shortcut map before choosing between the bundle-first route and the wrapper-heavy safe-route chain.
- Use `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the current saved or attached pages are still the known three-page compatibility bundle and you want that pinned route exercised first.
- Use `show_google_issue3_safe_route_entrypoints.ps1` after the broader suite-router work is already done and the replay is ready to choose between fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, or runner-wiring helpers.
- Use `show_google_issue3_runner_patch_next_step.ps1` only after a safe-route wrapper has already emitted one of the current runner-patch states.

## Keep these references open

- `docs/WINDOWS_FULL_USE.md` for the broader Windows validation runbook
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the prose bridge from the suite router into the narrower issue `#3` helper chain
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence once the replay narrows into the safe-route path
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the exact next move after the replay lands on one of the current runner-patch states

## Recommended use

When returning to issue `#3` after time away, prefer this order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

That keeps the higher-level router, the compact issue `#3` helper chooser, the
replay-route bridge, and the wrapper-heavy safe-route entrypoints aligned on the
same current branch guidance.
