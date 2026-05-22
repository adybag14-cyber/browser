# Headed Mode Localhost Validation

This guide is the branch-side quick ladder for validating headed mode against local HTML pages before widening into the remaining live Google issue work.

Use it when you need to confirm that a change still launches the real headed browser window, still loads local or loopback pages correctly, and still preserves the validation routes that bridge into the broader issue `#3` workflow.

## What this guide covers

- direct headed localhost launches
- command-mode inference for local and loopback HTML targets
- the current `show_headed_validation_suites.ps1` change-area routes
- the attached-pages replay ladder for saved HTML bundles
- the bounded validation bridge into the remaining Google issue flow

## Prerequisites

- Build the current branch and make sure `zig-out\bin\lightpanda.exe` exists.
- Keep the attached HTML pages in a local folder that can be served over localhost.
- Use Python's built-in HTTP server unless you already have another static local server.

Example local server:

```powershell
cd C:\path\to\saved-pages
python -m http.server 8123
```

## First-line headed checks

Run these before deeper route-specific follow-up.

1. Explicit headed localhost browse:

```powershell
.\zig-out\bin\lightpanda.exe browse --headed --window_width 1366 --window_height 900 "http://127.0.0.1:8123/attached-page.html"
```

2. Loopback command-mode inference should still resolve to `browse`:

```powershell
.\zig-out\bin\lightpanda.exe localhost:8123/attached-page.html
.\zig-out\bin\lightpanda.exe 127.0.0.1:8123/attached-page.html?case=1
```

3. Bare local HTML and XHTML paths should still resolve to `browse`:

```powershell
.\zig-out\bin\lightpanda.exe attached-page.html
.\zig-out\bin\lightpanda.exe attached-page.xhtml#focus-probe
```

4. Fully qualified remote HTML URLs should still stay on the fetch path unless a headed hint is explicit:

```powershell
.\zig-out\bin\lightpanda.exe https://example.com/attached-page.html
.\zig-out\bin\lightpanda.exe --headed https://example.com/attached-page.html
```

Expected results:

- explicit and loopback localhost targets open the native headed window
- bare local HTML and XHTML paths open the native headed window
- a remote HTML URL without a browse hint stays on the fetch path
- the same remote HTML URL with `--headed` still forces `browse`

## Validation router

The top-level router lives at:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1
```

Use `-ChangeArea` to print the smallest route that matches the work you changed.

### Core localhost routes

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea navigation
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea stop-loading
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
```

Use these first for:

- startup and navigation churn
- stop and reload recovery
- bounded form focus, label activation, and Enter-submit basics

### Product-weighted routes

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup
```

Use these when the change touched:

- layout, paint, screenshot timing, or visible headed rendering
- stylesheet or authenticated fetch behavior
- tabs, settings, or broader browser-shell surfaces
- popup creation, named-target navigation, or popup policy

## Attached-pages replay ladder

Use the attached-pages route when the local saved-page bundle matters more than a single probe page.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

Important route behavior:

- the route prints sidecar and asset audit commands first
- the catalog wrapper can print a manifest before starting the localhost replay server
- the catalog supports `-InputPath` to pin a specific saved page or bundle folder
- the catalog supports `-PreferredInitialPage` to keep one page first across replay helpers
- the route keeps the broader attached-page helper and the Google-shaped attached-page helper visible

Recommended order for saved-page replay:

1. audit sidecars
2. audit assets
3. print the manifest
4. start the catalog server
5. open the generated localhost route in headed mode

## Issue #3 bridge

The remaining live Google headed-input work is still behavior anchor issue `#3`, but the bounded localhost ladder should stay green before widening into the live site.

Use these router surfaces in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-recommended
```

What each route is for:

- `google-form-controls-enter-order`: the smallest dedicated Enter-order gate
- `google-shared-enter-order`: the broader shared Enter-order ladder between bounded probes and live Google
- `google-recommended`: the full operator-facing ladder from bounded input probes to live Google and then into the issue `#3` attached-page helpers

The `google-recommended` surface keeps these follow-ups visible on one route:

- bounded input
- dedicated Google Enter-order validation
- manual live Google browse
- broader attached-page replay
- Google-shaped attached-page replay
- issue `#3` attached-html quickstart and top-level helper routes
- bundle-suite and bundle-first follow-up helpers

## Suggested validation order by change type

- Input or focus work: `input`, then `google-form-controls-enter-order`, then `google-shared-enter-order`
- Startup or navigation work: `navigation`, `stop-loading`, then `attached-html`
- Rendering work: `rendering`, then `attached-html`
- Network or asset work: `network`, then `attached-html`
- Browser-shell or popup work: `browser-shell` or `popup`, then `attached-html`
- End-to-end Google follow-up: `google-recommended`

## Failure signals worth treating as real regressions

- localhost HTML opens on the wrong mode path instead of the native headed window
- loopback HTML stops resolving to `browse`
- the route script stops printing one of the first-line change-area families above
- the attached-pages route loses the sidecar or asset audit steps
- the Google bridge loses the dedicated Enter-order route or the issue `#3` attached-page follow-ups

When one of those fails, tighten the route back down to the smallest affected change area before widening into the next helper ladder.
