# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

Use this note when `docs/WINDOWS_FULL_USE.md` has already narrowed the next
headed replay to attached localhost follow-up and you want the compact
Windows-first attached-page catalog quickstart plus the replay-side attached
HTML surface check and quickstart visible immediately beside the broader
Windows full-use route.

This keeps the shortest current Windows-full-use-to-catalog path in one place
without reopening the broader suite-catalog, replay-route, or wrapper-heavy
safe-route notes first, while still keeping the broader attached-page flow
helper, the attached-pages launcher guide, the attached-pages launcher
entrypoint, the Windows wrapper-backed sidecar preflight, the dedicated
Google-shaped attached-page surface check and flow helper, the newer Top-level
shortcut bridge, the replay-route shortcut bridge, and the compact
attached-bundle suite surface visible before the route narrows again.

If you want that route printed directly from the broader Windows headed context
before reopening the newer top-level catalog quickstart, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached bundle paths, preserve that
same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

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
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `show_google_issue3_windows_full_use_attached_html_route.ps1`, rerun
`check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`,
move through `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`,
then reopen both `show_headed_validation_suites.ps1 -ChangeArea attached-html`
and `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` before
moving into `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`
and keep `show_attached_html_validation_flow.ps1`, the launcher-backed
`python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars`
preflight, `check_google_attached_html_validation_surface.ps1`,
`show_google_attached_html_validation_flow.ps1`,
`check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`,
`show_google_issue3_windows_replay_attached_html_quickstart.ps1`,
`show_google_issue3_top_level_shortcut_first_entrypoint.ps1`,
`show_google_issue3_replay_route_shortcut_entrypoint.ps1`, and
`show_google_issue3_attached_html_target_bundle_suite_surface.ps1` visible
before the replay narrows into the newer top-level attached-page catalog
quickstart, the suite-catalog-to-top-level attached-page catalog quickstart,
the suite-catalog bridge, the broader Google-shaped attached-page bridge, the
attached-page shortcut, replay shortcuts, or the safe-route map.

Before you trust the narrower Windows-first catalog ladder itself, rerun its
dedicated fail-fast checker so the route note, companion replay quickstart,
companion top-level catalog quickstarts, suite-catalog bridge, Google-shaped
fallback, and bundle re-entry helpers are all still present on the branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
```

Before you trust the saved export enough to widen back into the replay-side or
Google-shaped attached-page ladder, rerun the Windows wrapper-backed sidecar
audit too so a missing sibling `_files` bundle fails fast before deeper replay
diagnosis starts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
```

If the replay is already running from a non-default checkout or from explicit
bundle paths, preserve that context on the same preflight:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditSidecars
```

Use the lower-level Python launcher directly only when you need to bypass the
wrapper while keeping the same sidecar-first preflight pinned to the current
repo root or bundle inputs:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<bundle-html-or-folder>' --audit-sidecars
```

Before you trust the narrower replay-side attached-page ladder that follows,
rerun its dedicated fail-fast checker too so replay-note or helper drift stops
here instead of deeper in the attached localhost route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
```

From there, prefer one of these narrower follow-ups before reopening the
wrapper-heavy safe route:

- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars`
- `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `show_attached_html_validation_flow.ps1`
- `check_google_attached_html_validation_surface.ps1`
- `show_google_attached_html_validation_flow.ps1`
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
- `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root,
or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<attached-html-root>' --audit-sidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
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

Use that route when the attached localhost compatibility lane is already
obvious from the broader Windows full-use route and you want the route-level
fail-fast surface check, the validation-router attached-html bridge, the compact
Windows-first attached-page catalog quickstart, the shared attached-html and
Google-attached-html suite surfaces, the replay-side attached-page surface
check, the replay-side attached-page quickstart, the broader attached-page and
Google-shaped flow helpers, the launcher-backed sibling `_files` sidecar-bundle
audit, the broader Google-shaped attached-page surface check, the newer
Top-level shortcut bridge, the replay-route shortcut bridge, the compact
attached-bundle suite surface, the top-level attached-page catalog quickstart,
the suite-catalog-to-top-level attached-page catalog quickstart, and the
suite-catalog attached-page bridge visible before you choose between the
narrower attached-page helper chain, replay shortcuts, or the safe-route map.

