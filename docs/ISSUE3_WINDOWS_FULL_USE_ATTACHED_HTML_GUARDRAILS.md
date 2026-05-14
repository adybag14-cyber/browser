# Issue #3 Windows Full-Use Attached HTML Guardrails

Use this note when you are starting from `docs/WINDOWS_FULL_USE.md` and the next replay is already centered on the attached localhost HTML compatibility branch for issue `#3`, but you want the current route guardrails rechecked before the helper chain narrows.

This keeps the two fail-fast surface checks and the shorter attached-page bridges on one page so future Windows replay can reopen the route without rediscovering which checker belongs in front of which helper.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`

## Fail fast first

Start with the Windows full-use route checker before trusting the broader attached-page route after helper renames, note moves, or branch refreshes:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
```

If the replay is already running from a non-default checkout, preserve that repo root directly in the checker:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1 -RepoRoot '<repo-root>'
```

Then recheck the narrower validation-router attached-page bridge before it drops into the compact top-level helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
```

If the replay is already running from a non-default checkout, preserve that repo root there too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1 -RepoRoot '<repo-root>'
```

Use `-Json` on either checker when a wrapper or another script needs the result to fail closed without reading the formatted text output.

## Default guardrail-first route

Use this compact sequence when the broader Windows runbook has already made attached localhost replay the next obvious issue `#3` branch and you want the route guardrails checked before the helper chain narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

Use that route when:

- the replay is already on the attached localhost compatibility lane
- you want the broad Windows runbook route and the narrower validation-router bridge both checked before trusting the helper chain
- you still want the attached-html change-area quickstart and the compact top-level attached-page quickstart visible before the route narrows further into the catalog-side or shortcut-side helpers

## Preserve replay context

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, keep that same context attached to the helper chain after the guard checks pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle
- the next helper surface should keep the replay state aligned instead of silently falling back to repo-default assumptions

## Pick the next helper quickly

1. `check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1`

Use this first when the replay is reopening from the broad Windows full-use attached-page branch and you want the current route note plus its nearby helper surfaces verified before the helper chain narrows.

2. `show_google_issue3_windows_full_use_attached_html_route.ps1`

Use this next when the broader Windows runbook already narrowed replay to attached localhost follow-up and you want the shorter route map reprinted before the helper chain drops to the validation-router bridge.

3. `check_google_issue3_validation_router_attached_html_quickstart_surface.ps1`

Use this next when the replay is about to leave the broader Windows route and you want the narrower validation-router attached-page bridge to fail fast on missing notes, helper scripts, or route surfaces before trusting it.

4. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this next when the top-level validation router still matters and you want the shortest bridge from that broader surface into the compact top-level attached-page quickstarts.

5. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this next when the broader route has already dropped back to `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the issue `#3` attached-page bridge that still keeps the broader change-area framing visible.

6. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this next when the route is already ready to stay on the compact top-level attached-page quickstart before it widens into the catalog quickstart, the broader top-level attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route map.

## Practical rule

When `docs/WINDOWS_FULL_USE.md` has already narrowed the next replay to attached localhost follow-up, run the Windows full-use attached-page route checker first, reopen `show_google_issue3_windows_full_use_attached_html_route.ps1`, then run the validation-router attached-page surface checker before dropping into `show_google_issue3_validation_router_attached_html_quickstart.ps1`, the attached-html change-area quickstart, and the compact top-level attached-page quickstart.

If the current replay is already pinned to a non-default repo root, a saved summary, or explicit bundle paths, keep that same context attached to the helper commands immediately after the checkers pass so the route stays aligned with the current replay state instead of widening back into repo-default assumptions.