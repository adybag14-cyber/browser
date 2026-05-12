# Issue #3 Windows Validation Chain

This note captures the current bounded replay path for issue `#3` on `fork/headed-mode-foundation`.

Use it when the Windows headed validation lane needs to resume without rediscovering which helper should run next.

## Goal

Keep the next Windows replay on the newest strict-mode-safe helper first, and only reopen the stricter raw helper after the corresponding safe checkpoint reports that the saved state is ready.

## Starting point

Run the main replay first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

Notes:
- The runner now writes the saved summary, manifest, bundle, handoff, and refresh artifact paths into `tmp-browser-smoke\headed-probe`.
- When Google-style attached HTML fixtures are present in the configured search roots, the runner auto-detects them and keeps the manual follow-up on that local fixture set.

## Safe-first checkpoints

Use these helpers before reopening narrower raw audits:

1. Summary and artifact health
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle_safe_path_route.ps1
```

2. Manifest and handoff routing
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1
```

3. Runner-output contract and wiring
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## When to reopen raw helpers

Only trust the stricter raw helper after its safe wrapper says the state is ready:

- `show_google_issue3_validation_manifest.ps1` after `show_google_issue3_validation_manifest_safe.ps1` reports `safe-to-run-manifest-guide`.
- `show_google_issue3_validation_handoff.ps1` after `show_google_issue3_validation_handoff_safe.ps1` reports `safe-to-run-handoff`, or after the handoff safe refresh route reports `ready-for-handoff`.
- `show_google_issue3_validation_artifact_bundle.ps1` after `show_google_issue3_validation_artifact_bundle_safe.ps1` reports `safe-to-run-existing-helper`, or after the bundle safe path route reports `ready-for-bundle-follow-up`.
- `show_google_issue3_runner_output_wiring_status.ps1` after the runner-output safe chain reports `ready-for-runner-output-wiring`.

## If the runner-output contract still needs a patch

Use the patch-target route instead of guessing field values:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1
```

Patch target:
- `scripts/windows/run_google_issue3_recommended_validation.ps1`

Verify after any runner-output patch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1
```

## Direct Runner Patch Checklist

When the runner still needs a direct contract fix, patch both saved output objects inside `scripts/windows/run_google_issue3_recommended_validation.ps1`, not just one of them.

Required direct fields in both the summary artifact and the manifest artifact:
- `refresh_chain_artifact_path`
- `refresh_chain_artifact_error`
- `handoff_artifact_path`
- `handoff_artifact_error`

Patch rules:
- Use the values emitted by `show_google_issue3_runner_output_patch_targets_safe_route.ps1` or `show_google_issue3_runner_output_patch_targets.ps1` instead of inventing paths.
- Keep the error fields present even when the value is empty or `$null`; the newer audits distinguish between a missing field and a recorded empty value.
- Recheck both object writers after editing. The helper-chain audits treat the summary and manifest as separate contracts.

Recommended patch loop:
1. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1`.
2. Apply the suggested field lines to both saved output objects in `scripts/windows/run_google_issue3_recommended_validation.ps1`.
3. Rerun `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1`.
4. Verify with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1`.
5. Confirm the raw audit with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1`.
6. Continue into `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1` only after the wiring audit reports the runner output is ready.

## Practical rule

If two helpers disagree, prefer the one with `safe` in the name unless the safe helper explicitly says the raw helper is ready.
