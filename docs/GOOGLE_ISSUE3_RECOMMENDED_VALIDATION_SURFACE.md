# Issue #3 Recommended Validation Surface Artifact

Use this helper when you want the issue `#3` prerequisite audit to leave a
machine-readable artifact before the full Windows headed validation ladder runs.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_surface.ps1
```

## Output

The helper saves two files under `tmp-browser-smoke\headed-probe\`:

- `google-issue3-recommended-validation-surface.json`
- `google-issue3-recommended-validation-surface.log`

The JSON artifact records:

- generation timestamp
- repo root
- checker path
- output and log paths
- pass or fail status
- checked and missing reference counts
- missing reference paths
- the full `check_google_issue3_recommended_validation_surface.ps1 -Json` payload

## When To Use It

Run this first when a Windows headed replay fails before the bounded localhost
or homepage-fixture phases begin, or when you want to compare prerequisite
surface drift across multiple issue `#3` validation runs.

If the helper fails, inspect the saved JSON and log before widening into the
larger recommended runner or any live Google trace work.
