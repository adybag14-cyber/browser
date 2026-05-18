# Attached HTML Complete-Bundle Fail-Fast Surface

Use this helper when an attached-pages replay should stop immediately on either missing sidecar folders or missing local assets before headed localhost debugging starts.

Helper:
- `scripts/windows/show_attached_html_complete_bundle_fail_fast.ps1`

## What it prints

The helper prints these commands on one surface:

- sidecar audit
- asset audit
- plain manifest
- strict manifest with both `-RequireCompleteSidecars` and `-RequireCompleteAssets`
- strict localhost catalog launch with both completeness flags
- the matching `browse --headed` catalog command

## Typical use

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_complete_bundle_fail_fast.ps1 -InputPath "<saved-html-or-folder>"
```

Use `-GoogleStyle` when the attached-page replay should keep the strongest Google-like saved page first during auto-discovery.

## Practical rule

Run the sidecar audit first, run the asset audit second, then switch to the strict manifest or strict catalog command once both audits pass. That keeps incomplete bundles from sliding into headed replay as fake browser regressions.
