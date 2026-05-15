# Issue #3 Suite-Catalog Top-Level Attached HTML Catalog Quickstart

Use this note when the suite-catalog surface is already open and you want the replay-side attached HTML ladder plus the top-level attached HTML catalog quickstart visible together before the route narrows into the suite-catalog attached-page bridge or the shorter attached-page shortcuts.

If you want that compact suite-catalog-to-top-level route first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`

## Goal

Start from `show_google_issue3_suite_catalog_entrypoints.ps1` or from the broader suite catalog change-area surfaces, then move through the replay-side attached HTML quickstart, the validation-router attached-page quickstart, the compact top-level attached-page quickstart, and the top-level attached-page catalog quickstart before the route narrows into the suite-catalog attached-page bridge.

## Default read-first route

Use this route when no pinned bundle inputs, saved summary output, or non-default repo root needs to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:
- the suite-catalog surface already made attached localhost follow-up obvious
- you still want the replay-side attached HTML quickstart and the validation-router bridge visible before the route commits to the top-level attached-page catalog quickstart
- you want the suite-catalog attached-page bridge and the shorter attached-page shortcut kept nearby before the route widens again

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Pinned bundle-first route

If the current pages are already the known three-page compatibility bundle, keep the replay on that locked path before widening back into the broader issue `#3` helper stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Pick the next helper quickly

1. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when you want the suite-catalog-side attached-page bridge immediately after the top-level attached-page catalog quickstart.

2. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader Google-shaped attached-page bridge visible before narrowing again.

3. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the shortest attached-page bridge before widening into replay shortcuts, the next-step matrix, or the safe-route map.

4. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

5. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and the next helper surface should keep that replay state aligned before narrowing again.

6. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Once the suite-catalog surface already made attached localhost follow-up obvious, prefer the replay-side attached HTML quickstart, then the validation-router attached-page quickstart, then the compact top-level attached-page quickstart, then the top-level attached-page catalog quickstart before reopening the longer validation-chain notes.

- no pinned bundle inputs and no saved replay state yet: go from the suite-catalog surface to the replay-side attached HTML quickstart, then the validation-router bridge, then the compact top-level quickstart, then the top-level catalog quickstart, then the suite-catalog attached-page bridge, then the attached-page shortcut, then replay shortcuts
- broader Google-shaped attached-page surface still matters more than the generic shortcut chain: reopen the suite-catalog surface, then the top-level catalog quickstart, then the broader Google attached-page entrypoint before narrowing further
- explicit bundle paths already pinned: keep the bundle-first helper in front of the delegated bundle runner so the known three-page compatibility set stays fixed before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen this quickstart with that same context first, then choose the suite-catalog bridge, replay shortcuts, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
