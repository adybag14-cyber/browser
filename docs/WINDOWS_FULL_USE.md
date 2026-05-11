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

## 5) Run saved local HTML fixtures in headed mode

For richer localhost validation, use the reusable local-fixture probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 `
  -FixturePaths `
    "C:\path\to\Control your online safety and privacy – Google Safety Centre.html",`
    "C:\path\to\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic.html",`
    "C:\path\to\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
```

What it does:

- stages each saved HTML file behind a localhost server
- copies a sibling `<page-base>_files` asset directory when one exists
- opens each page in headed `browse`
- captures a screenshot for each fixture
- checks that the native window title matches the page `<title>`

Results are written under:

- `tmp-browser-smoke\local-html-fixtures\output\`

This is a good first-pass validation path for exported real-site pages before
moving into a narrower bug investigation or adding a dedicated bounded probe.

## 6) Route headed validation quickly

Use the shared suite map first when you need to choose the narrowest headed
probe for a change:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

For the current Google search-box work behind issue `#3`, use these helpers in
order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle -LeaveOpen
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle -LeaveOpen
```

For attached or saved localhost HTML follow-up after the matching bounded suite
is green, use these entry points:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
```

Routing rules:

- Start with the smallest bounded localhost suite before a saved-page or live-site pass.
- Use `show_google_input_validation_flow.ps1` when you want the full issue `#3` order printed as reusable commands.
- Use `show_google_title_validation_flow.ps1` when you want only the narrower bounded title-wrapper order printed before you run that slice.
- Use `show_google_title_probe_trace_guide.ps1` when you want the title markers translated into focus, text-commit, and Enter-submit stages without opening the saved markdown guide by hand.
- Use `run_google_title_validation.ps1` when you want the bounded title wrapper by itself before the faster quick pass, reduced homepage pass, or shared Enter-order follow-up.
- Use `run_google_issue3_recommended_validation.ps1` when you want the one-command issue `#3` flow to include the reduced-home keypress-before-submit probe through the shared Enter-order wrapper before the live or attached follow-up steps.
- Use `check_google_form_controls_enter_order_validation_surface.ps1` before `show_google_form_controls_enter_order_validation_flow.ps1` or `run_google_form_controls_enter_order_validation.ps1` so missing docs, helper scripts, or the raw dedicated probe fail fast.
- Use `show_google_form_controls_enter_order_validation_flow.ps1` when you want only the dedicated shared form-controls Enter-order gate printed and parameterized before you run it.
- Use `run_google_form_controls_enter_order_validation.ps1` when you want the dedicated shared form-controls Enter-order gate by itself after the broader shared Enter-order ladder or when narrowing the last shared keypress-before-submit check.
- Use `run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle` when you want the one-command issue `#3` flow to finish by auto-discovering current-run attached HTML under `user_files/` and `agent_files/`, while preferring a Google-like page first.
- Use `run_google_shared_enter_order_validation.ps1` when you want the shared issue `#3` enter-order stack by itself, including the reduced-home keypress-before-submit probe, the stricter localhost wrapper, and the shared form-controls gate.
- Use `check_google_attached_html_validation_surface.ps1` before `show_google_attached_html_validation_flow.ps1` or `run_google_attached_html_validation.ps1` when the next pass should reuse attached Google-style pages, so missing guides, helpers, or localhost runners fail fast.
- Use `check_attached_html_local_asset_closure.ps1 -GoogleStyle` before the Google attached-page flow when the saved page set might have nested CSS, image, or font dependencies that were not copied beside the HTML export.
- Use `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` when you want the shared validation router to point directly at the dedicated attached-HTML Google follow-up helper.
- Use `run_localhost_html_validation_recommended.ps1` when you want one command that auto-routes attached HTML under `agent_files/` or explicit saved-page inputs into the right localhost helper.
- Use `show_attached_html_validation_flow.ps1 -GoogleStyle` when the attached HTML set includes a Google-like page and you want that page chosen first for the manual headed follow-up.
- Use `show_google_attached_html_validation_flow.ps1` when you want the printed Google-style localhost-first flow for auto-discovered attached HTML without reshaping the broader issue `#3` commands by hand.
- Use `run_google_attached_html_validation.ps1` when you want the same Google-style attached HTML follow-up to execute directly in one command; attached-file modes now rerun the deep asset-closure audit before launch.
- Use `show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle` when you want the saved-page handoff commands to target the same auto-discovered Google-style attached pages without restating input paths.
- Use `show_saved_page_google_validation_flow.ps1` when the saved-page pass should stay in the same localhost-first Google investigation order before the manual headed retest.
