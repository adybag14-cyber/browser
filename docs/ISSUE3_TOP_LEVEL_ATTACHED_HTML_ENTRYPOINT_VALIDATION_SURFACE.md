# Issue #3 Top-Level Attached HTML Entrypoint Validation Surface

Use this note when issue `#3` replay is already narrowed to the broader
attached localhost HTML bridge and you want that route to fail fast before the
helper chain widens into replay-side, suite-catalog, shortcut, or bundle-first
follow-up.

The matching checker is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_entrypoint_validation_surface.ps1
```

If the replay is running from a non-default checkout, keep that same root
attached to the checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_entrypoint_validation_surface.ps1 -RepoRoot '<repo-root>'
```

Use `-Json` when another helper or automation step needs the exact missing-path
report instead of the human-readable output:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_entrypoint_validation_surface.ps1 -Json
```

## What it protects

This checker confirms that the broader top-level attached-html bridge still has
its note surface, Windows-first re-entry notes, replay-side notes, top-level
quickstarts, shortcut notes, bundle reference note, and the attached helper
scripts that the route expects before you trust:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Treat this checker as the route-level guard for the broader top-level
attached-html branch, the same way the replay-side and shortcut routes already
have their own fail-fast surface checks.

## Read-first sequence

Use this compact guard sequence when attached localhost follow-up is already the
obvious next branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_top_level_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Keep these companion notes nearby when you want the broader written route next
to the checker output:

- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`

## Practical rule

Run the checker first after branch updates, helper renames, or when replay is
re-entering from a different checkout. If it reports missing paths, repair that
surface before trusting the broader top-level attached-html route. If it passes,
continue into the top-level bridge or the narrower suite-router attached-html
quickstart with more confidence that the current route description still matches
the live branch.