# Issue #3 Runner Patch Decision Table

Use this note when the current issue `#3` replay has already narrowed to the direct runner patch loop for `scripts/windows/run_google_issue3_recommended_validation.ps1`.

Keep this note beside:
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and replay routing
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` for field-level patch rules and verification order

## Default entrypoint

For a fresh Windows replay, start here first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

That wrapper preserves the newest patch-handoff artifact and narrows the next move to one of the states below.

## State-to-next-step table

### `ready-for-runner-patch`

Meaning:
- the current replay still needs a direct source edit in `scripts/windows/run_google_issue3_recommended_validation.ps1`

Next steps:
1. Open the newest patch artifact in this order:
   - `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json`
   - `tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-handoff.json`
   - `tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-targets-safe-route.json`
   - `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-runner-output-patch-targets.json`
2. Patch both saved output objects in `scripts/windows/run_google_issue3_recommended_validation.ps1`:
   - `Write-RecommendedSummaryArtifact`
   - `Write-RecommendedManifestArtifact`
3. Keep these fields present in both objects:
   - `refresh_chain_artifact_path`
   - `refresh_chain_artifact_error`
   - `handoff_artifact_path`
   - `handoff_artifact_error`
4. Preserve nullable error fields exactly as emitted. If the snippet says `$null`, keep `$null`.
5. Re-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1
```

### `already-direct`

Meaning:
- the runner source is already carrying the direct contract fields the safe-route wrapper expected

Next steps:
1. Do not patch `scripts/windows/run_google_issue3_recommended_validation.ps1` again.
2. Reopen the safe wiring audit immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

3. Only reopen the raw wiring helper after the safe audit routes there.

### `runner-already-wired-regenerate-outputs`

Meaning:
- the source is already wired, but the saved outputs are stale or still missing the repaired contract

Next steps:
1. Treat this as an output-regeneration problem, not another direct source-edit pass.
2. Prefer the emitted repair or regeneration command from the wrapper artifact.
3. If you need the stable replay-safe default, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1
```

4. After regeneration or repair, reopen the safe wiring audit:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## Practical guardrails

- Prefer the newest wrapper artifact over older raw helper output.
- Treat blank path values as unresolved state, not as a finished direct contract.
- Keep the summary and manifest contracts aligned; patching only one object is not enough.
- Use the safe helper before the raw helper when both exist for the same checkpoint.
- Once the safe wiring audit is green, move back into the refresh-status and handoff-safe route instead of re-running the direct patch loop by default.

## After the runner patch loop is green

Continue with the next safe route rather than widening immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe_path_route.ps1
```

If the goal is to continue into attached or saved localhost HTML after the runner-output contract is ready, reopen the Google-style attached-page flow from `docs/WINDOWS_FULL_USE.md` only after the safe wiring and refresh-status helpers agree that the replay chain is ready.