## Route variants

If the replay still needs the broader Google-shaped attached-page route first,
start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars
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

Use that route when the broader issue-specific attached-page bridge should stay
visible before you drop to the shorter attached-page shortcut or replay-shortcuts
surface, but you still want the cheaper launcher-backed sidecar-bundle audit to
run before the broader Google-shaped checker and flow helper take over.

If the current pages are already the pinned three-page compatibility bundle,
start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<bundle-html-or-folder>' --audit-sidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the known three-page compatibility set should
stay pinned before widening back into the broader issue `#3` helper stack.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or
pinned bundle paths, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<bundle-html-or-folder>' --audit-sidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page
  compatibility bundle

## Preflight sidecar audit

Run this first when the broader Windows full-use route is already obvious and
you want the cheapest honest export-integrity check before replay widens into
the Google-shaped or replay-side helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
```

Use the repo-root-preserving form when the replay is already running from a
non-default checkout or pinned bundle paths:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -AuditSidecars
```

If you need the lower-level launcher directly instead of the Windows wrapper,
keep the same sidecar-audit intent and replay context:

```powershell
python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --repo-root '<repo-root>' --input '<bundle-html-or-folder>' --audit-sidecars
```

## Pick the next helper quickly

1. Windows replay attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

Use this when you want the replay-side attached-page quickstart printed
immediately after the broader Windows full-use route so the replay-side helper
ladder stays visible before widening again. Rerun the dedicated replay-side
surface check first so missing replay notes or helper drift fail fast before
the shorter ladder starts.

2. Broader attached HTML flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

Use this when you want the broader attached-page localhost helper printed
beside the Windows-first route before the replay narrows into the shorter issue
`#3` helpers.

3. Google attached HTML surface check

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
```

Use this when the current attached inputs are already Google-shaped and you
want the broader fail-fast checker rerun before the dedicated Google-shaped
flow helper or the issue-specific entrypoint take over.

4. Google attached HTML flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use this when the current attached inputs are already Google-shaped and you
want the dedicated attached-page asset-closure helper visible before the route
narrows again.

5. Top-level attached HTML catalog quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
```

Use this when you want the compact top-level attached-page catalog quickstart
printed immediately after the broader Windows full-use route so the top-level
attached localhost chain stays visible before widening again.

6. Top-level shortcut bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

Use this when you want the newer top-level shortcut bridge reprinted before the
route collapses into the shorter attached-page shortcut surface.

7. Replay-route shortcut bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use this when you want the replay-route companion surface reprinted before the
route widens into replay shortcuts, the next-step matrix, or the bundle-first
branch.

8. Attached bundle suite surface

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

Use this when the replay is already close to the known three-page compatibility
bundle but you still want the compact suite-level surface printed before the
bundle-first helper takes over.

