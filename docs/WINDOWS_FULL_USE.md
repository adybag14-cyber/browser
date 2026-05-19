# Lightpanda Full Use on Windows (Fork)

This fork now has:

- Runtime browser mode switch (`--browser_mode headless|headed`)
- Runtime viewport controls (`--window_width`, `--window_height`)
- CDP viewport controls (`Emulation.setDeviceMetricsOverride`, `Emulation.clearDeviceMetricsOverride`, `Browser.setWindowBounds`)

## 1) Check Windows prerequisites

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_lightpanda_windows_prereqs.ps1
```

If `SymlinkCreate` fails, enable Windows Developer Mode and reopen your shell.
Without symlink capability, Zig dependency unpacking can fail (`depot_tools`).
`DeveloperMode` can still show `FAIL` if symlink creation already works in your
current shell context.

## 2) Build options

1. Native Windows build:
- Works only when symlink creation is available in the current shell.
- Then run normal build commands (for example `zig build run -- help`).

2. WSL build (recommended fallback):
- Build and run from WSL where symlink behavior is reliable.
- Connect automation clients from Windows host to the WSL endpoint.
- Before blaming the browser source for Linux-side `zig build` failures, stage
  the branch's sibling-path dependencies first:
  - keep the repo beside `../zig-v8-fork` and `../boringssl-zig`
  - if you are using the saved dependency bundles, extract them so both
    sibling paths exist before running Zig
  - keep the bundled `brotli`, `zlib`, `nghttp2`, and `curl` tarballs nearby
    for the offline cache or throwaway path-rewrite step
  - treat `403` fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl` as
    an offline dependency-staging miss first, because `build.zig.zon` still
    points those packages at GitHub URLs
  - retry with explicit cache dirs before assuming a headed-mode regression:
    `zig build --help`
    `zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover`

## 3) Runtime usage examples

CLI:

```powershell
.\lightpanda.exe serve --browser_mode headed --window_width 1366 --window_height 768 --host 127.0.0.1 --port 9222
```

CDP viewport override:

- `Emulation.setDeviceMetricsOverride`
- `Emulation.clearDeviceMetricsOverride`
- `Browser.setWindowBounds` with width/height

## 4) Current headed status

`headed` mode now has a native Windows window lifecycle backend:

- window open/close with page lifecycle
- native Win32 message pump on a dedicated thread
- viewport resize wiring from CLI and CDP metrics/window-bounds APIs
- native mouse (down/up/move/wheel/hwheel), click, keydown/keyup, text input (`WM_CHAR`/`WM_UNICHAR`), IME result/preedit composition messages (`WM_IME_COMPOSITION`), back/forward mouse buttons, and window blur wired into page input handling
- native key repeat state is propagated to `KeyboardEvent.repeat`
- text controls now keep insertion at the active caret/selection and support `Ctrl/Meta + A` select-all
- text controls also support word-wise keyboard editing (`Ctrl/Meta + ArrowLeft/ArrowRight`, `Ctrl/Meta + Backspace/Delete`)
- textareas now support vertical and line-aware caret movement (`ArrowUp/ArrowDown`, line-aware `Home/End`, document `Ctrl/Meta + Home/End`)
- keyboard focus traversal now supports `Tab` / `Shift+Tab` with `tabindex` ordering
- native clipboard shortcuts are wired for text controls (`Ctrl/Meta + C/X/V`, `Ctrl+Insert`, `Shift+Insert`, `Shift+Delete`)
- clipboard shortcuts dispatch cancelable `copy`/`cut`/`paste` events and respect `preventDefault()`

Graphical rendering and native input translation are still in-progress:

- frame presentation pipeline
- IME candidate/composition UI and dead-key edge cases

## 5) Route headed validation from one entrypoint

