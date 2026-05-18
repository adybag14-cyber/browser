# Headed Mode Validation Matrix

Use this guide when a headed-mode change is ready for Windows validation and you
need the smallest bounded probe family before widening into manual replay.

Read this together with:
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Working Rules

- Start with the smallest bounded localhost probe that touches the shared path you changed.
- Widen into manual `browse --headed` replay only after the bounded probe is green.
- Prefer `scripts\windows\show_headed_validation_suites.ps1` first for the change areas it already routes directly: `navigation`, `stop-loading`, `input`, `google-form-controls-enter-order`, `rendering`, `network`, `browser-shell`, `popup`, `attached-html`, `attached-html-target-bundle`, `google-input`, and `google-attached-html`.
- For probe families that are not yet first-class router change areas, use the direct PowerShell entrypoints below.
- Older deeper probe families can still carry fixed checkout assumptions. If a helper fails before browser behavior is exercised, normalize the local repo-root or browser-exe path first.
- When replay depends on saved-page exports, keep the router's strict `-RequireCompleteSidecars` and `-RequireCompleteAssets` attached-pages catalog variants in play before treating missing files as headed regressions.

## Fast Picks

| Change area | First bounded check | Good follow-up | Notes |
| --- | --- | --- | --- |
| Browser chrome navigation, history, reload | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea navigation` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\addressbar-probe.ps1` | Use for back, forward, reload, wrapped-link hit-testing, and address-bar driven transitions. |
| Stop/loading lifecycle and restore-after-stop behavior | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea stop-loading` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-close-probe.ps1` | Use when stop, cancel, reload-after-stop, or restored page state changed. |
| Shared text input, focus, label activation, Enter submit | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input` | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input` | Start here before any live Google or saved-page follow-up. |
| Google form-controls Enter submit timing on the real headed surface | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order` | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input` | Use this when issue #3 is already narrowed to the smallest shared gate that proves submit still waits until keypress before widening back to manual Google or saved-page replay. |
| Shared layout, paint, screenshot timing, or visible headed surface behavior | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1` | Start here before widening into attached-page replay for rendering or screenshot issues. |
| Shared subresource loading, authenticated asset fetches, or browser-managed request credentials | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1` | Start here before widening into attached-page replay for network, credential, or asset-loading changes. |
| Browser shell tabs, settings, and related chrome behavior | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-tabs-probe.ps1` | Use this for tab strip, duplicate/reopen, settings persistence, and shell keyboard-shortcut changes before widening into older deeper helpers. |
| Popup creation, named-target flows, or popup policy | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1` | Start here for the checkout-portable first popup proof, then use the direct popup probes below if you need deeper form-submit or script-open coverage. |
| Saved HTML compatibility bundle or attached exported pages | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath "<saved-html-or-folder>"` | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"` | Use this for exported saved-page replays, sidecar and asset audits, strict completeness checks, and the first router pass before bundle-specific narrowing. |
| Pinned three-page compatibility bundle | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"` | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"` | Use this when the replay should stay on the known three-page compatibility set and you want the compact bundle-specific helper chain surfaced immediately. |

## Pinned Bundle Fast Path

When the current replay should stay on the known three-page compatibility set,
use this shorter route instead of reopening the broader attached-page ladders by
hand:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -InputPath "<bundle-html-or-folder>" -Wait
```

Use this route when:
- the current saved pages are still the exact three-page compatibility bundle
- the next check should stay bundle-first instead of reopening the wider manual attached-page discovery path
- you want the compact suite surface, replay-route bridge, and bundle-first handoff printed together before launch

## Probe Families

### Rendering and Layout

