# Issue #3 Runner Output Patch Rules

Use this note when the current issue `#3` safe-route wrapper or patch-handoff artifact reports `ready-for-runner-patch` for `scripts/windows/run_google_issue3_recommended_validation.ps1`.

The goal is to keep the direct runner-output contract aligned with the latest helper behavior before the next Windows replay regenerates artifacts.

Pair this note with `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` and `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`.
Use the validation-chain guide to choose the next safe-route wrapper, replay state, and raw-helper reopening order.
Use the decision table when the wrapper already emitted `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs` and you want the shortest next-step command map.
Use this focused patch-rules note once the newest wrapper or patch-handoff artifact has already narrowed the replay to a direct runner patch, or when you are reviewing an existing direct runner patch by hand.

## Companion use

- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`: route selection, safe-wrapper precedence, and replay-state branching.
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`: shortest next-step command map for `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`.
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`: direct source-edit rules, artifact precedence, nullable `$null` handling, blank-path guidance, and post-patch verification.

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

## Replay state handoff

- If the newest wrapper or artifact reports `ready-for-runner-patch`, use `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` to pick the right patch-loop command path, then use this note for the field-level source edit itself.
- If it reports `already-direct`, skip the source edit and go straight back to the safe wiring audit.
- If it reports `runner-already-wired-regenerate-outputs`, use the decision table or validation-chain guide to regenerate or repair the saved outputs before trying to patch the runner again.

## Verification order

After the runner patch lands:

1. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1`
2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1`
3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1`

Only continue into the narrower refresh-status chain after the safe wiring audit says the runner-output contract is ready.
