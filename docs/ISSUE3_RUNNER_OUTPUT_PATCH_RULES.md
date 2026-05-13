# Issue #3 Runner Output Patch Rules

Use this note when the current issue `#3` safe-route wrapper or patch-handoff artifact reports `ready-for-runner-patch` for `scripts/windows/run_google_issue3_recommended_validation.ps1`.

The goal is to keep the direct runner-output contract aligned with the latest helper behavior before the next Windows replay regenerates artifacts.

## Patch target

- `scripts/windows/run_google_issue3_recommended_validation.ps1`

Patch both saved output objects inside the runner, not just one of them:

- the summary artifact object written by `Write-RecommendedSummaryArtifact`
- the manifest artifact object written by `Write-RecommendedManifestArtifact`

## Required fields in both objects

- `refresh_chain_artifact_path`
- `refresh_chain_artifact_error`
- `handoff_artifact_path`
- `handoff_artifact_error`

## Rules

- Copy the preserved summary and manifest snippet lines from the newest safe-route patch artifact instead of rewriting the field list by hand.
- Keep nullable error fields nullable. If the preserved snippet line uses `$null`, keep `$null` and do not replace it with `''`.
- Only use an empty string when the emitted snippet line explicitly does so.
- Treat blank path values as unresolved state, not as a finished direct contract.
- Keep the path and error fields present in both output objects so later audits do not have to recover them indirectly from other artifacts.

## Preferred artifact order

Use the newest artifact that already narrowed the replay to a direct runner patch:

1. `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json`
2. `tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-handoff.json`
3. `tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-targets-safe-route.json`
4. `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-runner-output-patch-targets.json`

If the newest artifact reports `already-direct`, skip the source edit and go straight back to the safe wiring audit.

If it reports `runner-already-wired-regenerate-outputs`, regenerate or repair the saved outputs before trying to patch the runner again.

## Verification order

After the runner patch lands:

1. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1`
2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1`
3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1`

Only continue into the narrower refresh-status chain after the safe wiring audit says the runner-output contract is ready.
