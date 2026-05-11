# Issue #3 Validation Artifacts

Use this after a Windows replay of:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

The recommended runner now auto-refreshes the saved handoff set under:

- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-manifest.json`
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json`
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-guide.json`
- `tmp-browser-smoke\headed-probe\google-issue3-phase-boundary.json`
- `tmp-browser-smoke\headed-probe\google-issue3-validation-artifact-bundle.json`

## Fastest next step

Run the manifest helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1
```

That helper now prints:

- whether the validation ladder completed
- whether the run failed before the first phase even started
- the first failing phase
- the most relevant JSON artifact to open next
- why that artifact was chosen
- the direct surface-check replay command when the failure happened before phase execution
- the auto-saved artifact-bundle path, status, and any recorded helper error
- the next recommended rerun command
- the matching guide command
- the saved manual fixture replay command when the failure moved into the attached-HTML follow-up

## When to use the other helpers

Use the summary guide when you want the saved summary translated into the narrowest rerun command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1
```

Use the phase-boundary helper when you want the handoff between the last passing checkpoint and the first failing checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1
```

The artifact-bundle audit is now auto-saved by the recommended runner. Rerun the helper directly only when you want to refresh that completeness check without replaying the full validation ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1
```

The artifact-bundle helper reports `stale-cross-references` when the saved manifest, guide, or boundary JSON files still point at an older summary from a previous replay.

## Suggested operator flow

1. Run the recommended validation runner.
2. Open the manifest helper output first.
3. If `Surface` is not `passed`, open the `Surface JSON` artifact first and rerun the `Surface cmd` command before looking at later phase helpers.
4. If `Bundle status` is not `complete`, reopen the current `Summary JSON` first, then run the command shown under `Run next` before trusting older handoff files.
5. Otherwise inspect the `Open next` JSON path before reading broader logs.
6. If the artifact bundle says `stale-cross-references`, treat the current summary JSON as the source of truth, rerun the command shown under `Run next`, and then refresh the helper listed under `Guide` before trusting older handoff files.
7. Replay only the command shown under `Run next`.
8. Use the summary guide or phase-boundary helper only when you need extra context around that boundary.

## Why this matters

Issue `#3` already has several narrower bounded checkpoints. The hard part on reruns is usually deciding which artifact to trust first, not generating more traces. Starting from the manifest keeps the next replay on the earliest failing checkpoint and helps avoid widening back out to the bigger Google or large-Zig-file paths too early. Surfacing the auto-saved artifact-bundle state in the same helper also makes it much harder to follow stale handoff files after a newer replay has already produced a better summary.