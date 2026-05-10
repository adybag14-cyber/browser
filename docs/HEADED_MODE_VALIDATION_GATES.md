# Headed Mode Validation Gates

This document turns the existing headed smoke directories into named gate
suites so future work can pick the right bounded validation path quickly.

Read this with:
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/FULL_BROWSER_MASTER_TRACKER.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md`
- `tmp-browser-smoke/README.md`

## How To Use This File

When a change touches one subsystem, run the smallest matching gate suite first.
If that passes, move outward only when the changed behavior crosses into another
shared subsystem.

Keep these rules:
- run the narrowest matching suite before broader regression sweeps
- prefer the probe family that exercises the real headed Win32 surface
- treat saved artifacts and logs as part of the validation result, not optional
- do not mark a slice complete unless the primary matching suite is green or the
  failure is captured with a specific blocker note

## Gate Suites

### 1. Shell And Navigation

Use when changes touch browser chrome, internal pages, tab lifecycle, popup
policy, address-bar behavior, restore, bookmarks, stop/loading recovery, or
navigation recovery.

Directories:
- `tmp-browser-smoke/tabs`
- `tmp-browser-smoke/browser-pages`
- `tmp-browser-smoke/settings`
- `tmp-browser-smoke/wrapped-link`
- `tmp-browser-smoke/popup`
- `tmp-browser-smoke/stop-loading`
- `tmp-browser-smoke/bookmarks`

Good first probes:
- `tmp-browser-smoke/tabs/chrome-tabs-probe.ps1`
- `tmp-browser-smoke/browser-pages/chrome-browser-pages-start-shell-probe.ps1`
- `tmp-browser-smoke/settings/chrome-settings-home-probe.ps1`
- `tmp-browser-smoke/wrapped-link/addressbar-probe.ps1`
- `tmp-browser-smoke/popup/chrome-popup-script-policy-probe.ps1`
- `tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1`
- `tmp-browser-smoke/bookmarks/bookmark-toggle-probe.ps1`

### 2. Rendering And Layout

Use when changes touch paint ordering, layout geometry, hit-testing parity,
screenshots, clipping, transforms, overflow, or visual composition.

Directories:
- `tmp-browser-smoke/layout-smoke`
- `tmp-browser-smoke/inline-flow`
- `tmp-browser-smoke/flow-layout`
- `tmp-browser-smoke/rendered-link-dom`

Good first probes:
- `tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1`
- `tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1`
- `tmp-browser-smoke/inline-flow/probe.ps1`
- `tmp-browser-smoke/flow-layout/probe.ps1`
- `tmp-browser-smoke/rendered-link-dom/chrome-rendered-link-dom-probe.ps1`

### 3. Text, Fonts, Editing, And Focus

Use when changes touch input delivery, caret behavior, clipboard, IME, focus
traversal, text measurement, fonts, or zoom-sensitive editing behavior.

Directories:
- `tmp-browser-smoke/form-controls`
- `tmp-browser-smoke/google-investigation-next`
- `tmp-browser-smoke/google-home`
- `tmp-browser-smoke/font-smoke`
- `tmp-browser-smoke/font-render`
- `tmp-browser-smoke/find`
- `tmp-browser-smoke/zoom`

Good first probes:
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1`
- `tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1`
- `tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1`
- `tmp-browser-smoke/form-controls/label-click-probe.ps1`
- `tmp-browser-smoke/form-controls/enter-submit-probe.ps1`
- `tmp-browser-smoke/inline-flow/chrome-inline-break-input-enter-submit-probe.ps1`
- `tmp-browser-smoke/font-render/chrome-font-render-probe.ps1`
- `tmp-browser-smoke/find/chrome-find-probe.ps1`
- `tmp-browser-smoke/zoom/chrome-zoom-probe.ps1`

### 4. Graphics And Canvas

Use when changes touch canvas 2D, WebGL, image compositing inside canvas, or
screenshot parity for graphics-heavy surfaces.

Directories:
- `tmp-browser-smoke/canvas-smoke`

Good first probes:
- `tmp-browser-smoke/canvas-smoke/chrome-canvas-render-probe.ps1`
- `tmp-browser-smoke/canvas-smoke/chrome-canvas-text-probe.ps1`
- `tmp-browser-smoke/canvas-smoke/chrome-canvas-webgl-triangle-probe.ps1`

### 5. Network, Downloads, And Resource Policy

Use when changes touch shared `Http` runtime behavior, cookies, auth, fetch,
websockets, downloads, attachments, stylesheets, scripts, or image loading.

Directories:
- `tmp-browser-smoke/image-smoke`
- `tmp-browser-smoke/stylesheet-smoke`
- `tmp-browser-smoke/fetch-abort`
- `tmp-browser-smoke/fetch-credentials`
- `tmp-browser-smoke/websocket-smoke`
- `tmp-browser-smoke/downloads`
- `tmp-browser-smoke/attachment-downloads`

Good first probes:
- `tmp-browser-smoke/image-smoke/chrome-http-runtime-image-probe.ps1`
- `tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1`
- `tmp-browser-smoke/fetch-abort/chrome-fetch-abort-probe.ps1`
- `tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1`
- `tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1`
- `tmp-browser-smoke/downloads/chrome-download-probe.ps1`
- `tmp-browser-smoke/attachment-downloads/chrome-attachment-link-probe.ps1`

