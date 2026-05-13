# Issue #3 Repo-Root Safe Replay

Use this note when the current issue `#3` replay is running from a non-default Windows checkout and the saved summary or helper artifacts should stay tied to that exact tree.

## Why this exists

Recent issue `#3` safe-route helpers now accept `-RepoRoot` or honor `LIGHTPANDA_REPO_ROOT`, but the replay chain is easier to misuse when a Windows run falls back to the default checkout discovery path.

This note keeps the alternate-checkout route small and explicit:
- point the helper chain at the intended repo root
- keep the same `SummaryPath` once the replay has already produced a current summary
- prefer the safe wrappers before the older raw helpers

## Default fresh replay from an alternate checkout

Set the repo root once and start with the newest safe-route handoff wrapper:

```powershell
$repoRoot = 'C:\path\to\browser'
$summaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'

powershell -NoProfile -ExecutionPolicy Bypass -Command "`$env:LIGHTPANDA_REPO_ROOT = '$repoRoot'; & '.\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -SummaryPath '$summaryPath'"
```

Use this as the default fresh replay entrypoint when the current issue `#3` outputs may be stale or missing.

## Reopen the current safe-route state without a broader rerun

If the saved outputs are already current and you only want to reopen the narrowed guidance:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1 -RepoRoot $repoRoot -SummaryPath $summaryPath
```

## Repo-root-aware safe follow-up commands

Keep the same `RepoRoot` and `SummaryPath` when the replay narrows into the newer safe checkpoints:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1 -RepoRoot $repoRoot -SummaryPath $summaryPath
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1 -RepoRoot $repoRoot -SummaryPath $summaryPath
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1 -RepoRoot $repoRoot -SummaryPath $summaryPath
```

These helpers are the safest way to keep the replay on the selected checkout once the branch has already emitted current artifacts.

## Status-to-next-step quick map

### `ready-for-runner-patch`

- Open the newest safe-route patch-handoff artifact under:
  - `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json`
- Keep `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` and `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` open.
- Apply the preserved snippet lines to `scripts/windows/run_google_issue3_recommended_validation.ps1`.

### `already-direct`

- Do not patch the runner again.
- Reopen the safe wiring audit with the same repo root and summary path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1 -RepoRoot $repoRoot -SummaryPath $summaryPath
```

### `runner-already-wired-regenerate-outputs`

- Treat the replay as a saved-output regeneration problem, not another direct source edit.
- Prefer the emitted repair or regeneration command from the wrapper artifact.
- After that rerun, reopen the same safe wiring audit with `-RepoRoot` and `-SummaryPath` preserved.

## Practical rules

- Prefer `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` as the fresh replay entrypoint for alternate-checkout runs.
- Prefer the safe helper with `-RepoRoot $repoRoot -SummaryPath $summaryPath` over a raw helper that rediscovers paths.
- Keep the same summary path all the way through the safe wiring, refresh, and handoff checkpoints.
- Reopen older raw helpers only after the corresponding safe helper says that checkpoint is ready.

## Keep These Notes Open

- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
