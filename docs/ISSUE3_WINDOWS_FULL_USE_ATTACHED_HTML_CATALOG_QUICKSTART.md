# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

Use this note when `docs/WINDOWS_FULL_USE.md` has already narrowed the next
headed replay to attached localhost follow-up and you want the compact
top-level attached-page catalog quickstart visible immediately beside the
broader Windows full-use route.

This keeps the shortest current Windows-full-use-to-catalog path in one place
without reopening the broader suite-catalog, replay-route, or wrapper-heavy
safe-route notes first.

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

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from `show_google_issue3_windows_full_use_attached_html_route.ps1`, then
move into `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`
when the attached-page route is already in focus and you want the compact
top-level attached-page catalog quickstart surfaced before the replay narrows
into the suite-catalog bridge, the broader Google-shaped attached-page bridge,
the attached-page shortcut, replay shortcuts, or the safe-route map.

From there, prefer one of these narrower follow-ups before reopening the
wrapper-heavy safe route:

- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the attached localhost compatibility lane is already
obvious from the broader Windows full-use route and you want the compact
top-level attached-page catalog quickstart plus the suite-catalog attached-page
bridge visible before you choose between the narrower attached-page helper
chain, replay shortcuts, or the safe-route map.

## Route variants

If the replay still needs the broader Google-shaped attached-page route first,
start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use that route when the broader issue-specific attached-page bridge should stay
visible before you drop to the shorter attached-page shortcut or replay-shortcuts
surface.

If the current pages are already the pinned three-page compatibility bundle,
start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
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
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

## Pick the next helper quickly

1. Top-level attached HTML catalog quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
```

Use this when you want the compact top-level attached-page catalog quickstart
printed immediately after the broader Windows full-use route so the top-level
attached localhost chain stays visible before widening again.

2. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when you want the suite-catalog-side attached-page bridge printed
immediately after the catalog quickstart so the attached localhost route stays
visible before widening again.

3. Google attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
```

Use this when the replay still needs the broader Google-shaped attached-page
bridge visible before narrowing again.

4. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when you want the shortest attached-page bridge before widening into
replay shortcuts, the next-step matrix, or the safe-route map.

5. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the
tightest compact helper surface before deciding whether to widen again.

6. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use this when repo-root, summary, or pinned bundle context already matters and
the next helper surface should keep that replay state aligned before narrowing
again.

7. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay
should stay on the known three-page compatibility bundle before widening back
into the broader Google-only helper chain.

## Practical rule

Once `docs/WINDOWS_FULL_USE.md` or
`show_google_issue3_windows_full_use_attached_html_route.ps1` has already made
the attached localhost branch obvious, prefer
`show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`
before reopening the longer validation-chain notes again.

- no pinned bundle inputs and no saved replay state yet: go from the Windows
  full-use route to the Windows full-use catalog quickstart, then the top-level
  attached-page catalog quickstart, then the suite-catalog attached-page
  bridge, then the broader Google-shaped attached-page bridge, then the
  attached-page shortcut, then replay shortcuts, then the safe-route map
- broader Google-shaped attached-page surface still matters more than the
  generic shortcut chain: go from the Windows full-use route to
  `-ChangeArea google-attached-html`, then the Windows full-use catalog
  quickstart, then the top-level attached-page catalog quickstart, then the
  suite-catalog attached-page bridge, then the Google attached-page entrypoint
  before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper before
  widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the Windows
  full-use catalog quickstart with that same context first, then choose replay
  shortcuts, the next-step matrix, contextual flow, or the safe-route map only
  as needed

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
