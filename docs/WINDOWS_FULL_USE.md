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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
```

What exists today:

- bounded localhost probes under `tmp-browser-smoke\wrapped-link\`
- bounded localhost probes under `tmp-browser-smoke\form-controls\`
- the Windows prerequisite checker in `scripts\windows\`
- the committed attached HTML helper chain rooted at `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- the Windows-first issue `#3` attached HTML re-entry helpers in `show_google_issue3_windows_full_use_attached_html_route.ps1` and `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`
- the replay-side attached HTML quickstart in `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- the pinned three-page bundle helpers in `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` and `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Treat the validation router output and the newer issue `#3` Windows attached HTML
notes as the source of truth for the currently committed helper surface. Older
notes that still describe the attached HTML or pinned bundle routes as missing
are now stale.

## 6) Validate saved or attached HTML pages honestly

The saved-page compatibility path now has committed helper surfaces for both the
broader attached HTML route and the pinned three-page bundle route. Start with
the router or the Windows-first issue `#3` attached HTML notes before dropping
to a manual localhost replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -InputPath "<saved-html-or-folder>"
```

When the current inputs are still the known three-page compatibility bundle,
keep these notes nearby and prefer the committed bundle helper chain before
widening back into the broader attached-page route:

- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

If you still need a plain manual localhost fallback, keep the exported HTML file
and any sibling `*_files` asset directory together, serve them locally, then
browse the page in headed mode:

```powershell
cd <folder-containing-exported-html>
python -m http.server 8123 --bind 127.0.0.1
.\zig-out\bin\lightpanda.exe browse --headed --window_width 1366 --window_height 900 "http://127.0.0.1:8123/<page.html>"
```

When you already know which saved page or bundle folder you want to replay, ask
the validation router to print the same localhost steps with your concrete
input path expanded:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath "<saved-html-or-folder>"
```

For the current three-page compatibility bundle, use the committed bundle route
or the manual route for each page and verify:

- the page title appears in the native window
- top-of-page controls stay clickable
- scrolling works
- text fields keep focus and accept typing
- Enter-driven submit or button activation still behaves as expected

Some older probe scripts still assume the repo checkout lives at
`C:\Users\adyba\src\lightpanda-browser`. If your checkout differs, prefer the
router and issue `#3` helper surfaces above or normalize those probe-local
paths before depending on them.