9. Suite-catalog top-level attached HTML catalog quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
```

Use this when you want the suite-catalog-side bridge into the replay-side and
top-level attached-page catalog ladder printed immediately after the top-level
catalog quickstart so the narrower suite-catalog route stays visible before it
drops into the suite-catalog attached-page bridge.

10. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when you want the suite-catalog-side attached-page bridge printed
immediately after the catalog quickstarts so the attached localhost route stays
visible before widening again.

11. Google attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use this when the replay still needs the broader Google-shaped attached-page
bridge visible before narrowing again.

12. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the shortest attached-page bridge before widening into
replay shortcuts, the next-step matrix, or the safe-route map.

13. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the
tightest compact helper surface before deciding whether to widen again.

14. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use this when repo-root, summary, or pinned bundle context already matters and
the next helper surface should keep that replay state aligned before narrowing
again.

15. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay
should stay on the known three-page compatibility bundle before widening back
into the broader Google-only helper chain.

## Practical rule

Once `docs/WINDOWS_FULL_USE.md` or
`show_google_issue3_windows_full_use_attached_html_route.ps1` has already made
the attached localhost branch obvious, rerun
`check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`,
then reopen `show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1`,
then rerun
`check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1`,
then `show_headed_validation_suites.ps1 -ChangeArea attached-html`,
then `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`,
then prefer `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`,
then `show_attached_html_validation_flow.ps1`,
then `powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars`,
then `check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1`,
then `show_google_issue3_windows_replay_attached_html_quickstart.ps1`,
then `check_google_attached_html_validation_surface.ps1`,
then `show_google_attached_html_validation_flow.ps1`,
then `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`,
then `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`,
then `show_google_issue3_replay_route_shortcut_entrypoint.ps1`,
then `show_google_issue3_attached_html_target_bundle_suite_surface.ps1`,
then `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`
before reopening the longer validation-chain notes again.

- no pinned bundle inputs and no saved replay state yet: go from the Windows
  full-use route to the fail-fast surface check, then the Windows full-use
  validation-router bridge, then the attached-page catalog quickstart surface
  check, then the shared attached-html suite surface, then the
  Google-attached-html suite surface, then the Windows full-use catalog
  quickstart, then the broader attached-page flow helper, then the
  launcher-backed sidecar-bundle audit, then the replay-side attached-html
  surface check, then the replay-side attached-html quickstart, then the
  broader Google-shaped attached-page surface check, then the dedicated
  Google-shaped attached-page flow helper, then the top-level attached-page
  catalog quickstart, then the newer Top-level shortcut bridge, then the
  replay-route shortcut bridge, then the compact attached-bundle suite surface,
  then the suite-catalog top-level attached-page catalog quickstart, then the
  suite-catalog attached-page bridge, then the broader Google-shaped attached-
  page bridge, then the attached-page shortcut, then replay shortcuts, then the
  safe-route map
- broader Google-shaped attached-page surface still matters more than the
  generic shortcut chain: go from the Windows full-use route to the fail-fast
  surface check, then the Windows full-use validation-router bridge, then the
  attached-page catalog quickstart surface check, then
  `-ChangeArea google-attached-html`, then
  `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`,
  then `python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars`,
  then `check_google_attached_html_validation_surface.ps1`,
  then `show_google_attached_html_validation_flow.ps1`, then the replay-side
  attached-html surface check, then the replay-side attached-html quickstart,
  then the top-level attached-page catalog quickstart, then the newer Top-level
  shortcut bridge, then the replay-route shortcut bridge, then the suite-catalog
  top-level attached-page catalog quickstart, then the suite-catalog attached-
  page bridge, then the Google attached-page entrypoint before narrowing
  further
- explicit bundle paths already pinned: stay on the validation-router bridge,
  the attached-page catalog quickstart surface check, the Windows full-use
  catalog quickstart, the launcher-backed sidecar-bundle audit, the replay-side
  attached-html surface check, the replay-side attached-html quickstart, the
  compact attached-bundle suite surface, and the bundle-first helper before
  widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the Windows
  full-use validation-router bridge, attached-page catalog quickstart surface
  check, Windows full-use catalog quickstart, the broader attached-page flow
  helper, the launcher-backed sidecar-bundle audit, the replay-side attached-
  html surface check, replay-side attached-html quickstart, the broader
  Google-shaped attached-page surface check, the dedicated Google-shaped
  attached-page flow helper, the top-level shortcut bridge, the replay-route
  shortcut bridge, and the compact bundle suite surface with that same context
  first, then choose replay shortcuts, the next-step matrix, contextual flow,
  or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
