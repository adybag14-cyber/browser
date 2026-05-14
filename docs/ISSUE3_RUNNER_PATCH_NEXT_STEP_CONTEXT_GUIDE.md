# Issue #3 Runner Patch Next-Step Context Guide

Use this note when the issue `#3` safe-route wrapper has already emitted one of
the runner-patch states and the replay should keep the same `RepoRoot`, saved
`SummaryPath`, and attached helper chain aligned while you choose the exact next
command.

## Goal

Keep the direct runner-patch recovery path easy to reopen from the current
issue `#3` validation lane without reconstructing the same non-default replay
context by hand.

This guide is the compact bridge between:

- `show_google_issue3_suite_router_handoff.ps1`
- `show_google_issue3_replay_route.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_runner_patch_next_step.ps1`

## State helper entrypoint

Use the runner next-step helper directly once the safe-route wrapper or the
reuse-current-outputs helper has already named one of these states:

- `ready-for-runner-patch`
- `already-direct`
- `runner-already-wired-regenerate-outputs`

Default command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>
```

If the replay is running from a non-default checkout or already has a saved
summary artifact, preserve that same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>
```

## Read-first recovery route

Use this compact sequence when the higher-level route is still helpful before
you act on the runner-patch state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>
```

Use that route when:

- `LIGHTPANDA_REPO_ROOT` should stay attached to later helper commands
- a current safe-route wrapper already emitted a saved `SummaryPath`
- the replay still needs the broader suite-router, replay-route, or shortcut
  surfaces visible before the direct runner step

## Exact state examples

If the wrapper says `ready-for-runner-patch`, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State ready-for-runner-patch
```

Use this when the replay still needs a direct source edit in
`run_google_issue3_recommended_validation.ps1` and you want the repo-root-aware
rerun plus safe-wiring commands printed together beside the current artifact
paths.

If the wrapper says `already-direct`, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State already-direct
```

Use this when the source is already wired and the next move should go straight
back to the safe wiring audit instead of patching the runner again.

If the wrapper says `runner-already-wired-regenerate-outputs`, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State runner-already-wired-regenerate-outputs
```

Use this when the source is already wired but the saved outputs still need a
regeneration pass before the safe wiring audit is rerun.

## Keep these nearby

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest safe-route replay note
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and the broader issue `#3` safe-route ladder
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the longer direct runner-patch decision table
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` for the field-level patch rules once the replay is already narrowed to a direct source edit
- `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md` when the replay should keep `LIGHTPANDA_REPO_ROOT` plus `SummaryPath` aligned through the broader safe-route helpers

## Practical rule

Use `show_google_issue3_runner_patch_next_step.ps1` as soon as the wrapper has
already named the state. Reopen the higher-level suite-router, replay-route, or
replay-shortcuts helpers first only when you still need the broader issue `#3`
recovery surfaces reprinted beside that state-specific next command.