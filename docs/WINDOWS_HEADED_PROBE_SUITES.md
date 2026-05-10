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
