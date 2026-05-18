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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
```

For the broader subsystem-to-probe map across the existing `tmp-browser-smoke`
families, read `docs/HEADED_MODE_VALIDATION_MATRIX.md` after the router output.
Use that matrix when the change lands outside the router's currently named
change areas or when you need a quick first pick for a deeper probe family.

What exists today:

- the Windows prerequisite checker in `scripts\windows\`
- bounded localhost navigation probes under `tmp-browser-smoke\wrapped-link\`
- bounded localhost stop/reload coverage under `tmp-browser-smoke\stop-loading\`
- bounded localhost input probes under `tmp-browser-smoke\form-controls\`
- a truthful validation router at `scripts\windows\show_headed_validation_suites.ps1`
- the first-line navigation, stop-loading, and form-control probes now auto-resolve the repo root and `zig-out\bin\lightpanda.exe` from the current checkout
- an attached-pages localhost catalog, sidecar audit, and broader asset-audit helper surface under `tmp-browser-smoke\attached-pages\` plus the Windows wrapper `scripts\windows\start_attached_pages_catalog.ps1`

Treat the validation router output as the source of truth for the currently
committed helper surface on this branch.

## 6) Validate saved or attached HTML pages honestly

Use the validation router when you want the current attached-html route printed
with your concrete input path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
```

When the current replay should stay pinned to the known three-page compatibility
bundle, use the compact Windows-first bundle bridge before widening back into
the broader attached-page ladders:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath "<bundle-html-or-folder>"
```

Keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md` nearby when that
pinned bundle route is the next intended replay path.

The preferred localhost path on this branch is the attached-pages catalog
helper, not a hand-built `python -m http.server` session. It gives the saved
HTML bundle short stable routes, a generated manifest, a sidecar audit that
answers whether the export is missing its sibling `_files` directory, and a
broader asset audit that can fail fast before the browser is involved.

Use the sidecar audit first. A missing `_files` directory means the export
itself is incomplete, so the next replay result is already degraded before it
says anything about the headed runtime.

When you need to validate a non-default browser build, keep that same binary
pinned at every helper hop instead of letting the route drift back to
`.\zig-out\bin\lightpanda.exe`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -BrowserExe "C:\path\to\lightpanda.exe" -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -BrowserExe "C:\path\to\lightpanda.exe" -InputPath "<saved-html-or-folder>"
```

The broader Google-shaped attached-page flow already preserves `-BrowserExe`.
The replay-side issue `#3` attached-page quickstart now preserves `-BrowserExe`
through its printed replay bridge, broader attached-page flow helper, dedicated
Google-shaped attached-page flow helper, and top-level attached-page quickstart.
Before widening from that replay ladder into older attached-page helpers, rerun
the validation router with `-BrowserExe` so any still-default shortcut is easy
to spot.

For a concrete saved page or bundle root, use the Windows wrapper first and run
the same pinned input set through the sidecar check before the broader asset
audit:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -Port 8235
```

For the current issue `#3` style replay, let the wrapper auto-discover the
attached pages and keep the strongest Google-like page first when one is
available:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -Port 8235
```

For non-Windows or scheduled runs, the matching Python launcher exposes the same
pinned-input flow and preflight modes without going through PowerShell:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --audit-sidecars
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --audit-assets
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --print-manifest
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --google-style --port 8235
```

If you want to bypass the launchers and run the lower-level Python helper
directly from the repo root, keep the same sidecar-first, asset-second order:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py --root "<saved-html-or-folder>"
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root "<saved-html-or-folder>" --audit-assets
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root "<saved-html-or-folder>" --print-manifest
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root "<saved-html-or-folder>" --port 8235
```

Then browse the generated catalog or one of its short routes in headed mode:

```powershell
.\zig-out\bin\lightpanda.exe browse --headed --window_width 1366 --window_height 900 "http://127.0.0.1:8235/"
```

Use this flow to verify:

- the generated catalog or pinned manifest resolves the expected pages
- the page title appears in the native window
- top-of-page controls stay clickable
- scrolling works
- text fields keep focus and accept typing
- Enter-driven submit or button activation still behaves as expected

If the sidecar audit reports a missing `_files` directory, restore that export
bundle first or consciously accept a degraded replay before blaming the browser.
If the sidecar audit passes but the asset audit still reports missing local
files, fix the saved bundle first or rerun with the explicit allow-missing path
only when you want a best-effort replay and are ready to treat the result as a
narrower signal.

The router's first-line navigation, stop-loading, and form-control probes now
resolve the repo root from the current checkout automatically. Older deeper
probe families under `tmp-browser-smoke\` can still carry fixed local path
assumptions, so prefer the router output and the attached-pages catalog helper
before widening into older helpers.