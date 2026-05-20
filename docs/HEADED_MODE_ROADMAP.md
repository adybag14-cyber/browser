# Headed Mode Roadmap (Fork)

This fork targets full headed-mode browser usage while preserving Lightpanda's
current headless strengths.

For the full product plan from the current headed foundation to a
production-ready minimalist Zig browser, see
`docs/FULL_BROWSER_MASTER_TRACKER.md`.

## Current Status

- `--browser_mode headless|headed` is now accepted.
- `--headed` and `--headless` shortcuts are available.
- `browse` now defaults to `headed`, while `serve`, `fetch`, and `mcp` default to `headless` unless overridden.
- `browse` and headed `serve` now use the longer interactive HTTP timeout default (`30000` ms), while headless `serve`, `fetch`, and `mcp` keep the shorter `5000` ms default unless `--http_timeout` is set explicitly.
- On Windows targets, `headed` now starts a native window lifecycle backend.
- On non-Windows targets, `headed` still uses a safe headless fallback with warning.
- Startup diagnostics now distinguish successful headed activation from headed fallback and surface the target class, OS, profile directory, window size, timeout source, and browse/serve target context needed for local headed triage.
- `--window_width` / `--window_height` now drive window/screen/viewport values.
- Display runtime abstraction exists with page lifecycle hooks and a Win32 thread backend.
- CDP viewport APIs update runtime viewport (`Emulation.*Metrics*`, `Browser.setWindowBounds`).
- Win32 headed backend now forwards native mouse (down/up/move/wheel/hwheel), click, keydown/keyup, text input (`WM_CHAR`/`WM_UNICHAR`), IME result/preedit composition messages (`WM_IME_COMPOSITION`), back/forward mouse buttons, and window blur events into page input.
- Win32 headed backend now propagates native key repeat state into `KeyboardEvent.repeat`.
- Text control editing now includes caret-aware insertion paths, `Ctrl/Meta + A` select-all, word-wise keyboard edit/navigation shortcuts, textarea vertical/line navigation, `Tab`/`Shift+Tab` focus traversal with `tabindex` ordering, and native clipboard shortcuts (`Ctrl/Meta + C/X/V`, `Ctrl+Insert`, `Shift+Insert`, `Shift+Delete`) with cancelable clipboard event dispatch.
- Windows prereq checker + runbook added (`scripts/windows`, `docs/WINDOWS_FULL_USE.md`).

## Validation Quick Routes

Use the validation router when you want the smallest headed check already
committed on this branch:

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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html -InputPath "<saved-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle -InputPath "<bundle-html-or-folder>"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath "<saved-html-or-folder>"
```

When the replay is already narrowed to the attached-localhost lane, run the
replay quickstart surface check first and then the replay quickstart helper so
the launcher companion, the broader Google-shaped attached-page route, the
compact bundle-suite surface, and the pinned proof-route follow-up stay visible
on one smaller surface before the route widens again.

Current validation truth on this branch:

- bounded localhost navigation probes exist under `tmp-browser-smoke/wrapped-link/`
- bounded localhost stop/reload probes exist under `tmp-browser-smoke/stop-loading/`
- bounded localhost input probes exist under `tmp-browser-smoke/form-controls/`
- the router now surfaces a dedicated `google-form-controls-enter-order` gate for the smallest issue #3 shared Enter-submit checkpoint on the real headed surface
- the router now surfaces a broader `google-shared-enter-order` gate when issue #3 replay should stay on the reusable shared Enter-order ladder before widening back out to live Google or attached-page follow-up
- the router now surfaces first-line `rendering` probes for shared layout, screenshot timing, and visible headed surface checks before attached-page replay
- the router now surfaces first-line `network` probes for authenticated stylesheet and fetch-credentials regressions before attached-page replay
- the router now surfaces checkout-portable `browser-shell` first-line probes for tabs and settings behavior on the real headed window
- the router now surfaces a checkout-portable `popup` first-line probe for popup creation and named-target behavior on the real headed window
- the router now surfaces dedicated `google-attached-html` and `attached-html-target-bundle` routes for issue #3 attached-page replay, including the pinned three-page compatibility-bundle path
- the router now exposes suite-level `google-attached-html` and `attached-html-target-bundle` surfaces when the narrower attached-page helper lane should be reprinted without widening back out to the rest of the catalog first
- the router now also keeps the replay-attached fail-fast checker and shorter replay helper ladder visible through `scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1` and `scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1` so the launcher-companion and pinned proof-route bridges stay surfaced before bundle-first replay takes over
- the first-line navigation, stop-loading, input, rendering, network, browser-shell, and popup probes auto-resolve the repo root and built browser path from the current checkout
- `scripts/windows/show_headed_validation_suites.ps1` is the truthful router for current small Windows headed checks
- `scripts/windows/start_attached_pages_catalog.ps1` is the wrapper-backed localhost entrypoint for issue #3 attached-page replay, including sidecar audits, broader asset audits, manifest printing, and strict completeness gates before the browser is blamed
- that same attached-page helper lane now also preserves a caller-supplied preferred first page and auto-discovers nested `agent_files/` HTML inputs before the broader localhost replay handoff is staged
- `scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1` and `scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1` are the compact issue #3 launcher-companion surfaces when the replay should stay on the narrower attached-page helper lane
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` is the read-first companion when the replay should keep one Google-like attached page first through the localhost route
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` is the smaller bridge when the replay is already narrowed to the issue #3 attached localhost ladder and needs the next helper chain surfaced quickly
- `docs/WINDOWS_FULL_USE.md` now also keeps a plain `python -m http.server 8139 --bind 127.0.0.1` fallback loop for the same three-page attached bundle, stable viewport, disposable profile root, and per-page navigation or interaction checks when a run starts from a plain checkout before the helper surfaces are reopened
- saved or attached HTML follow-up should stay on the wrapper-backed localhost replay route in `docs/WINDOWS_FULL_USE.md`, not older wrapper-heavy note chains that predate the current router and launcher surfaces

Use `rendering` before attached-page replay when the current change touched layout, paint, screenshot timing, or other visible headed-surface behavior. Use `network` before attached-page replay when the current change touched shared subresource loading, authenticated asset fetches, or browser-managed request credentials.

Before starting the attached-pages localhost server or blaming the browser for
issue #3 replay, run the wrapper-backed launcher preflight from the current
branch surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest
```

Run the sidecar audit first so missing sibling `_files` directories fail fast,
run the broader asset audit second so local export drift stays visible, and use
the strict manifest command when replay should stay pinned to a fully closed
saved-page bundle before the browser is blamed.

When the current replay is already on the known three-page compatibility route,
keep this exact file set together from the start and prefer the Google Safety
Centre export as the initial page. That preferred-first-page choice now stays
intact through the narrower attached-page helper chain before the broader
localhost replay handoff opens the full bundle:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

See `docs/WINDOWS_FULL_USE.md` for the current Windows-first runbook, and use
`docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` plus
`docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` when issue #3 is already down
to the attached-page replay path.

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
