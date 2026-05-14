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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

For the current Google search-box work behind issue `#3`, keep the shorter
suite-router notes nearby when you want the fastest written bridge from the
top-level validation catalog into the current helper chain:

- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`

If the broader Windows runbook already made attached localhost replay the next
obvious issue `#3` branch, keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
nearby and print the dedicated attached-page route helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
```

If the replay is already running from a non-default checkout, an already-saved
summary, or explicit attached bundle paths, preserve that same context directly
in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

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

If you want those read-first commands plus the attached three-page bundle route, the current safe-route map, and the repo-root-aware runner next-step helper printed together in one place, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

If the replay is running from a non-default checkout, from an already-saved
summary, or from an explicit attached-bundle path, preserve that context
directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you already want the narrower shortcut helper directly after the catalog
helper, next-step matrix, or that broader replay-route bridge, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

If the replay is running from a non-default checkout, from an already-saved
summary, or from an explicit attached-bundle path, preserve that context
directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the current saved or attached pages are already the known three-page
compatibility bundle and you want that pinned bundle route plus the return
commands printed in one helper before reopening the broader Google-only safe
route, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved
summary, or from an explicit attached-bundle path, preserve that context
directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this helper when the next replay should stay pinned to the known three-page
compatibility bundle before widening back into the wrapper-heavy issue `#3`
chain. It keeps the bundle suite-router command, the bundle flow helper, the
delegated bundle runner, the replay-shortcuts helper, and the safe-route return
command on one compact command surface.

When those commands narrow the replay into the wrapper-heavy issue `#3` safe
route, print the dedicated safe-route entrypoints map next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

For the current Google search-box work behind issue `#3`, use these helpers in
order.

Keep these notes open once the replay narrows into the wrapper-heavy safe route:

- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md` for the shortest bridge from `show_headed_validation_suites.ps1` into the current issue `#3` helper chain
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge from the suite router into replay shortcuts, the bundle-first route, and the safe-route entrypoints
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path before reopening the longer chain
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the current fresh replay entrypoints and wrapper precedence
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the replay lands on `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` for the field-level runner patch rules once the safe-route handoff artifact says a direct source edit is still required
- `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md` when the replay is running from a non-default checkout or should keep `LIGHTPANDA_REPO_ROOT` plus `SummaryPath` aligned through the safe-route helpers

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1