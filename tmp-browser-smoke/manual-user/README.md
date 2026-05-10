# Manual User Validation

This directory is the follow-up path for real saved pages after the bounded
headed suites are green.

Use it for:

- attached or saved `.html` pages that should be served on localhost
- manual headed checks that need the real Win32 surface instead of a pure DOM
  or screenshot-only check
- issue slices where the reduced probe is green and the next question is
  whether the same behavior holds on a more realistic page snapshot

Do not start here when a narrower `tmp-browser-smoke/` suite already exists for
what you changed. Run the smallest bounded suite first.

## Quick Start

Serve a directory of saved pages and open the first page in headed mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -LaunchBrowser `
  -Wait
```

Choose a specific page first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -InitialPage subdir\page.html `
  -LaunchBrowser `
  -Wait
```

Stage mixed saved files or folders into one clean localhost run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_staged_localhost_html_validation.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -LaunchBrowser `
  -Wait
```

Inventory a saved-page directory before you choose the first page to open:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\summarize_localhost_html_pages.ps1 `
  -PageRoot C:\path\to\saved-pages
```

Use the current attached-page folder as the page root when the run already has
saved HTML snapshots available locally. Use the staged wrapper when the run has
a mix of standalone HTML files and saved-page folders or when you want a
per-run manifest of exactly which HTML files were served.

## What The Helper Records

`start_localhost_html_validation.ps1` writes the session summary and server logs
under:

- `tmp-browser-smoke\manual-user\localhost-html-validation\`

That session record includes:

- the page root that was served
- the initial page and URL
- the full list of discovered HTML pages
- the server PID
- the browser PID when `-LaunchBrowser` is used
- the stdout and stderr log paths for the local server

`start_staged_localhost_html_validation.ps1` also writes
`staged-input-manifest.json` inside the staged page root that it prepares for
each run.

`summarize_localhost_html_pages.ps1` writes a JSON summary under the same
artifact root with:

- page titles when present
- URL-safe relative paths for localhost serving
- a simple interactive score to help pick the first manual follow-up page
- lightweight counts for forms, inputs, buttons, textareas, links, scripts,
  iframes, images, canvas, and `contenteditable`
- `recommended_bounded_suites` for each saved page so you can run the closest
  `tmp-browser-smoke/` gate before the manual follow-up
- `overall_recommended_suites` for the full saved-page set when several files
  or folders should be covered together
- `manual_follow_up_suite` and `next_step` guidance for the localhost pass

## Recommended Flow

1. Pick the bounded suite for the subsystem you changed with `scripts/windows/show_headed_validation_suites.ps1`.
2. Run that suite and one nearby shared-behavior suite if the change crossed subsystems.
3. If the saved pages are spread across several files or folders, stage them first with `start_staged_localhost_html_validation.ps1`.
4. Run `summarize_localhost_html_pages.ps1` when you need a quick inventory, a suggested first page, or a recommended bounded-suite set for the saved HTML pages.
5. Run one or two of the suggested bounded suites from the summary JSON before you start the localhost manual pass.
6. Start the saved-page localhost pass from this directory's helper flow.
7. Keep notes about which attached pages still fail and whether the failure looks like input, rendering, navigation, or storage.
8. Only move to live-site checking after the saved-page pass is stable.

## Google-Style Input Work

If the issue is headed Google-style typing or Enter-submit behavior:

1. run `google-investigation-next/`
2. use `scripts/windows/watch_headed_probe.ps1` against the reduced homepage probe
3. then use `start_localhost_html_validation.ps1` for any saved HTML snapshots
4. finish with the smallest live-site pass that proves the same behavior

## Useful Flags

- `-Port 8124` uses a different localhost port
- `-Host 0.0.0.0` exposes the same saved pages to another device on the LAN
- `-LeaveServerRunning` keeps the server alive after the wait prompt
- omit `-LaunchBrowser` when you only want the localhost URLs and logs first
- `start_staged_localhost_html_validation.ps1 -InputPath <file-or-folder>, <file-or-folder>` stages a mixed saved-page set into one clean localhost root before the normal helper runs
- `-InitialPage C:\path\to\saved-page.html` works with the staged wrapper when you want a specific source file to open first
- `summarize_localhost_html_pages.ps1 -PageRoot <saved-page-dir> -Port 8124` lets the saved-page inventory reflect a non-default localhost port before you launch the browser
