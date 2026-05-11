# Headed Localhost Validation

Use this guide when you want a repeatable Windows headed-mode check against a
directory of saved local HTML pages.

## Goal

Smoke-test the current headed browser against exported compatibility pages
before moving on to deeper real-site debugging.

## Inputs

- a Windows build of `lightpanda.exe`
- a directory that contains one or more top-level `.html` files
- optional sibling asset folders that the saved pages already reference

## Command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_headed_local_page_suite.ps1 -PagesRoot C:\path\to\headed-pages
```

Useful options:

- `-PageNames page-one.html,page-two.html,page-three.html`
- `-BrowserExe .\zig-out\bin\lightpanda.exe`
- `-Port 38421`
- `-WindowWidth 1366 -WindowHeight 768`

## What the script does

1. Starts a localhost Python server rooted at `PagesRoot`.
2. Opens each selected page in headed `browse`.
3. Waits for a native window or non-empty screenshot artifact.
4. Captures per-page stdout, stderr, screenshot, and JSON results.
5. Writes an overall suite summary to `tmp-browser-smoke\local-page-suite\suite-result.json`.

## Output layout

The suite writes under:

`tmp-browser-smoke\local-page-suite\`

Each page gets its own folder with:

- `headed.png`
- `browser.stdout.txt`
- `browser.stderr.txt`
- `result.json`
- `profile\`

## Recommended use

Run this first for the three attached localhost compatibility pages. If one
page fails, keep its output folder and move next into the narrower bounded
headed probe that best matches the failure mode.
