# Issue #3 Top-Level Suite Router Shortcuts

Use this note when issue `#3` work starts from the top-level Windows validation catalog and needs the shortest route back into the current replay helpers.

## Read-first order

1. Broader issue `#3` suite entry:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended`
2. Narrower Google-input suite entry:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input`
3. Pinned three-page bundle branch when the attached compatibility set is already known:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
4. Compact suite-router bridge:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1`
5. Compact next-step matrix:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1`
6. Broader replay route helper:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1`
7. Narrower replay-shortcuts helper:
   - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1`

## Routing rules

- Stay on the attached-bundle branch first when the current work item is the saved or attached three-page compatibility bundle.
- Reopen `show_google_issue3_replay_route.ps1` before `show_google_issue3_replay_shortcuts.ps1` when the broader issue `#3` context still needs to be re-established.
- Reopen `show_google_issue3_safe_route_entrypoints.ps1` only after the suite-router bridge, next-step matrix, replay route, or replay shortcuts have already narrowed the run into the wrapper-heavy safe-route path.
- Keep `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`, `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`, and `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` nearby when the replay needs the longer written explanation beside the command surface.

## Context-preserving examples

- Non-default repo root:
  - `powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = 'C:\work\browser'; & '.\scripts\windows\show_headed_validation_suites.ps1' -SuiteName 'google-recommended'"`
- Saved summary already in play:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -SummaryPath 'artifacts\google-issue3-summary.json'`
- Pinned attached bundle inputs:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '.\user_files\page-a.html' '.\user_files\page-b.html' '.\user_files\page-c.html'`
