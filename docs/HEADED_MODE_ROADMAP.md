# Headed Mode Roadmap (Fork)

This fork targets full headed-mode browser usage while preserving Lightpanda's
current headless strengths.

For the full product plan from the current headed foundation to a
production-ready minimalist Zig browser, see
`docs/FULL_BROWSER_MASTER_TRACKER.md`.

## Current Status

- `--browser_mode headless|headed` is now accepted.
- `--headed` and `--headless` shortcuts are available.
- On Windows targets, `headed` now starts a native window lifecycle backend.
- On non-Windows targets, `headed` still uses a safe headless fallback with warning.
- `--window_width` / `--window_height` now drive window/screen/viewport values.
- Display runtime abstraction exists with page lifecycle hooks and a Win32 thread backend.
- CDP viewport APIs update runtime viewport (`Emulation.*Metrics*`, `Browser.setWindowBounds`).
- Win32 headed backend now forwards native mouse (down/up/move/wheel/hwheel), click, keydown/keyup, text input (`WM_CHAR`/`WM_UNICHAR`), IME result/preedit composition messages (`WM_IME_COMPOSITION`), back/forward mouse buttons, and window blur events into page input.
- Win32 headed backend now propagates native key repeat state into `KeyboardEvent.repeat`.
- Text control editing now includes caret-aware insertion paths, `Ctrl/Meta + A` select-all, word-wise keyboard edit/navigation shortcuts, textarea vertical/line navigation, `Tab`/`Shift+Tab` focus traversal with `tabindex` ordering, and native clipboard shortcuts (`Ctrl/Meta + C/X/V`, `Ctrl+Insert`, `Shift+Insert`, `Shift+Delete`) with cancelable clipboard event dispatch.
- Windows prereq checker + runbook added (`scripts/windows`, `docs/WINDOWS_FULL_USE.md`).

## Validation Quick Routes

Use these Windows entrypoints when you want the narrowest headed validation path
without reopening the full helper chain by hand.

Top-level router:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Known attached HTML compatibility bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths '<bundle-html-or-folder>'
```

When the bundle route is being chosen from the broader router instead of from
already-pinned inputs, keep the wider attached-page helpers visible first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this re-entry when the three-page bundle is already the likely next move,
but you still want both the broader attached-page helper and the dedicated
Google-shaped attached-page helper visible before the replay locks onto the
pinned bundle branch.

Attached HTML target intent:

- `Control your online safety and privacy – Google Safety Centre (...).html`
  should stay visibly nonblank on the headed surface and keep top-of-page
  interactive controls usable, especially cookie-banner buttons, long-form
  scrolling, SVG-heavy sections, and ambient media containers.
- `Job Application for [Expression of Interest] Research Manager,
  Interpretability at Anthropic (...).html` is the bundle's strongest typed-form
  target: text entry, focus retention, combobox interaction, scrolling, and the
  primary apply flow should all stay usable on the real headed path.
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S.
  Department of War.html` exercises dense legacy markup: expanding the search
  affordance, focusing the search field, typing, submit-button activation, and
  large navigation/menu hit-testing should remain stable.
- When a bundle replay fails, route the follow-up toward the shared input,
  layout, or rendering path that broke. Do not special-case one saved page if
  the same headed subsystem would affect the others.

For the pinned three-page route, keep
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`,
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`, and
`docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` nearby. The reference
note keeps the fail-fast bundle surfaces, the delegated bundle runner, and the
reusable fixed-list screenshot-and-title probe on the same locked inputs before
the replay widens back into the broader issue `#3` helper chain, while the
Google attached-page note keeps the narrower Google-shaped fallback visible when
one of the pinned pages makes that route the next obvious follow-up.

Saved-page or attached-page localhost follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_saved_page_localhost_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1 -InputPath '<saved-html-or-folder>' -Wait
```

Google-shaped attached-page localhost follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

Use this route when the current attached inputs already include a Google-like
page and you want the stricter issue `#3` attached-page surface check, the
local-asset audit, and the Google-first helper output visible before the route
narrows back into the shorter top-level, suite-router, replay-shortcut, or
bundle-first helpers.