| Subsystem | First probe | Follow-up probes |
| --- | --- | --- |
| Block/flex/overflow layout | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1` | `chrome-layout-overflow-hidden-probe.ps1`, `chrome-layout-fixed-position-probe.ps1`, `chrome-layout-responsive-image-probe.ps1` |
| Screenshot/load-complete timing on the headed surface | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1` | `chrome-screenshot-delayed-content-probe.ps1`, `chrome-screenshot-tiny-placeholder-probe.ps1` |
| Dense inline flow, mixed control rows, wrapped controls | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\inline-flow\probe.ps1` | `chrome-inline-dense-focus-probe.ps1`, `chrome-inline-wrap-flow-probe.ps1`, `chrome-inline-control-link-tab-probe.ps1` |
| Shared rendering for multiple images | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-intrinsic-image-probe.ps1` | open `tmp-browser-smoke\multi-image\index.html` in headed mode after the intrinsic-image probe passes |
| Rendered-link DOM mutation correctness | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\link-down-probe.ps1` | `hover-probe.ps1`, `blank-click-probe.ps1` |

### Text, Fonts, Zoom, and Find

| Subsystem | First probe | Follow-up probes |
| --- | --- | --- |
| Authenticated and anonymous font loading | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\font-smoke\chrome-font-auth-probe.ps1` | `chrome-font-anonymous-probe.ps1` |
| Font raster and fallback behavior | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\font-render\chrome-font-render-probe.ps1` | `chrome-private-font-fallback-probe.ps1`, `chrome-private-font-woff-probe.ps1`, `chrome-private-font-woff2-probe.ps1` |
| Button and control sizing under custom fonts | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\font-render\chrome-font-button-layout-probe.ps1` | `chrome-private-font-render-probe.ps1` |
| Zoom and post-zoom input fidelity | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\zoom\chrome-zoom-probe.ps1` | rerun the smallest matching input or layout probe after zoom-specific changes |
| Find-in-page surface correctness | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\find\chrome-find-probe.ps1` | pair with `chrome-zoom-probe.ps1` if the change touched text metrics or viewport math |

### Windows Interaction and Browser Shell

| Subsystem | First probe | Follow-up probes |
| --- | --- | --- |
| Popup creation and named-target flows | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-named-anchor-probe.ps1` |
| Popup form submit and script-open policy | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-form-enter-probe.ps1` | `chrome-popup-form-post-probe.ps1`, `chrome-popup-script-policy-probe.ps1`, `chrome-popup-script-policy-block-probe.ps1` |
| Tab strip, duplicate, reopen, session restore | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-duplicate-tab-probe.ps1` |
| Settings shell and restore policy | `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell` | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\settings\chrome-settings-restore-off-probe.ps1` |

### Storage, Network, and Web Platform

| Subsystem | First probe | Follow-up probes |
| --- | --- | --- |
| Cookies across clear, restart, and cross-tab paths | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\cookie-persistence\chrome-cookie-cross-tab-probe.ps1` | `chrome-cookie-restart-probe.ps1`, `chrome-cookie-clear-probe.ps1` |
| localStorage/sessionStorage persistence and event scope | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\localstorage-persistence\chrome-localstorage-storage-event-probe.ps1` | `chrome-localstorage-restart-probe.ps1`, `chrome-sessionstorage-same-tab-probe.ps1`, `chrome-sessionstorage-cross-tab-probe.ps1` |
| IndexedDB persistence and transactional behavior | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\indexeddb-persistence\chrome-indexeddb-cross-tab-probe.ps1` | `chrome-indexeddb-restart-probe.ps1`, `chrome-indexeddb-transaction-mode-probe.ps1`, `chrome-indexeddb-index-probe.ps1` |
| Fetch credentials and abort behavior | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1` | `chrome-fetch-abort-probe.ps1` |
| WebSocket basics | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\websocket-smoke\chrome-websocket-echo-probe.ps1` | `chrome-websocket-subprotocol-probe.ps1`, `chrome-websocket-binary-close-probe.ps1` |

### Files, Downloads, and User Data Flows

| Subsystem | First probe | Follow-up probes |
| --- | --- | --- |
| File upload picker and submit | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\file-upload\chrome-file-upload-submit-probe.ps1` | `chrome-file-upload-cancel-probe.ps1`, `chrome-file-upload-multiple-probe.ps1`, `chrome-file-upload-replace-probe.ps1` |
| Upload targets and attachment capture | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\file-upload\chrome-file-upload-target-probe.ps1` | `chrome-file-upload-target-attachment-probe.ps1`, `chrome-file-upload-attachment-probe.ps1` |
| Download creation and cleanup | `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\downloads\chrome-download-probe.ps1` | `chrome-download-delete-probe.ps1` |

## Manual Widening

After the matching bounded family is green:

1. Re-run the nearest manual headed flow with `.\zig-out\bin\lightpanda.exe browse --headed ...`.
2. For saved HTML or exported pages, use the attached-pages catalog route instead of an ad hoc `python -m http.server` whenever the branch helper can express the replay cleanly, and reuse the router's strict `-RequireCompleteSidecars` and `-RequireCompleteAssets` variants when you want localhost replay to fail fast on incomplete exports.
3. For the pinned three-page compatibility bundle, prefer the `attached-html-target-bundle` router output and the compact bundle-specific helper chain before dropping back to the broader attached-page discovery route.
4. For live Google issue work, keep the sequence bounded-input probe -> google-form-controls-enter-order gate -> manual Google replay -> attached-page follow-up.
5. If a deeper helper fails because of repo-root assumptions rather than browser behavior, fix the helper pathing before treating it as a headed regression.