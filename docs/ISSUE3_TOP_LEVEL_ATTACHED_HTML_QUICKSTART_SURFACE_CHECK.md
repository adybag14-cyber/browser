# Issue #3 Top-Level Attached HTML Quickstart Surface Check

Use this note when the replay is about to trust `show_google_issue3_top_level_attached_html_quickstart.ps1` and you want the matching fail-fast checker, nearby companion notes, and the smallest follow-up ladder written down in one place.

This note matches `check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1`.

## Goal

Run the surface check before leaning on the compact top-level attached localhost quickstart after helper, note, or attached-bundle guidance changes. The checker verifies that the quickstart still points at the expected issue `#3` note family, attached-page helpers, Google-shaped fallback helpers, bundle-aware surfaces, and later replay-route follow-ups.

Use the checker first when:
- the top-level attached-page quickstart is the next obvious route from `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- the replay is narrowing from the broader validation-router or suite-router attached-page helpers into the top-level quickstart
- the route is about to depend on the top-level attached-page bridge, the top-level shortcut-first bridge, the suite-router next-step matrix, or the bundle-first branch that the compact quickstart keeps nearby

## Read-First Command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1
```

If the replay already uses a non-default checkout, keep the same repo root attached to the checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
```

## Recommended Follow-Up

When the checker passes and no pinned bundle inputs or saved replay context need to take priority first, reopen the compact top-level route and then the broader top-level bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

When the replay is still carrying a saved summary, a non-default repo root, or explicit bundle inputs, keep that same context on the compact helper after the checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Keep These Nearby

- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Practical Rule

1. Rerun the top-level quickstart surface check before trusting the compact top-level attached-page route after nearby helper or note edits.
2. If the replay is still broad, keep `show_google_issue3_attached_html_change_area_quickstart.ps1`, `show_attached_html_validation_flow.ps1`, and `show_google_issue3_validation_router_attached_html_quickstart.ps1` visible before collapsing into the compact top-level route.
3. If the current attached-page set is still Google-shaped, keep `check_google_attached_html_validation_surface.ps1` and `show_google_attached_html_validation_flow.ps1` nearby before narrowing further.
4. If the replay is pinned to the known three-page compatibility bundle, reopen `show_google_issue3_attached_html_target_bundle_suite_surface.ps1` or `show_google_issue3_attached_bundle_first_entrypoint.ps1` before widening back into the broader helper stack.
5. After the checker passes, prefer `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, and only then widen back into shortcut, replay-shortcut, next-step-matrix, or safe-route helpers.
