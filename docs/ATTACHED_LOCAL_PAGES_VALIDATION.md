# Attached Local Pages Validation

This helper exists so headed-mode runs can replay the three saved attached HTML pages through stable localhost routes instead of opening long saved filenames directly.

## Files

- `tmp-browser-smoke/attached-local-pages/attached_pages_server.py`

## Source Pages

Point the helper at the directory that contains these saved captures:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

If the Department of War capture has a sibling asset directory ending in `_files`, keep it in the same source directory so relative CSS, JS, and image requests can resolve.

## Start The Helper

```powershell
python .\tmp-browser-smoke\attached-local-pages\attached_pages_server.py --source-dir C:\path\to\saved\attached\pages --port 8124
```

Health and inventory:

- `http://127.0.0.1:8124/ping`
- `http://127.0.0.1:8124/manifest.json`
- `http://127.0.0.1:8124/`

Stable page routes:

- `http://127.0.0.1:8124/pages/google-safety-centre/index.html`
- `http://127.0.0.1:8124/pages/anthropic-job-application/index.html`
- `http://127.0.0.1:8124/pages/uap-war-department/index.html`

## What To Validate

Use the three routes as complementary headed checks:

- Google Safety Centre: long-scroll rendering, large inline asset pages, general navigation stability.
- Anthropic Job Application: focus movement, keyboard input, combobox-style text fields, and form-style controls.
- Department of War UAP page: button grids, modal-style flows, scripted list rendering, and optional sidecar asset loading.

## Practical Follow-Up

When a headed failure reproduces on one of these routes:

1. Capture the exact localhost route and visible failure.
2. Note whether the helper reported missing HTML or sidecar assets in `manifest.json`.
3. Narrow the failure into the relevant headed lane before reopening larger runtime files.
