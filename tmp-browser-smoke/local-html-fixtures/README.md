# Local HTML Fixture Probe

Use `chrome-local-html-fixture-probe.ps1` to stage saved HTML pages behind a
localhost server, open each page in headed `browse`, capture screenshots, and
confirm the native window title matches the page `<title>`.

This helper is for saved local pages that are richer than the existing focused
probe fixtures, including pages exported from real sites for manual headed-mode
triage.

Read-first helpers:

- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_local_html_fixture_validation_flow.ps1 -InputPath '<saved-html-or-folder>'`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1 -InputPath '<saved-html-or-folder>'`

Expected companion assets:

- if a saved page has a sibling `<page-base>_files/` directory, the probe
  stages it automatically beside the copied HTML file

Outputs:

- `output/fixture-results.json`
- one screenshot per staged fixture under `output/`
- browser and server stdout/stderr logs under `output/`
