# Headed Attached HTML Fixture Profiles

This note records how the current attached HTML pages should enter the headed
validation flow on `fork/headed-mode-foundation`.

Use it after the matching bounded suite is chosen. The goal is to avoid routing
every Google-branded or asset-heavy page through the wrong helper.

## Current attached pages

### Google Safety Centre snapshot

File:
- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`

Observed shape:
- title: `Control your online safety and privacy – Google Safety Centre`
- no missing sibling local assets from the saved HTML scan
- asset-heavy marketing page with many images and links
- not a Google search-box fixture and not part of the issue `#3` submit path

Recommended route:
- start with Rendering and Layout
- then use the generic attached-page localhost flow

Good first commands:
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -PreferredInitialPage 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'`

### Anthropic job-application snapshot

File:
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`

Observed shape:
- title: `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic`
- no missing sibling local assets from the saved HTML scan
- form-heavy page with many inputs, buttons, and textareas

Recommended route:
- start with Text, Fonts, Editing, And Focus
- then use the generic attached-page localhost flow

Good first commands:
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -PreferredInitialPage 'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'`

### U.S. Department of War UAP snapshot

File:
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Observed shape:
- title: `Presidential Unsealing and Reporting System for UAP Encounters | U.S. Department of War`
- missing sibling local assets in the current workspace scan: `66`
- saved page references a companion `_files/` directory that is not currently present

Recommended route:
- treat asset recovery as the first step
- do not trust a localhost replay until the missing `_files/` bundle is restored
- once the asset bundle is restored, start with Rendering and Layout or Network depending on the subsystem that changed

Good first commands:
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -SummaryOnly`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1`
- after restoring the sibling `_files/` directory:
  `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering`

## Working rule

- Use the issue `#3` Google helpers only for Google search-box or submit-order work. A Google-branded policy or marketing page is not enough by itself.
- When an attached page has missing sibling assets, run the summary or flow helper first and restore the local asset bundle before interpreting the headed localhost result as an engine regression.
- Prefer `show_attached_html_validation_flow.ps1` for mixed attached-page sets and `show_google_attached_html_validation_flow.ps1` only when the current set truly includes a Google-style search fixture.
