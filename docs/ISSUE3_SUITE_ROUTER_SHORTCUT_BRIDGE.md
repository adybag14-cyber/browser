# Issue #3 Suite-Router Shortcut Bridge

Use this note when issue `#3` work starts from the higher-level Windows validation router and the next replay should move quickly into the repo-root-aware replay-route and shortcut surfaces instead of reopening the longer chain notes first.

If you want that suite-router next-step matrix printed in one command before choosing between the handoff, replay-route, bundle-first, and safe-route branches, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit attached-bundle path, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Goal

Keep the first issue `#3` commands stable when you start from:

- `show_headed_validation_suites.ps1 -SuiteName google-recommended`
- `show_headed_validation_suites.ps1 -ChangeArea google-input`

Then hand off immediately into the replay-route helper before narrowing further into the shortcut helper that keeps the current replay context attached.

If you want that bridge printed in one command before choosing between the bundle-first and safe-route branches, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

## Default read-first sequence

Use these commands in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Why this bridge matters:

- the suite router is still the quickest way to surface the broader issue `#3` lane from the top-level catalog
- the suite-router handoff helper is now the shortest way to reprint those read-first commands beside the current replay-route, replay-shortcuts, bundle-first, and safe-route map helpers
- the replay-route helper is now the compact default next step that keeps the attached three-page bundle route, safe-route entrypoints, fresh replay, and runner next-step helper together
- reopening the replay-route helper immediately avoids drifting back through the longer validation-chain note when the next replay already knows it is on issue `#3`

If you already know you want the narrower shortcut map right after the replay-route helper, continue with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

## Suite-router next-step matrix

Use this compact map when you are starting from the top-level suite router and want the fastest correct next helper without reopening the longer chain notes first.

If you want the same matrix as executable commands in one compact helper, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

- `show_headed_validation_suites.ps1 -SuiteName google-recommended`
  Default next helper: `show_google_issue3_suite_router_handoff.ps1`
  Use this when you want the higher-level suite entrypoints and the newer issue `#3` replay helpers reprinted together before choosing the next route.
- `show_headed_validation_suites.ps1 -ChangeArea google-input`
  Default next helper: `show_google_issue3_replay_route.ps1`
  Use this when you already know the work stays inside issue `#3` and want the compact replay-route surface right away.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
  Default next helper: `show_google_issue3_attached_bundle_first_entrypoint.ps1`
  Use this when the current saved or attached inputs are still the pinned three-page compatibility bundle and you want the one-command bundle-first helper to keep that locked route plus the safe-route return visible before the broader Google-only wrappers.
- `show_google_issue3_suite_router_handoff.ps1`
  Default next helper: `show_google_issue3_replay_route.ps1`
  Use this when the handoff helper has already confirmed the broader router state and you want the current replay-route, bundle branch, and safe-route entrypoints in one tighter surface.
- `show_google_issue3_replay_route.ps1`
  Default next helper: `show_google_issue3_replay_shortcuts.ps1`
  Use this when you want the narrower shortcut map before deciding between the attached-bundle-first route, the fresh safe-route replay, or the wrapper-heavy safe-route entrypoints map.
- Wrapper-emitted runner state already known
  Default next helper: `show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>`
  Use this when the current replay already has a saved summary path plus one of the three runner-patch states and you want the shortest exact next-step command map.

## Bundle-first read-first sequence

Use this alternate route when the current saved or attached pages are still the known three-page compatibility bundle and the replay should stay pinned to that bundle before reopening the broader Google-only helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when:

- the current replay inputs are the pinned three-page compatibility set rather than a broader saved-page or live Google retest
- you want the attached-bundle surface check, flow helper, and delegated localhost runner to stay on one locked route from the higher-level suite router
- you only want to reopen `show_google_issue3_replay_route.ps1`, `show_google_issue3_replay_shortcuts.ps1`, or `show_google_issue3_safe_route_entrypoints.ps1` after the bundle replay makes the next Google-style input or submit failure state clear

## Preserve non-default replay context

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit attached bundle path, preserve that context directly in the suite-router handoff helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you already know you want the replay-route helper right away, preserve that same repo-root and summary context directly in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

If you already know you want the narrower shortcut helper right away, preserve that same context directly in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use those commands immediately after the top-level suite-router commands when:

- `LIGHTPANDA_REPO_ROOT` should stay attached to later helpers
- the current replay is already carrying a saved summary artifact
- the current saved or attached pages are the known three-page compatibility bundle

## Decide between the four main follow-ups

After `show_google_issue3_suite_router_handoff.ps1` or `show_google_issue3_replay_route.ps1` prints the current routes, choose one of these first:

1. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when you want the narrower shortcut map for the attached bundle branch, bundle-first helper, and safe-route entrypoints before deciding whether the replay should stay pinned to the compatibility bundle or reopen the broader wrapper-heavy issue `#3` path.

2. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when the current saved or attached pages are still the known three-page compatibility bundle and you want the pinned bundle route exercised before reopening the broader Google-only safe route.

3. Fresh safe-route replay

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

Use this when the current issue `#3` outputs may be stale or missing and you want the current safe-route replay plus the final runner-patch handoff artifact in one command.

4. Safe-route entrypoints map

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the higher-level suite router is already out of the way and you want the current wrapper-heavy issue `#3` commands, notes, and next-state helper surfaced in one place before the next replay step.

## When a runner-patch state is already known

If the safe-route wrapper or reuse-current-outputs helper already named one of the direct runner-patch states, go straight to the next-step helper instead of reopening the longer chain note first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>
```

Use that state helper after the suite-router handoff helper, replay-route helper, or replay-shortcuts helper when the current run already has:

- a saved summary path
- a wrapper-emitted runner state
- a need to preserve repo-root-aware recovery commands beside the next-step output

## Notes to keep nearby

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current issue `#3` replay route
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and the larger safe-route ordering
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay lands on one of the three runner-patch states
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` when the replay is already narrowed to a direct runner-source edit
