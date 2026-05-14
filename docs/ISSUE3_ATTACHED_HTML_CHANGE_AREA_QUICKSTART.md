# Issue #3 Attached HTML Change-Area Quickstart

Use this note when issue `#3` replay is already narrowed to `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the shortest current bridge from that top-level attached localhost route into the newer attached-page helper chain.

If you want that route printed directly first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Start from the generic attached localhost route surfaced by `show_headed_validation_suites.ps1 -ChangeArea attached-html`, then move through `show_google_issue3_attached_html_change_area_quickstart.ps1` when the next replay is already known to stay on the attached-page follow-up path but still needs the broader attached-page flow helper, the compact top-level quickstart, and the shorter replay helpers kept visible together.

From there, prefer one of these narrower follow-ups before reopening the broader wrapper-heavy safe route:

- `show_attached_html_validation_flow.ps1`
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the top-level validation router has already narrowed replay to attached localhost follow-up and you want the broader attached-page flow helper, the compact top-level quickstart, the suite-router attached-page quickstart, and the shorter replay surfaces visible before the route widens again.

## Top-level router variants

If the replay is reopening from `docs/WINDOWS_FULL_USE.md` first and you want the broader Windows-first route surfaced before this attached-html change-area quickstart, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when the broader Windows headed runbook already made attached localhost follow-up the next obvious issue `#3` branch and you want the Windows-full-use helper plus the newer attached-html change-area route aligned on one read-first path.

If the replay still needs the broader Google-shaped attached-page surface first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use that route when the replay still needs the Google-style attached-page surface checker and flow helper kept visible before you drop to the shorter attached-page shortcut or replay shortcuts.

If the current pages are still the pinned three-page compatibility bundle, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that bundle-first route when the known three-page compatibility set should stay pinned from the attached-html change-area route into the bundle-first branch before widening back into the broader issue `#3` helper stack.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the attached-html change-area helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. Attached HTML validation flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
```

Use this when you want the broader attached-page localhost flow helper visible from the same `-ChangeArea attached-html` route before narrowing into issue-specific helper surfaces.

2. Top-level attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
```

Use this when the route is already narrowed enough that the compact top-level attached-page bridge is the next best helper.

3. Suite-router attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use this when the route should stay closer to the suite-router-side attached-page branch before widening again.

4. Top-level attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use this when you want the broader top-level attached-page bridge reprinted before the shorter follow-up helpers.

5. Top-level shortcut-first entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

Use this when the replay is already narrowed enough that the shortest top-level shortcut bridge is the most useful follow-up.

6. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when the suite-catalog-side attached-page bridge should stay visible before you narrow again.

7. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening back into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.

8. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

9. Suite-router next-step matrix

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Use this when you want the executable branch matrix reprinted after the attached-html change-area helper before choosing the narrower replay surface.

10. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
```

Use this when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.

11. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

12. Safe-route entrypoints

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the route has already narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical rule

Once `show_headed_validation_suites.ps1 -ChangeArea attached-html` has already made attached localhost follow-up the next obvious branch, prefer `show_google_issue3_attached_html_change_area_quickstart.ps1` first, then keep the broader attached-page flow helper or the compact top-level attached-page quickstart visible before narrowing back into the shorter issue `#3` replay surfaces.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: go from the Windows full-use attached-page route to `-ChangeArea attached-html`, then the attached-html change-area quickstart, then the top-level attached-page quickstart, then the suite-router attached-page quickstart before narrowing again
- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the attached-html change-area quickstart, then the broader attached-page flow helper, then the compact top-level quickstart, then replay shortcuts, then the safe-route map
- Google-specific attached-page surface still matters more than the generic shortcut chain: go from `-ChangeArea google-attached-html` to the attached-html change-area quickstart, then the top-level attached-page quickstart, then the broader top-level attached-page bridge before narrowing further
- explicit bundle paths already pinned: stay on the bundle-first helper after the attached-html change-area quickstart so the known three-page compatibility set stays fixed before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the attached-html change-area quickstart with that same context first, then choose the broader flow helper, the top-level quickstart, replay shortcuts, the next-step matrix, contextual flow, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
