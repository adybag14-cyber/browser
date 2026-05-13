# Issue #3 Windows Validation Chain

This note captures the current bounded replay path for issue `#3` on `fork/headed-mode-foundation`.

Use it when the Windows headed validation lane needs to resume without rediscovering which helper should run next.

## Goal

Keep the next Windows replay on the newest strict-mode-safe wrapper first, preserve the current runner-patch guidance in the saved artifacts, and only reopen the stricter raw helper after the corresponding safe checkpoint reports that the saved state is ready.

## Preferred entrypoints

Use the smallest wrapper that matches the current state instead of starting from a raw helper by default.

1. Fresh replay plus final safe-route patch handoff
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```
Use this as the default fresh Windows replay entrypoint when the current issue `#3` outputs may be stale or missing and you want one command that:
- reruns the recommended validation flow
- preserves the final runner patch handoff artifact
- keeps the follow-up split between `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`

2. Top-level route plus preserved runner-patch guidance
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```
Use this when the current saved outputs are already present and you want to reopen the strict-mode-safe validation route plus preserved runner-output patch guidance without another broader replay first.

3. Summary-contract recovery plus safe-route reopen
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_summary_contract_safe_route.ps1
```
Use this when older or partially repaired saved outputs still need summary-contract cleanup before the safe route should be trusted again.

4. Fresh replay plus runner-output contract repair
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1
```
Use this when the next replay should regenerate the current outputs, normalize the runner-output contract, and immediately confirm whether the raw wiring audit is ready.

5. Fresh replay plus runner-output patch-target guidance
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
```
Use this when the next replay is likely to end in a direct runner-side patch and you want one artifact that preserves the exact patch-target lines.

6. Fresh replay plus runner-output wiring safe-route reopen
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
```
Use this when the next replay should regenerate or repair the runner-output contract and only reopen the raw wiring audit after the safe wrapper says the saved summary is ready.

## Raw runner

The underlying runner is still:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

Use it directly when you intentionally want a broader regeneration pass. In normal issue `#3` replay loops, prefer one of the wrappers above so the next-step guidance stays on the current safe route.

Notes:
- The runner writes the saved summary, manifest, bundle, handoff, and refresh artifact paths into `tmp-browser-smoke\headed-probe`.
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## When to reopen raw helpers

Only trust the stricter raw helper after its safe wrapper says the state is ready:

- `show_google_issue3_validation_manifest.ps1` after `show_google_issue3_validation_manifest_safe.ps1` reports `safe-to-run-manifest-guide`.
- `show_google_issue3_validation_handoff.ps1` after `show_google_issue3_validation_handoff_safe.ps1` reports `safe-to-run-handoff`, or after the handoff safe refresh route reports `ready-for-handoff`.
- `show_google_issue3_validation_artifact_bundle.ps1` after `show_google_issue3_validation_artifact_bundle_safe.ps1` reports `safe-to-run-existing-helper`, or after the bundle safe path route reports `ready-for-bundle-follow-up`.
- `show_google_issue3_runner_output_wiring_status.ps1` after `run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1` reports `runner-output-fully-wired`, or after the runner-output safe chain reports `ready-for-runner-output-wiring` and you intentionally want the raw helper by itself.
- `show_google_issue3_runner_output_patch_handoff.ps1` after `show_google_issue3_runner_output_patch_targets_safe_route.ps1` or `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` reports `ready-for-runner-patch`.
- `show_google_issue3_runner_output_patch_targets.ps1` only after `show_google_issue3_runner_output_patch_targets_safe.ps1` or `show_google_issue3_runner_output_patch_targets_safe_route.ps1` reports that the raw patch-target helper itself is still the next safe checkpoint.
- `show_google_issue3_runner_output_wiring_status_safe.ps1` directly when the safe-route patch-target or safe-route patch-handoff chain reports `already-direct`, instead of reopening another runner patch step first.

## If the runner-output contract still needs a patch

Stay on the wrapper and safe-route chain instead of starting from the raw patch-target helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1
```

When current outputs may be stale or missing, prefer the fresh replay handoff wrapper first. Use the show-only safe-route wrapper when you already trust the current saved outputs and only need to reopen the narrower guidance chain.

If the safe route still says the raw patch-target helper is the next safe checkpoint, let that helper be reopened through the safe-route wrapper instead of launching it by hand first.

If the safe-route patch-handoff wrapper reports `already-direct`, reopen:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

and skip the direct runner patch loop for that replay.

## When the runner source is already wired

If `show_google_issue3_runner_output_wiring_status.ps1` reports `saved-artifacts-stale-runner-already-wired`, do not patch `scripts/windows/run_google_issue3_recommended_validation.ps1` again as the first move.

Treat that status as a saved-output recovery problem instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1
```

