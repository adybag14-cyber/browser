# Headed Local Page Compatibility

This runbook adds a repeatable headed validation step for saved local HTML
pages that do not already live inside the repository.

Use it when you need to check whether the current headed browser can open and
navigate a small set of captured pages, such as the attached compatibility
targets used in autonomous runs.

## What It Covers

- starts a localhost server for an arbitrary directory of saved `.html` pages
- exposes a stable `/manifest.json` with derived titles and slugs
- drives the headed browser across every saved page by address-bar navigation
- asserts that each page reaches its expected title in the real Win32 window

This does not replace deeper visual or interaction probes. It is the first
gate for "does the page open, stay alive, and surface the right document
title under headed execution?"

## Files

- `tmp-browser-smoke/local-pages/saved_pages_server.py`
- `tmp-browser-smoke/local-pages/chrome-local-pages-title-probe.ps1`

## Expected Inputs

- a Windows build of `zig-out/bin/lightpanda.exe`
- a directory of saved `.html` pages
- Python on `PATH`

The saved pages can come from any folder. The probe does not require the pages
to be committed into the repo.

## Example

```powershell
Set-Location C:\Users\adyba\src\lightpanda-browser

.\tmp-browser-smoke\local-pages\chrome-local-pages-title-probe.ps1 `
  -PagesRoot C:\Users\adyba\saved-headed-pages
```

## Output

The probe prints JSON with:

- whether the localhost server became ready
- how many pages were discovered
- the expected title and observed title for each page
- the first page that failed, if any

## How To Use It In Headed Work

1. Put the current compatibility target pages in one folder.
2. Run the probe before and after a headed-mode change.
3. Treat a title mismatch or early browser exit as a compatibility regression
   until proven otherwise.
4. Pair this probe with a narrower interaction or screenshot probe when the
   saved page opens successfully but still behaves incorrectly.

## Current Limits

- the probe only checks navigation and final title, not visual fidelity
- pages that depend on missing sidecar assets may still load with degraded
  presentation
- if a saved page mutates the title very late, the default wait window may need
  to be increased for that case
