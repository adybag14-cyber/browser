# Issue #3 Artifact-Path Safe Route

Use this note when the saved issue `#3` validation outputs are old enough that one or more artifact-path fields may be missing from the summary or manifest.

## Entry command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_artifact_paths_safe_route.ps1
```

## What it does

The wrapper runs these checkpoints in order:

1. `repair_google_issue3_validation_artifact_paths.ps1`
2. `run_google_issue3_recommended_validation_repair_summary_contract_safe_route.ps1`

That keeps the replay on the current safe route instead of making the next Windows pass stop for a manual artifact-path repair first.

## When to use it

Use this wrapper when:
- the summary-safe helper points to missing artifact-path fields
- older saved issue `#3` outputs were copied forward from an earlier helper chain
- the next replay should normalize saved paths before trusting the narrower summary-contract safe route again

## Output artifact

The wrapper writes a combined artifact at:

`tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-artifact-paths-safe-route.json`

Open that artifact first before widening back out to broader issue `#3` helpers.
