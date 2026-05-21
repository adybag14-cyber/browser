# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

Use this note when `docs/WINDOWS_FULL_USE.md` has already narrowed the next headed replay to attached localhost follow-up and you want one compact Windows-first route that keeps the broader attached-page ladder, the wrapper-backed attached-pages preflight, the launcher-companion guard and helper, and the replay-side quickstarts visible together.

This route is intentionally sidecar-first, then asset-audit, then strict manifest gating, then launcher-companion reprint, then replay. That keeps missing export bundles and missing local assets visible before the browser gets blamed for the next failure.

Keep these companion notes and launcher surfaces nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `tmp-browser-smoke/attached-pages/README.md`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/windows/start_attached_pages_catalog.ps1`
- `scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1`
- `scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the broader Windows full-use attached-page route, rerun the route and catalog surface checks, reopen the attached HTML and Google attached HTML change areas, and then keep the wrapper-backed attached-pages preflight ladder visible in this order:

1. sidecar audit
2. asset audit
3. strict asset-gated manifest print
4. launcher companion surface check plus helper reprint
5. replay-side attached-page quickstart

When the current inputs still look Google-shaped, keep the wrapper-backed Google-style sidecar audit, the dedicated Google attached-page surface check, the issue-specific Google attached-page entrypoint, and the flow helper nearby. When the current inputs are already the pinned three-page bundle, keep the bundle suite surface and bundle-first entrypoint nearby.

## Default read-first sequence

Use this when no explicit bundle paths, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the attached localhost lane is already obvious and you want the export-integrity checks, the stricter local-asset manifest gate, the launcher companion surface check, the launcher companion helper, the replay-side quickstart, the Google-shaped wrapper-backed sidecar preflight, the dedicated Google-shaped fallback, and the bundle re-entry helpers all visible before the route narrows further.

## Google-shaped variant

Use this when the current attached inputs are already Google-shaped and you want to keep the Google route visible in the same wrapper-backed preflight order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the dedicated Google-shaped guide should remain the main nearby fallback, but you still want the cheaper sidecar and asset preflight steps plus the launcher companion guard/helper before trusting the narrower replay ladder.

## Bundle-pinned variant

Use this when the current pages are already the known three-page compatibility bundle and you want to keep the same pinned inputs through the wrapper-backed preflight before replay narrows into the bundle-specific helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<bundle-html-or-folder>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<bundle-html-or-folder>' -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<bundle-html-or-folder>' -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known bundle should stay pinned before widening back into the broader issue `#3` helper chain.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -RequireCompleteAssets -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Practical rule

Once `docs/WINDOWS_FULL_USE.md` or `show_google_issue3_windows_full_use_attached_html_route.ps1` has already made the attached localhost branch obvious, rerun the route and catalog surface checks, reopen the attached-page ladders, then prefer the wrapper-backed sidecar audit, the wrapper-backed asset audit, the strict asset manifest gate, the launcher companion surface check, and the launcher companion helper before trusting the replay-side quickstart. When the inputs still look Google-shaped, keep the wrapper-backed Google-style sidecar audit, the dedicated Google surface check, the dedicated Google flow helper, and the issue-specific Google entrypoint visible before narrowing into the shorter issue `#3` helper chain. Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path or after the bundle and Google-shaped follow-up helpers have clarified the next failure state.
