# Issue #3 Validation Artifacts

Use this after a Windows replay of:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

The recommended runner now leaves a small artifact bundle under:

- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-manifest.json`
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json`
- `tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-guide.json`
- `tmp-browser-smoke\headed-probe\google-issue3-phase-boundary.json`

## Fastest next step

Run the manifest helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1
```

That helper prints:

- whether the validation ladder completed
- whether the run failed before the first phase even started
- the first failing phase
- the most relevant JSON artifact to open next
- why that artifact was chosen
- the direct surface-check replay command when the failure happened before phase execution
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

Use the artifact-bundle helper when you want a completeness and freshness audit across the saved summary, manifest, guide, boundary, and per-phase artifacts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1
```

The artifact-bundle helper now reports `stale-cross-references` when the saved manifest, guide, or boundary JSON files still point at an older summary from a previous replay.

## Suggested operator flow

1. Run the recommended validation runner.
2. Open the manifest helper output first.
3. If `Surface` is not `passed`, open the `Surface JSON` artifact first and rerun the `Surface cmd` command before looking at later phase helpers.
4. Otherwise inspect the `Open next` JSON path before reading broader logs.
5. If the artifact bundle says `stale-cross-references`, treat the current summary JSON as the source of truth, rerun the command shown under `Run`, and then refresh the helper listed under `Guide` before trusting older handoff files.
6. Replay only the command shown under `Run next`.
7. Use the summary guide or phase-boundary helper only when you need extra context around that boundary.

## Why this matters

Issue `#3` already has several narrower bounded checkpoints. The hard part on reruns is usually deciding which artifact to trust first, not generating more traces. Starting from the manifest keeps the next replay on the earliest failing checkpoint and helps avoid widening back out to the bigger Google or large-Zig-file paths too early. The new stale-reference warning also helps prevent a later replay from following helper JSON that was generated from an older summary.