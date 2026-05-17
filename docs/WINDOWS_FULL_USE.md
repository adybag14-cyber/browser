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

For richer localhost validation, check the reusable fixture probe surface first,
then run the reusable local-fixture probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
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
- fails fast if the reusable probe chain or its shared dependencies were renamed or removed

Results are written under:

- `tmp-browser-smoke\local-html-fixtures\output\`

Use `check_local_html_fixture_validation_surface.ps1 -Json` after branch updates
or helper renames when you want the reusable saved-page replay path to fail fast
before you spend time staging exports or opening a headed window.

This is a good first-pass validation path for exported real-site pages before
moving into a narrower bug investigation or adding a dedicated bounded probe.

## 6) Route headed validation quickly

Use the shared suite map first when you need to choose the narrowest headed
probe for a change:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

When the current replay is still the known three-page attached HTML
compatibility bundle, keep
`docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md` and
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md` nearby and stay on the
bundle-first route before widening back into the broader attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_bundle_first_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-focused ladder when the broader Windows runbook already made
attached localhost follow-up the next obvious route and you want the newer
Windows-first bundle bridge, the compact bundle-suite helper, the replay-route
bundle bridge, and the narrower bundle-first helper kept visible together on one
read-first path.

Only widen back to `show_google_attached_html_validation_flow.ps1` or
`show_attached_html_validation_flow.ps1` after the pinned bundle no longer
matches the current inputs or the next failure needs the broader attached-page
lane reprinted first.

For the current Google search-box work behind issue `#3`, keep the shorter
suite-router notes nearby when you want the fastest written bridge from the
top-level validation catalog into the current helper chain:

- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`

If the broader Windows runbook already made attached localhost replay the next
obvious issue `#3` branch, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`,
`docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`,
`docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`, and
`docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md` nearby and reopen the
broader Windows-first attached-page route before the helper chain narrows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
```

If the replay is already running from a non-default checkout, an already-saved
summary, or explicit attached bundle paths, preserve that same context directly
in the broader bridge helpers before dropping back into the narrower attached-page
quickstarts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use those helpers when the broader Windows runbook already narrowed the replay
to attached localhost follow-up and you want the route-level surface check, the
Windows-to-validation-router bridge, the replay-side attached-html
quickstart, and the change-area quickstart visible before the route narrows
into the smaller top-level attached-page helpers, the shorter attached-page
shortcut, replay shortcuts, or the safe-route map.

If the replay is already known to stay on `show_headed_validation_suites.ps1 -ChangeArea attached-html`,
keep `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md` nearby and print the
shorter change-area quickstart before dropping into the broader attached-page
flow helper or the narrower top-level attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

If the replay is already carrying a non-default checkout, an already-saved
summary, or explicit attached bundle paths, preserve that same context directly
in the change-area quickstart before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that shorter change-area route when the top-level validation router has
already narrowed the replay to attached localhost follow-up and you want the
broader attached-page flow helper, the dedicated Google-shaped attached-page
flow guide, and the compact top-level attached-page bridge to stay aligned on
one shorter read-first ladder.

If that same attached localhost replay should stay on the newer Google-shaped
attached-page lane before it narrows back into the top-level or suite-router
helpers, keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` nearby and
reopen the Google-style surface check, local-asset audit, helper, and runner
first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

If the replay already carries a non-default checkout, a preferred starting
page, an explicit browser binary, or pinned attached bundle paths, preserve
that same context directly in the Google-style helper chain before widening
again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>' -Wait
```

Use that Google-style branch when the current attached inputs already include a
Google-like page and you want the stricter issue `#3` attached-page surface
check, the local-asset audit, and the Google-first helper output visible before
the route narrows back into the shorter top-level attached-page quickstarts,
suite-router notes, replay shortcuts, or the safe-route map.

If that same replay is already clearly on the attached localhost follow-up
branch, keep `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` nearby too and
print the compact top-level attached-page quickstart before reopening the
broader top-level attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, an already-saved
summary, or explicit attached bundle paths, preserve that same context directly
in the quickstart helper before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that quickstart when the Windows runbook has already narrowed the next
replay to attached localhost follow-up and you want the shortest top-level
attached-page bridge visible before the route widens into the broader attached-page
entrypoint, the suite-router attached-page quickstart, replay shortcuts, or the
safe-route map.

If that same replay should keep the newer catalog-side attached-page bridge
visible before the helper chain narrows again, keep
`docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md` nearby too
and print the Windows-first catalog quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
```

If the replay is already running from a non-default checkout, an already-saved
summary, or explicit attached bundle paths, preserve that same context directly
in the catalog quickstart helper before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that helper when the Windows runbook has already narrowed the next replay
to attached localhost follow-up and you want the top-level attached-page
catalog quickstart plus the suite-catalog attached-page bridge reprinted before
the route narrows into the shorter attached-page shortcut, replay shortcuts,
contextual flow, or the safe-route map.

Start with the newer suite-catalog bridge and next-step matrix before widening
into the broader handoff or replay-route helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

If the replay is running from a non-default checkout, from an already-saved
summary, or from an explicit attached-bundle path, preserve that context
directly in the catalog helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If that same replay still stays inside issue `#3`, preserve the same context in
the next-step matrix before reopening narrower helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you want the slightly wider compact bridge after the catalog helper or the
next-step matrix because the replay-route, bundle-first, or safe-route-map
surfaces still need to stay visible together, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

If the replay is running from a non-default checkout, from an already-saved
summary, or from an explicit attached-bundle path, preserve that context
directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```