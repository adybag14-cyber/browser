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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile title
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_wrapper.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_validation_surface.ps1 -Profile submit-path
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle -LeaveOpen
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle -LeaveOpen
```

For attached or saved localhost HTML follow-up after the matching bounded suite
is green, use these entry points:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_saved_page_localhost_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_localhost_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1 -InputPath '<saved-html-or-folder>' -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
```

Routing rules:

- Start with the smallest bounded localhost suite before a saved-page or live-site pass.
- Use `show_headed_validation_suites.ps1 -SuiteName google-recommended` when you want the higher-level suite router to surface the broader localhost-first issue `#3` runner and its companion checkpoints before choosing a narrower slice.
- Use `show_headed_validation_suites.ps1 -ChangeArea google-input` when the next replay may need the narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slices instead of the broader recommended runner.
- Use `show_google_issue3_suite_catalog_entrypoints.ps1` when you want the exact top-level suite-router entrypoints and the current issue `#3` replay helpers surfaced together before choosing the narrower branch back into the live helper chain.
- Use `show_google_issue3_suite_router_next_steps.ps1` when you want the fastest command matrix from the top-level suite router before deciding between the handoff, replay-route, bundle-first, shortcut, or safe-route branches.
- Use `show_google_issue3_replay_shortcuts.ps1` when the matrix or replay-route helper has already narrowed the replay back inside issue `#3` and you want the tightest current shortcut surface before deciding whether to widen into the handoff, replay-route, bundle-first, or safe-route helpers.
- Use `show_google_input_validation_flow.ps1` when you want the full issue `#3` order printed as reusable commands.
- Use `show_google_issue3_suite_router_handoff.ps1` when you want the wider compact bridge from the suite-catalog and next-step helpers into the current replay-shortcuts, bundle-first, and safe-route-map helpers before you decide whether the next replay should stay broad or narrow.
- Use `show_google_issue3_replay_route.ps1` when you want the same read-first bridge plus the attached three-page bundle branch, the current safe-route map, and the repo-root-aware runner next-step helper preserved together before choosing whether the next replay should stay on the pinned compatibility bundle, narrow into replay shortcuts, or reopen the wrapper-heavy safe-route entrypoints.
- Use `show_google_issue3_replay_shortcuts.ps1` when you want the same read-first commands, the attached three-page bundle route, and the current safe-route helpers printed together before deciding whether the next replay should stay on the pinned compatibility bundle or reopen the broader wrapper-heavy issue `#3` path.
- Use `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the current saved or attached inputs are the known three-page compatibility bundle and you want the pinned bundle-first route plus the replay-shortcuts helper and safe-route return command printed together before widening back into the broader Google-only wrapper chain.
- Use `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` and `show_google_issue3_windows_full_use_attached_html_route.ps1` when `docs/WINDOWS_FULL_USE.md` already narrowed the replay to attached localhost follow-up and you want the shorter attached-page-first helper chain before reopening the broader suite-catalog, replay-route, or safe-route notes.
- Use `show_google_issue3_safe_route_entrypoints.ps1` after the shared suite router or broader Google flow has already narrowed into the current wrapper-heavy issue `#3` replay and you want the fresh replay, reuse-current-outputs, refresh-status, handoff-safe, summary-guide, and runner-wiring commands printed in one place.
- Use `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` when you want the shortest current safe-route replay note before reopening the longer validation-chain or decision-table guidance.
- Use `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` as the wrapper-order reference once the issue `#3` replay narrows into safe-route, handoff, or repair helpers.
- Use `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay lands on the direct runner patch loop and you want the next move for `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs` without reopening the longer chain note.
- Use `show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>` when the safe-route wrapper has already emitted one of those three states and you want the exact next commands without reopening the longer decision table first.
- Use `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` beside the decision table when the replay is already on the direct runner source edit and you need the field-level rules for nullable `$null`, artifact order, blank-path handling, and post-patch verification.
- Use `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md` when the replay is running from a non-default checkout or should preserve `LIGHTPANDA_REPO_ROOT` plus a current `SummaryPath` through the safe wiring, refresh, and handoff checkpoints.
- Use `check_google_validation_surface.ps1 -Profile title` before `show_google_title_validation_flow.ps1` or `run_google_title_validation.ps1` so the narrower title guide, helper, direct probe, and fixture chain fails fast before you depend on that smaller issue `#3` ladder.
- Use `show_google_title_validation_flow.ps1` when you want only the narrower bounded title-wrapper order printed before you run that slice.
- Use `show_google_title_probe_trace_guide.ps1` when you want the title markers translated into focus, text-commit, and Enter-submit stages without opening the saved markdown guide by hand.
- Use `run_google_title_validation.ps1` when you want the bounded title wrapper by itself before the faster quick pass, reduced homepage pass, or shared Enter-order follow-up.
- Use `run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1` as the default fresh replay entrypoint when current issue `#3` outputs may be stale or missing and you want the newest safe-route plus final runner-patch handoff artifact in one command.
- Use `run_google_issue3_recommended_validation_safe_route_runner_patch_wrapper.ps1` when you want the broader safe-summary route to refresh the current replay first and then preserve the narrower safe-route runner-patch guidance in one artifact before deciding between `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`.
- Use `show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1` when the current issue `#3` outputs are already present and you want to reopen the safe-route plus narrower runner-patch guidance without a broader regeneration first.
- Use `run_google_issue3_recommended_validation.ps1` when you intentionally want the broader one-command issue `#3` flow to regenerate the reduced-home keypress-before-submit probe through the shared Enter-order wrapper before the live or attached follow-up steps.
- Use `check_google_validation_surface.ps1 -Profile submit-path` before `show_google_submit_path_validation_flow.ps1` or `run_google_issue3_submit_path_validation.ps1` so missing guides, helpers, or bounded probes fail fast before you depend on the later issue `#3` submit-path ladder.
- Use `show_google_submit_path_validation_flow.ps1` when you want only the later-stage saved homepage fixture, submit-timing, and shared Enter-order ladder printed after the title gates are already green.
- Use `show_google_submit_path_trace_guide.ps1` when you want the saved homepage fixture, submit-timing, and shared Enter-order outputs translated into the next smaller checkpoint before you rerun anything or widen back out to attached HTML or the live headed homepage.
- Use `run_google_issue3_submit_path_validation.ps1` when the title or reduced-homepage gates are already green and you want the saved homepage fixture, submit-timing, and shared Enter-order slices in one narrower command before the trace or live Google follow-up.
- Use `check_google_form_controls_enter_order_validation_surface.ps1` before `show_google_form_controls_enter_order_validation_flow.ps1` or `run_google_form_controls_enter_order_validation.ps1` so missing docs, helper scripts, or the raw dedicated probe fail fast.
- Use `show_google_form_controls_enter_order_validation_flow.ps1` when you want only the dedicated shared form-controls Enter-order gate printed and parameterized before you run it.
- Use `show_google_form_controls_enter_order_trace_guide.ps1` when you want the dedicated probe markers translated into quick failure stages without reopening the longer read-first markdown note.
- Use `run_google_form_controls_enter_order_validation.ps1` when you want the dedicated shared form-controls Enter-order gate by itself after the broader shared Enter-order ladder or when narrowing the last shared keypress-before-submit check.
- Use `run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle` when you want the one-command issue `#3` flow to finish by auto-discovering current-run attached HTML under `user_files/` and `agent_files/`, while preferring a Google-like page first.
- Use `run_google_shared_enter_order_validation.ps1` when you want the shared issue `#3` enter-order stack by itself, including the reduced-home keypress-before-submit probe, the stricter localhost wrapper, and the shared form-controls gate.
- Use `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` when you want the shared validation router to point directly at the dedicated attached-HTML Google follow-up helper.
- Use `show_headed_validation_suites.ps1 -ChangeArea attached-html` when you want the shared validation router to point back at the broader attached-page localhost route before choosing between the bundle-aware and generic replay helpers.
- Use `check_attached_html_target_bundle_validation_surface.ps1`, `check_attached_html_target_bundle.ps1`, and `show_attached_html_target_bundle_validation_flow.ps1` when the current attached or saved page set is the known three-page compatibility bundle and you want one stable read-first route before launch.
- Use `run_attached_html_target_bundle_validation.ps1 -Wait` when the bundle checks are green and you want the same locked three-page set to launch through the bundle-aware route in one command.
- Use `check_google_attached_html_validation_surface.ps1` before `show_google_attached_html_validation_flow.ps1` or `run_google_attached_html_validation.ps1` when the next pass should reuse attached Google-style pages, so missing guides, helpers, or localhost runners fail fast.
- Use `check_attached_html_local_asset_closure.ps1 -GoogleStyle` before the Google attached-page flow when the saved page set might have nested CSS, image, or font dependencies that were not copied beside the HTML export.
- Use `check_saved_page_localhost_validation_surface.ps1` before manual saved-page follow-up when the branch has moved recently and you want the general localhost helper chain to fail fast if a guide, runner, or summary helper was renamed or removed.
- Use `check_local_html_fixture_validation_surface.ps1` before the reusable fixed-list fixture replay when you want the staged localhost probe and its shared helpers to fail fast after the branch has moved.
- Use `run_localhost_html_validation_recommended.ps1` when you want one command that auto-routes attached HTML under `agent_files/` or explicit saved-page inputs into the right localhost helper.
- Use `run_sanitized_saved_page_localhost_validation.ps1` when the saved inputs have Unicode-heavy filenames, were exported as standalone HTML files with sibling `*_files` assets, or need one ASCII-safe staged localhost root before headed launch.
- Use `show_attached_html_validation_flow.ps1 -GoogleStyle` when the attached HTML set includes a Google-like page and you want that page chosen first for the manual headed follow-up.
- Use `show_google_attached_html_validation_flow.ps1` when you want the printed Google-style localhost-first flow for auto-discovered attached HTML without reshaping the broader issue `#3` commands by hand.
- Use `run_google_attached_html_validation.ps1` when you want the same Google-style attached HTML follow-up to execute directly in one command; attached-file modes now rerun the deep asset-closure audit before launch.
- Use `show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle` when you want the saved-page handoff commands to target the same auto-discovered Google-style attached pages without restating input paths.
- Use `show_saved_page_google_validation_flow.ps1` when the saved-page pass should stay in the same localhost-first Google investigation order before the manual headed retest.
