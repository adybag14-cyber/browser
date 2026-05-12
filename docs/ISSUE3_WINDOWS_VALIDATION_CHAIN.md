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

## Practical rule

If two helpers disagree, prefer the one with `safe` in the name unless the safe helper explicitly says the raw helper is ready.
