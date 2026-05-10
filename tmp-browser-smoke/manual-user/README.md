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

Use the current attached-page folder as the page root when the run already has
saved HTML snapshots available locally.

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

## Recommended Flow

1. Pick the bounded suite for the subsystem you changed with `scripts/windows/show_headed_validation_suites.ps1`.
2. Run that suite and one nearby shared-behavior suite if the change crossed subsystems.
3. Start the saved-page localhost pass from this directory's helper flow.
4. Keep notes about which attached pages still fail and whether the failure looks like input, rendering, navigation, or storage.
5. Only move to live-site checking after the saved-page pass is stable.

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
