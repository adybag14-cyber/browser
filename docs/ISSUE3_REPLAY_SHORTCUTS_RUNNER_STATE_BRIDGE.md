# Issue #3 Replay-Shortcuts Runner-State Bridge

Use this note when `show_google_issue3_replay_shortcuts.ps1` is already the current helper surface, but the next useful move depends on runner state rather than another attached-page routing note.

Keep these companion notes nearby:
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`

## Goal

Start from `show_google_issue3_replay_shortcuts.ps1`, then choose between a fresh safe-route replay, a reuse-current-outputs wrapper, or the exact runner-state helper without reopening the broader attached-page, Windows-first, or replay-route notes first.

## Default fresh replay

Use this route when current issue `#3` outputs may be stale or missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when:
- the current replay outputs may be stale, partial, or missing
- you want a fresh handoff artifact before choosing a narrower runner-patch or direct-edit path
- the wider attached-page route is already understood and the next decision is about replay state, not rediscovering navigation notes

## Reuse current outputs

Use this route when a saved summary already exists and those outputs are still trusted:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1 -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -SummaryPath '<saved-summary-path>' -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -SummaryPath '<saved-summary-path>'
```

Use that route when:
- a saved `SummaryPath` already points at current outputs
- you want to reuse the present replay state instead of regenerating it
- the next move depends on the reported runner state more than on another routing surface

## Preserve repo-root context

If the replay is already running from a non-default checkout, keep that same repo-root context attached to the runner-state helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

Use that context-preserving form when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current outputs for that checkout
- you want the runner-state helper to stay grounded in the same replay context before choosing a narrower patch path

## Bundle guard

If explicit `InputPath` values are already pinned to the known three-page compatibility bundle, keep the replay on the bundle-first path before widening into the safe-route runner helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle guard when:
- explicit `InputPath` values are already pinned to the known three-page compatibility set
- the next useful decision depends on whether that same bundle still reproduces the current issue `#3` state
- you do not want the safe-route wrappers to widen the replay before the pinned bundle branch is checked

## Pick the runner-state helper quickly

1. `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`

Use this when outputs may be stale or missing and you want one command to regenerate the current handoff artifact.

2. `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1`

Use this when a saved `SummaryPath` already exists and the current outputs are still trusted.

3. `show_google_issue3_runner_patch_next_step.ps1 -State ...`

Use this when the replay has already named the exact runner state and you want the narrowest next-step command surface.

4. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the route is ready to reopen the wrapper-heavy issue `#3` command map after the runner-state choice is clear.

## Practical rule

Only widen back into the broader replay-route, attached-page, or Windows-first note families when the runner-state helper is no longer enough.

- fresh outputs needed: use the fresh safe-route replay first, then the runner-state helper
- saved outputs already trusted: use the wrapper first, then the runner-state helper
- explicit bundle inputs already pinned: stay on the bundle-first branch until the bundle run clarifies the next replay state
- runner state already known: jump straight to `show_google_issue3_runner_patch_next_step.ps1`
- wrapper-heavy route truly needed again: reopen `show_google_issue3_safe_route_entrypoints.ps1` only after the narrower runner-state decision is made
