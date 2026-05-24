# Windows Headed Probe Suites

Use `scripts/windows/run_headed_probe_suite.ps1` as the shared entry point for
headed Win32 smoke validation.

## Quick start

List supported suite names:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_headed_probe_suite.ps1 -List
```

Run the text and input acceptance family:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_headed_probe_suite.ps1 -Suite phase2-text-input
```

Run two suites and keep going after the first failure:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_headed_probe_suite.ps1 -Suite browser-shell,phase1-rendering -ContinueOnError -PassThru
```

Run an explicit probe glob instead of a named suite:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_headed_probe_suite.ps1 -Probe "tmp-browser-smoke\zoom\*probe.ps1"
```

## Suite map

- `browser-shell`
  - `tmp-browser-smoke\tabs`
  - `tmp-browser-smoke\browser-pages`
  - `tmp-browser-smoke\settings`
  - `tmp-browser-smoke\wrapped-link`
  - `tmp-browser-smoke\popup`
- `phase1-rendering`
  - `tmp-browser-smoke\layout-smoke`
  - `tmp-browser-smoke\inline-flow`
  - `tmp-browser-smoke\flow-layout`
  - `tmp-browser-smoke\rendered-link-dom`
  - `tmp-browser-smoke\image-smoke`
  - `tmp-browser-smoke\font-render`
- `phase2-text-input`
  - `tmp-browser-smoke\form-controls`
  - `tmp-browser-smoke\font-smoke`
  - `tmp-browser-smoke\font-render`
  - `tmp-browser-smoke\find`
  - `tmp-browser-smoke\zoom`
- `files-and-downloads`
  - `tmp-browser-smoke\file-upload`
  - `tmp-browser-smoke\downloads`
  - `tmp-browser-smoke\attachment-downloads`
- `storage-and-session`
  - `tmp-browser-smoke\cookie-persistence`
  - `tmp-browser-smoke\localstorage-persistence`
  - `tmp-browser-smoke\indexeddb-persistence`
  - `tmp-browser-smoke\sessionstorage-scope`
- `network-runtime`
  - `tmp-browser-smoke\fetch-abort`
  - `tmp-browser-smoke\fetch-credentials`
  - `tmp-browser-smoke\websocket-smoke`
  - `tmp-browser-smoke\stylesheet-smoke`
- `graphics`
  - `tmp-browser-smoke\canvas-smoke`
- `release-gates`
  - combines the browser-shell, rendering, text/input, files/downloads,
    storage/session, network/runtime, and graphics suites
- `bare-metal-release`
  - `tmp-browser-smoke\bare-metal-release`

## Routing guide

- Browser chrome, tabs, address bar, popup, or internal page changes:
  `browser-shell`
- Rendering, layout, flow, image, or font placement changes:
  `phase1-rendering`
- Text entry, focus, caret, editing, find, or zoom changes:
  `phase2-text-input`
- Upload, download, or attachment changes:
  `files-and-downloads`
- Cookie, storage, restart, or session restore changes:
  `storage-and-session`
- Fetch, websocket, stylesheet, or runtime network-policy changes:
  `network-runtime`
- Canvas or WebGL changes:
  `graphics`
- Release-candidate validation:
  `release-gates`

## Focused follow-up

When `browser-shell` or popup work fails its first suite pass, switch to the
bounded follow-up ladders in `docs/HEADED_BROWSER_SHELL_POPUP_VALIDATION.md`
instead of jumping straight to a large manual headed replay.

For browser-shell changes, start here after the suite-level route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-start-shell-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-tabs-recovery-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-home-restore-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\browser-pages\chrome-browser-pages-title-fidelity-probe.ps1
```

For popup-path changes, reopen the popup-specific router surface first, then
choose the smallest direct proof that matches the symptom:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-named-anchor-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-enter-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-script-policy-block-probe.ps1
```

Keep the full browser-shell and popup ladder in the companion guide nearby when
work touches restore, reopen, settings persistence, named targets, popup
policy, or launcher callbacks, because those routes are deliberately narrower
than the broad suite runner.