### 6. Storage And Session

Use when changes touch cookies, localStorage, sessionStorage, IndexedDB,
restart restore, or shared profile behavior across tabs.

Directories:
- `tmp-browser-smoke/cookie-persistence`
- `tmp-browser-smoke/localstorage-persistence`
- `tmp-browser-smoke/indexeddb-persistence`
- `tmp-browser-smoke/sessionstorage-scope`
- `tmp-browser-smoke/bare-metal-release`

Good first probes:
- `tmp-browser-smoke/cookie-persistence/chrome-cookie-restart-probe.ps1`
- `tmp-browser-smoke/localstorage-persistence/chrome-localstorage-restart-probe.ps1`
- `tmp-browser-smoke/indexeddb-persistence/chrome-indexeddb-restart-probe.ps1`
- `tmp-browser-smoke/sessionstorage-scope/chrome-sessionstorage-same-tab-probe.ps1`
- `tmp-browser-smoke/bare-metal-release/chrome-bare-metal-persistence-probe.ps1`

### 7. Product Polish And Long-Session Checks

Use when changes touch release packaging, manual headed sessions, internal page
ergonomics, or end-to-end readiness instead of a single engine subsystem.

Directories:
- `tmp-browser-smoke/bare-metal-release`

Good first probes:
- `tmp-browser-smoke/bare-metal-release/chrome-bare-metal-start-shell-probe.ps1`
- `tmp-browser-smoke/bare-metal-release/chrome-bare-metal-tabs-session-restore-probe.ps1`

## Subsystem-To-Suite Map

- `src/display/win32_backend.zig`: start with Text, Fonts, Editing, And Focus; add Shell And Navigation when window chrome or shell commands changed
- `src/render/DocumentPainter.zig` and `src/render/DisplayList.zig`: start with Rendering And Layout; add Graphics And Canvas when canvas paint paths changed
- `src/browser/Page.zig` and `src/browser/EventManager.zig`: choose between Rendering And Layout, Text, or Shell based on whether the change affects geometry, input, or navigation lifecycle
- `src/browser/webapi/canvas/`: start with Graphics And Canvas
- `src/browser/webapi/net/`, `src/http/`, resource elements, and downloads flows: start with Network, Downloads, And Resource Policy
- persistent stores and profile wiring: start with Storage And Session
- browser pages, tab strip, settings, popup policy, address bar, bookmarks, and stop/reload flows: start with Shell And Navigation

## Probe Selection Rules

Pick the first probe that matches the specific behavior you changed, then widen
only as needed.

- single control or text-entry changes: start with one `form-controls` probe; when submit timing changed, also run the closest `inline-flow` Enter-submit probe before broader sweeps
- screenshot or visual regressions: start with one `layout-smoke` or `rendered-link-dom` probe that proves the visible surface
- auth/cookie/subresource changes: start with one targeted `image-smoke`, `stylesheet-smoke`, `fetch-credentials`, `websocket-smoke`, or `attachment-downloads` probe
- restart or persistence changes: start with the restart-oriented probe in the matching persistence directory
- shell-state changes: start with one `browser-pages`, `tabs`, `settings`, `bookmarks`, or `stop-loading` probe that exercises the changed action directly
- live-site Google search-box work: start with `scripts/windows/show_headed_validation_suites.ps1 -ChangeArea google-input` or `tmp-browser-smoke/google-investigation-next/`, then use the title or quick gate, then the reduced-homepage pass, then `scripts/windows/show_google_submit_timing_validation_flow.ps1` before the bounded timing slice, then the shared Enter-order stack, then `scripts/windows/show_google_attached_html_validation_flow.ps1` when current-run attached HTML exists, and only then move to the saved-page or live trace follow-up; use `src/browser/tests/page/google_home_title_probe.html` when the change specifically touches load or readiness ordering before moving to the full live-site pass

## Issue #3 Flow

For issue `#3`, keep the bounded follow-up order consistent across the branch:

1. `google-investigation-next`
2. `google-title` or `google-quick` when the next question is title, readiness, focus, or the first real-surface text marker
3. `google-home` or `google-recommended` when you want the reduced-homepage pass bundled with the current bounded runner
4. `scripts/windows/show_google_submit_timing_validation_flow.ps1`, then the bounded submit-timing slice
5. the shared Enter-order stack, including `scripts/windows/show_google_shared_enter_order_validation_flow.ps1` when you want the stricter localhost-first ordering printed before execution
6. `scripts/windows/show_google_attached_html_validation_flow.ps1` plus attached-page follow-up when the current run already has Google-like HTML snapshots, otherwise the saved-page follow-up
7. `scripts/windows/show_google_trace_validation_flow.ps1`
8. live Google trace or the full homepage follow-up

Use `docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md`,
`scripts/windows/show_google_input_validation_flow.ps1`, and
`scripts/windows/show_headed_validation_suites.ps1 -ChangeArea google-input`
when you need the exact command map for that sequence.

## Expected Artifacts

For Windows headed runs, keep:
- the exact probe script name that was run
- the browser build command, if the slice required a rebuild
- screenshots, logs, or downloaded artifacts produced by the probe
- the first failing observable if the suite is red

If a probe cannot be run from the current environment, record:
- which suite should have been run
- which exact script would be the first validation step
- what environment constraint prevented it

That keeps the gate decision explicit instead of implied.