If the replay is already running from a non-default checkout, from a preferred
starting page, from an explicit browser binary, or from pinned attached bundle
paths, preserve that context directly in the Google-style helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -PreferredInitialPage '<preferred-page>' -BrowserExe '<browser-exe>' -Wait
```

Issue `#3` attached-page follow-up:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use the validation-router quickstart when the broader headed validation router
already made attached localhost replay the next obvious branch and you still
want that router context reprinted before the route narrows again. Use the
Windows replay attached-html quickstart when
`docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` already narrowed the replay to the
attached localhost lane and you want that replay-side helper ladder kept
visible. Use the suite-catalog entrypoints guide, suite-catalog top-level
attached-html catalog quickstart, and suite-catalog attached-html bridge when
you want the replay-side ladder, the dedicated suite-catalog command map, the
newer top-level attached-page catalog note family, and the suite-catalog
attached-page bridge visible together before the route collapses into the
shortcut-first helpers. Keep the Google-shaped attached-page entrypoint and the
shortcut-first helpers nearby when the route is already clearly inside issue
`#3` and the next step is choosing between replay shortcuts, the next-step
matrix, contextual flow, or the bundle-first branch. Use the bundle-first
helper whenever the current inputs are already the known three-page
compatibility bundle and you want that exact set pinned before widening back
into the broader helper chain. Keep the target-bundle reference note nearby
when you want the pinned manual checklist plus the reusable fixed-list
screenshot-and-title proof path surfaced with that same three-page set.

When the replay is already running from a non-default checkout, saved summary,
or pinned bundle paths, preserve that state with `-RepoRoot`, `-SummaryPath`,
and `-InputPath` on the issue `#3` helper scripts so the attached-page route
stays on the same context.

Keep these companion route notes nearby when the replay is already narrowed to
attached localhost follow-up:

- `docs/WINDOWS_FULL_USE.md` when the broader Windows runbook already made the
  attached localhost lane obvious and you want the widest route context before
  the helper chain narrows again.
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` and
  `docs/ISSUE3_WINDOWS_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` when the
  replay is re-entering from the Windows-facing route notes first.
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` and
  `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` when you want the
  replay-side and validation-router attached-page ladders surfaced before
  dropping into the smaller top-level helpers.
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`,
  `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`, and
  `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md` when the replay
  should stay on the compact top-level attached-page route before it narrows
  again.
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`,
  `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`,
  `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`, and
  `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` when you want the
  suite-catalog command map, the broader Google-style attached-page guide, and
  the attached-page bridge kept visible beside the replay-side and top-level
  attached-page catalog notes.
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`,
  `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`,
  `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`, and
  `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md` when the route has
  already narrowed to the suite-router side, the compact companion notes, or
  the pinned three-page compatibility bundle and you want the reusable
  fixed-list screenshot-and-title proof path kept nearby.

For the broader Windows runbook and the longer validation chain, keep
`docs/WINDOWS_FULL_USE.md`, `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`,
`docs/ISSUE3_WINDOWS_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`,
`docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`,
`docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`,
`docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`,
`docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`,
`docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`,
`docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`,
`docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`,
`docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`,
`docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`,
`docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`,
`docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`,
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`,
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`, and
`docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` nearby.

## Milestones

1. Display abstraction
- Introduce a renderer backend interface with a no-op backend and a
  real windowed backend (Win32 lifecycle backend implemented).
- Keep DOM, JS, networking, and CDP independent from the window backend.

2. Window lifecycle
- Implement window creation, resize, close, and frame pump.
- Wire browser/page lifecycle events to the display backend.

3. Layout and paint pipeline
- Build incremental layout + paint passes from DOM/CSS state.
- Add dirty-region invalidation to avoid full-frame redraws.

4. Input + event synthesis
- Convert OS input events (mouse/keyboard/wheel/focus) into DOM events.
- Keep CDP input paths consistent with native input behavior.

5. Screenshots and surfaces
- Expose pixel surfaces for screenshots/recording while in headed mode.
- Ensure parity between headless and headed screenshot semantics.

6. Stabilization
- Add headed integration tests (window lifecycle, input, rendering, resize).
- Validate performance, memory, and crash-handling budgets.

## Design Constraints

- No regressions to existing headless CLI/CDP behavior.
- Feature flags must keep partial implementations safe.
- Keep platform-specific code isolated behind backend boundaries.
