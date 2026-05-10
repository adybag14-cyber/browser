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

## 5) Headed validation gate map

The headed probe suites under `tmp-browser-smoke/` are now the default
validation map for this fork.

Start with:

1. the narrowest suite for the subsystem you changed
2. one nearby shared-behavior suite when the change touches input, rendering,
   navigation, persistence, or downloads
3. the issue-specific reduced Google or manual real-site pass only after the
   bounded local suite is green

Command-line helper:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName layout-smoke
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-home
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input -Json
```

Primary suite families:

- shell and browser pages: `tabs/`, `browser-pages/`, `settings/`, `popup/`,
  `wrapped-link/`, `stop-loading/`, `bookmarks/`
- rendering and layout: `layout-smoke/`, `inline-flow/`, `flow-layout/`,
  `rendered-link-dom/`, `font-render/`, `font-smoke/`, `image-smoke/`,
  `stylesheet-smoke/`, `zoom/`
- forms and editing: `form-controls/`, `find/`, `file-upload/`, `downloads/`,
  `attachment-downloads/`
- reduced Google input investigation: `google-investigation-next/` for
  Google-style localhost probes that cover focus churn, delayed readiness,
  correction, and Enter-submit ordering before the reduced homepage pass
- reduced Google homepage surface: `google-home/` for the bounded real-window
  Enter-submit probe and title-stream watcher path against
  `google_home_title_probe.html`
- persistence and runtime: `cookie-persistence/`,
  `localstorage-persistence/`, `indexeddb-persistence/`,
  `sessionstorage-scope/`, `fetch-abort/`, `fetch-credentials/`,
  `websocket-smoke/`
- graphics and packaging: `canvas-smoke/`, `multi-image/`,
  `bare-metal-release/`

See `tmp-browser-smoke/README.md` for the full suite map and recommended
change-to-probe routing.

## 6) Reduced Google homepage probe

Use the reduced Google probe pages when issue-driven headed input work needs a
repeatable local check before moving on to the full live homepage.

Start with `tmp-browser-smoke/google-investigation-next/` for the narrowed
localhost probes. Then use `tmp-browser-smoke/google-home/` when you need a
bounded real-surface Enter-submit pass on the reduced homepage fixture itself.
Use the watcher below only when you want a longer interactive title stream on
that same fixture.

Bounded reduced homepage pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-enter-probe.ps1
```

That probe should reach the title markers `FOCUSED`, `TYPED:QZ`, and
`SUBMIT:QZ` before you move on to a live Google manual pass.

One-command reduced Google plus nearby shared-input pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase all -IncludeSharedInput
```

With `-IncludeSharedInput`, the ordered follow-up now includes the reduced
homepage pass plus the nearby shared input checks for deferred Enter submit,
basic Enter submit, and inline-flow submit behavior.

Interactive watcher path:

1. Start a local static server from the repo root:

```powershell
python -m http.server 9582
```

2. In a second shell, watch the headed probe title stream:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\watch_headed_probe.ps1
```

Defaults:

- URL: `http://127.0.0.1:9582/src/browser/tests/page/google_home_title_probe.html`
- Expected ready marker: `BOUND|`
- Trace output: `tmp-browser-smoke\headed-probe\headed-probe-trace.json`

Useful options:

- `-LeaveOpen` keeps the headed browser running after the expected marker is seen so you can click and type manually.
- `-ExpectedTitleContains "SUBMIT:"` is useful when validating that an Enter path reaches form submission on the reduced probe.
- `-BrowserExe <path>` lets you point at a custom Windows build output.

The probe mirrors the query box state into the window title so you can track
focus, keydown, keypress, beforeinput, input, and submit behavior without
attaching a separate debugger first.

## 7) Saved localhost HTML page validation

Use `scripts\windows\start_localhost_html_validation.ps1` when you want a
repeatable headed session against saved or attached HTML pages instead of the
repo's built-in smoke fixtures.

Typical flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -LaunchBrowser `
  -Wait
```

When the saved pages live across several standalone HTML files or folders,
stage them into one clean localhost run first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_staged_localhost_html_validation.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -LaunchBrowser `
  -Wait
```

That wrapper copies the provided inputs into a timestamped validation root,
writes `staged-input-manifest.json`, and then hands off to
`start_localhost_html_validation.ps1`.

What the helper does:

- serves every `.html` and `.htm` file under `-PageRoot` on `http://127.0.0.1:<port>/`
- chooses the first HTML file alphabetically unless `-InitialPage` is provided
- optionally launches the headed browser directly against that first page
- writes the session summary and server logs under `tmp-browser-smoke\manual-user\localhost-html-validation\`

Useful options:

- `-InitialPage subdir/page.html` opens a specific saved page first
- `-InitialPage C:\path\to\saved-page.html` also works with `start_staged_localhost_html_validation.ps1` when you want to open one staged source file first
- `-Port 8124` moves the local server when another harness is already bound
- `-Host 0.0.0.0` exposes the same pages to other machines on the LAN when needed
- `-LeaveServerRunning` keeps the server alive after the `-Wait` prompt completes
- omit `-LaunchBrowser` when you only want the localhost URLs and log files

This helper is meant for manual compatibility passes on real saved pages after
bounded probe suites are green. It does not replace the normal `tmp-browser-smoke/`
validation gates; it gives them a cleaner follow-up path for real-world local HTML.