If you need the narrower repair step without reopening the wider safe route yet, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
```

If you want one combined replay that repairs the runner-output contract and only reopens the raw wiring audit when the safe gate says the summary is ready, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
```

If `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` reports `already-direct`, go straight to the safe wiring audit. If it reports `runner-already-wired-regenerate-outputs`, follow its emitted regeneration or repair command before reopening the safe wiring audit.

Only come back to the raw runner-output wiring audit after the safe wiring helper routes there again. The goal is to regenerate or normalize the saved summary and manifest before spending another replay on a direct runner patch that is already present in source.

Patch target:
- `scripts/windows/run_google_issue3_recommended_validation.ps1`

When the top-level wrapper reports `ready-for-runner-patch`, open its combined artifact first:
- `tmp-browser-smoke\headed-probe\google-issue3-validation-safe-route-runner-patch-wrapper.json`

When the runner-output repair plus patch-target wrapper is the entrypoint, its combined artifact is:
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-runner-output-patch-targets.json`

When the safe-route patch-handoff wrapper is the entrypoint, its combined artifact is:
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json`

When the patch handoff helper is the entrypoint, its artifact is:
- `tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-handoff.json`

Use the preserved summary and manifest snippet lines from the newest wrapper or patch-handoff artifact before reopening lower-level helpers by hand.

Verify after any runner-output patch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1
```

Use the combined safe-route wrapper first when you want the repair flow and reopened raw audit state preserved in one artifact. Keep the standalone safe and raw wiring commands for narrower follow-ups when the current outputs are already trustworthy.

## Direct Runner Patch Checklist

When the runner still needs a direct contract fix, patch both saved output objects inside `scripts/windows/run_google_issue3_recommended_validation.ps1`, not just one of them.

Required direct fields in both the summary artifact and the manifest artifact:
- `refresh_chain_artifact_path`
- `refresh_chain_artifact_error`
- `handoff_artifact_path`
- `handoff_artifact_error`

Patch rules:
- Use the values emitted by `show_google_issue3_runner_output_patch_targets_safe_route.ps1`, `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`, or `show_google_issue3_runner_output_patch_handoff.ps1` instead of inventing paths.
- Keep the error fields present even when the value is empty or `$null`; the newer audits distinguish between a missing field and a recorded empty value.
- Recheck both object writers after editing. The helper-chain audits treat the summary and manifest as separate contracts.
- If the raw wiring audit reports `saved-artifacts-stale-runner-already-wired`, stop the direct patch loop and move back to output regeneration or repair instead of reapplying the same source edit.
- If the safe-route patch-handoff wrapper reports `already-direct`, skip the source patch and move straight to the safe wiring audit.

Recommended patch loop:
1. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1`.
2. If the wrapper reports `ready-for-runner-patch`, open the newest safe-route patch-handoff artifact and copy the suggested field lines for both saved output objects in `scripts/windows/run_google_issue3_recommended_validation.ps1`.
3. If the wrapper reports `already-direct`, skip the runner patch and reopen `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1`.
4. If the wrapper reports `runner-already-wired-regenerate-outputs`, follow its emitted regeneration or repair command before reopening the safe wiring audit.
5. Otherwise, if you are intentionally reusing current saved outputs, run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1` or `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1`.
6. Rerun `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1`.
7. Prefer `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1` so the safe contract wrapper reruns first and the raw audit only reopens when the saved summary is ready.
8. If you intentionally need the narrower checks by themselves, verify with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1`, then confirm with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1`.
9. Continue into `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1` only after the wiring audit reports the runner output is ready.

## Practical rule

If two helpers disagree:
- prefer the wrapper over the raw command when a wrapper already exists for that checkpoint
- prefer `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` as the default fresh replay entrypoint; use `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1` when reusing current saved outputs is intentional
- otherwise prefer the helper with `safe` in the name unless the safe helper explicitly says the raw helper is ready
- if the raw wiring audit says `saved-artifacts-stale-runner-already-wired`, prefer saved-output regeneration or repair over another direct runner patch
- if the safe-route patch-handoff wrapper says `already-direct`, go straight to the safe wiring audit
- if the safe-route patch-handoff wrapper says `runner-already-wired-regenerate-outputs`, regenerate or repair the saved outputs before another direct runner patch attempt