Use the validation router first when you want the smallest headed check that is
already committed on this branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea navigation
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea stop-loading
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle
```

Use the dedicated Google form-controls Enter-order route after the shared input
probes when issue #3 is already narrowed to the smallest real-surface
Enter-submit checkpoint. Use the broader `google-shared-enter-order` route when
issue #3 replay should stay on the reusable shared Enter-order ladder before
widening back out to live Google or attached-page follow-up. Use `rendering`
before attached-page replay when the change touched layout, paint, screenshot
timing, or other visible headed-surface behavior. Use `network` before
attached-page replay when the change touched shared subresource loading,
authenticated asset fetches, or browser-managed request credentials. Use
`browser-shell` when the change touched tabs, settings persistence, chrome
keyboard shortcuts, or related shell behavior. Use `popup` when the change
touched popup creation, named-target flows, or popup policy on the real headed
window. Use the suite-level `google-attached-html` and
`attached-html-target-bundle` views when you want the narrower issue #3
attached-page helper surface reprinted without widening back out to the rest of
the router catalog first.

For the broader subsystem-to-probe map across the existing `tmp-browser-smoke`
families, read `docs/HEADED_MODE_VALIDATION_MATRIX.md` after the router output.
Use that matrix when the change lands outside the router's currently named
change areas or when you need a quick first pick for a deeper probe family.

What exists today:

- the Windows prerequisite checker in `scripts\windows\`
- bounded localhost navigation probes under `tmp-browser-smoke\wrapped-link\`
- bounded localhost stop/reload coverage under `tmp-browser-smoke\stop-loading\`
- bounded localhost input probes under `tmp-browser-smoke\form-controls\`
- a dedicated Google form-controls Enter-order gate surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order` and `scripts\windows\run_google_form_controls_enter_order_validation.ps1`
- a broader shared Enter-order ladder surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order` when issue #3 replay should stay on the reusable shared keypress-before-submit path before widening back out
- checkout-portable first-line rendering probes surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering` for shared layout, screenshot timing, and visible headed-surface checks before attached-page replay
- checkout-portable first-line network probes surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network` for authenticated stylesheet and fetch-credentials regressions before attached-page replay
- checkout-portable first-line browser-shell probes under `tmp-browser-smoke\tabs\` and `tmp-browser-smoke\settings\`, surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea browser-shell`
- a checkout-portable first-line popup probe under `tmp-browser-smoke\popup\`, surfaced through `scripts\windows\show_headed_validation_suites.ps1 -ChangeArea popup`
- a checkout-portable first-line canvas screenshot probe at `tmp-browser-smoke\canvas-smoke\chrome-canvas-render-probe.ps1`
- a truthful validation router at `scripts\windows\show_headed_validation_suites.ps1`
- the first-line navigation, stop-loading, input, rendering, network, browser-shell, and popup probes now auto-resolve the repo root and `zig-out\bin\lightpanda.exe` from the current checkout
- an attached-pages localhost catalog, sidecar audit, broader asset-audit helper, and strict completeness launch surface under `tmp-browser-smoke\attached-pages\` plus the Windows wrapper `scripts\windows\start_attached_pages_catalog.ps1`
- a guarded attached-pages launcher companion surface under `scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1` and `scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1`
- dedicated suite-level `google-attached-html` and `attached-html-target-bundle` router surfaces when the issue #3 replay should stay on the narrower attached-page helper lane without reopening the rest of the catalog first
- a Windows-first attached-bundle bridge surface under `scripts\windows\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1` plus the fail-fast checker `scripts\windows\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1`

Treat the validation router output as the source of truth for the currently
committed helper surface on this branch.

## 6) Validate saved or attached HTML pages honestly

Use the validation router when you want the current attached-html route printed
with your concrete input path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle
```

Use the broader `attached-html` route first when the saved bundle is not yet
obviously on the Google-like replay lane, use `google-attached-html` when the
replay still matches the Google-shaped flow but is not yet pinned to the exact
three-page compatibility bundle, and switch to `attached-html-target-bundle`
once the current pages are already confirmed to be that known three-page set.
Use the suite-level `google-attached-html` and `attached-html-target-bundle`
views when you want the same narrower attached-page helper surface reprinted
without widening back out to the rest of the router catalog first.

When the current replay should stay pinned to the known three-page compatibility
bundle, keep this exact file set together from the start:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer the Google Safety Centre export as `-PreferredInitialPage` when the
replay should keep one Google-like page first while staying on the same bundle.
For the shortest written route into that Google-first replay, read
`docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`. When the run is already
re-entering from `show_headed_validation_suites.ps1 -ChangeArea attached-html`
and needs the shorter issue `#3` attached-page follow-up ladder printed before
widening again, read `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
alongside the same router output. When the run is re-entering from the broader
validation router and still needs the attached-html helper ladder visible
before narrowing again, read
`docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` alongside the same
router output.

Before starting the localhost catalog server or blaming headed replay, reuse
the Windows wrapper-backed launcher preflight from the same branch surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteSidecars -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteSidecars -RequireCompleteAssets
```

Run the sidecar audit first so missing sibling `_files` directories fail fast
before deeper replay diagnosis, run the asset audit second so broader local
export drift stays visible before the browser is blamed, use the manifest
command when you want the pinned localhost routes printed without starting the
server, add `-RequireCompleteSidecars` when the manifest or localhost launch
should stop on incomplete saved-page bundles, add `-RequireCompleteAssets` when
the same route should also stop on missing local assets, and pair both require
switches when replay should stay pinned to a fully closed saved-page bundle
before the browser is blamed.

When you want the same wrapper-backed preflight, strict bundle gates, and
pinned proof follow-up reprinted from one compact issue `#3` surface first,
rerun the launcher companion guard and helper before widening back into the
broader Windows-first route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot "<repo-root>" -InputPath "<saved-html-or-folder>"
```

Use the guard first when the launcher companion itself, its note pointers, or
the wrapper-backed attached-pages route may have drifted. Then keep the
companion helper nearby when the replay should preserve the wrapper-side
sidecar audit, the broader asset audit, the strict sidecar gate, the strict
asset gate, the strict bundle gate, and the pinned proof checker plus proof
entrypoint on one smaller surface before the broader Windows-first ladders
reopen.

When the current replay should stay pinned to the known three-page compatibility
bundle, use the compact Windows-first bundle bridge before widening back into
the broader attached-page ladders:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath "<bundle-html-or-folder>"
```

Use the bundle-bridge surface checker first so renamed notes or helper scripts
fail fast after branch moves, reopen `google-attached-html` when the replay is
still clearly Google-like but the exact three-page compatibility set is not yet
confirmed, and then continue into the pinned bundle route once the current
inputs really do stay on that narrower branch.