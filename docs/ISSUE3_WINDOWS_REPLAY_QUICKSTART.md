# Issue #3 Windows Replay Quickstart

Use this note when you want the shortest current replay path for issue `#3` on `fork/headed-mode-foundation` without reopening the longer routing notes first.

Keep these companion notes nearby when the replay needs more detail:
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md`

## One-command entrypoints map

Use this helper when you want the current issue `#3` safe-route commands printed in one place before choosing the next replay step:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

If the replay is running from a non-default checkout or from an already-saved summary, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

Use this when you want the helper to print the current:
- fresh replay command
- reuse-current-outputs command
- refresh-status safe-path route
- handoff-safe helper
- summary-guide safe helper
- runner-wiring safe helper

## Default fresh replay

Start here when current issue `#3` outputs may be stale or missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

Why this is the default:
- reruns the recommended issue `#3` validation flow
- preserves the newest runner-patch handoff artifact
- narrows the next move to one of three states instead of reopening the full helper chain by hand

## If the current saved outputs are already trustworthy

Use this reopen-only wrapper instead of a fresh replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```

Use this only when you intentionally want to reuse the current saved outputs and reopen the safe-route guidance without another broader run first.

## State to next move

### `ready-for-runner-patch`

Meaning:
- the replay still needs a direct edit in `scripts/windows/run_google_issue3_recommended_validation.ps1`

Do this next:
1. Open `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json` first.
2. Patch both saved output writers in `scripts/windows/run_google_issue3_recommended_validation.ps1`.
3. Keep these fields present in both objects:
   - `refresh_chain_artifact_path`
   - `refresh_chain_artifact_error`
   - `handoff_artifact_path`
   - `handoff_artifact_error`
4. Re-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1
```

### `already-direct`

Meaning:
- the runner source already carries the direct contract fields that the wrapper expected

Do this next:
- do not patch `scripts/windows/run_google_issue3_recommended_validation.ps1` again
- reopen the safe wiring audit immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

### `runner-already-wired-regenerate-outputs`

Meaning:
- the source is already wired, but the saved outputs still need regeneration or repair

Do this next:
1. Treat it as an output-refresh problem, not another direct source edit.
2. Prefer the emitted repair command from the wrapper artifact.
3. If you want the stable default repair route, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## After the runner-output contract is green

Continue with the next safe route instead of widening immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe_path_route.ps1
```

If the refresh and wiring helpers agree that the chain is ready, only then widen into the attached or saved localhost HTML follow-up from `docs/WINDOWS_FULL_USE.md`.

## Repo-root note

If the replay is running from a non-default checkout, keep `LIGHTPANDA_REPO_ROOT` and the current summary path aligned through the safe wrappers. Use `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md` before reopening the runner-output or refresh-status checkpoints when the working tree location changed.
