# Issue #3 Validation-Router Attached HTML Surface Check

Use this note when issue `#3` replay is reopening from the broader headed validation router and you want a fail-fast check for the attached-localhost quickstart chain before trusting the narrower helper route.

This note matches `check_google_issue3_validation_router_attached_html_quickstart_surface.ps1`.

If you want that guard printed directly first, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
```

If the replay is already running from a non-default checkout, preserve that same repo root directly in the checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1 -RepoRoot '<repo-root>'
```

If you want the checked reference list in machine-readable form for later automation or wrapper scripts, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1 -Json
```

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`

## Goal

Start from the validation-router guard when the next replay depends on the issue `#3` attached-localhost helper chain and you want missing notes, moved helper scripts, or broken downstream route surfaces to fail fast before the route narrows again.

The checker verifies the current validation-router quickstart lane is still intact across:

- the broader Windows runbook reopening path
- the Windows replay quickstart note
- the attached-html change-area quickstart note and helper
- the validation-router attached-html quickstart note and helper
- the top-level attached-html quickstart, catalog quickstart, and bridge notes
- the suite-router attached-html quickstart note and helper
- the suite-catalog attached-html bridge note
- the replay-shortcuts helper, next-step matrix, and pinned bundle-first helper

## Default read-first sequence

Use this compact sequence when the replay is about to re-enter the validation-router attached-localhost branch and you want the guard to fail fast before the helper chain narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- the broader validation router already made attached localhost follow-up obvious
- you want the guard to confirm the written quickstarts, helpers, and bundle-first path are still present before trusting the narrower route
- the next replay will stay in the validation and regression control lane rather than widening back into the broader runtime-debugging path

## Windows full-use variant

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first, keep the broader Windows runbook route in front of the same guard:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

Use that route when the broader Windows headed runbook already made attached localhost replay the next obvious issue `#3` branch and you want the dedicated guard visible before the validation-router helper chain narrows again.

## Preserve replay context

If the replay already carries a non-default repo root or pinned bundle paths, keep that same context attached to the checker first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` or pinned `InputPath` values already matter to later helpers
- you want the checker to fail fast on the same checkout and route context the next replay will use

## Reading the result

- success: the checker prints `PASS` for every required note and helper path and exits with status `0`
- failure: the checker prints one or more `FAIL` lines, reports how many route paths are missing, and exits with status `1`
- JSON mode: the checker returns the same reference list with `checked_count`, `missing_count`, and the per-path `Exists` result so wrapper scripts can branch without scraping console text

## Practical rule

When issue `#3` replay is about to depend on the validation-router attached-html quickstart from a fresh checkout, from a different repo root, or after several small helper-note commits, run the surface checker first. If it fails, repair the missing note or helper before trusting the narrower attached-localhost route.