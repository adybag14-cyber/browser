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
- the first failing phase
- the most relevant JSON artifact to open next
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

## Suggested operator flow

1. Run the recommended validation runner.
2. Open the manifest helper output first.
3. Inspect the `Open next` JSON path before reading broader logs.
4. Replay only the command shown under `Run next`.
5. Use the summary guide or phase-boundary helper only when you need extra context around that boundary.

## Why this matters

Issue `#3` already has several narrower bounded checkpoints. The hard part on reruns is usually deciding which artifact to trust first, not generating more traces. Starting from the manifest keeps the next replay on the earliest failing checkpoint and helps avoid widening back out to the bigger Google or large-Zig-file paths too early.
