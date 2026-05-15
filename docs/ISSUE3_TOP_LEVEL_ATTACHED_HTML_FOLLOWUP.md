# Issue #3 Top-Level Attached HTML Follow-Up

Use this note when issue `#3` replay has already narrowed to `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want one compact follow-up surface that keeps the broader attached-page flow helper, the compact top-level quickstart, the broader top-level attached-page bridge, the direct attached-page shortcut, and the next-step matrix visible together before the route widens back into the wrapper-heavy safe path.

If you want that route printed directly first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_followup.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_followup.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Start from the generic attached localhost route surfaced by `show_headed_validation_suites.ps1 -ChangeArea attached-html`, then move through `show_google_issue3_top_level_attached_html_followup.ps1` when the next replay is already known to stay on the attached-page follow-up path but still needs the broader attached-page flow helper and the shorter direct attached-page shortcut kept visible beside the newer top-level attached-page helper chain.

From there, prefer one of these narrower follow-ups before reopening the broader wrapper-heavy safe route:

- `show_attached_html_validation_flow.ps1`
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`

## Default read-first sequence

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_followup.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the top-level validation router has already narrowed replay to attached localhost follow-up and you want the broader attached-page flow helper, the compact top-level quickstart, the broader top-level attached-page bridge, the shorter attached-page shortcut, and the next-step matrix visible before the route widens again.

## Bundle-first variant

If the current pages are still the pinned three-page compatibility bundle, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_followup.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay pinned from the attached-html change-area route into the bundle-first branch before widening back into the broader issue `#3` helper stack.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the follow-up helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_followup.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
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

3. Top-level attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use this when you want the broader top-level attached-page bridge reprinted before the shorter follow-up helpers.

4. Top-level shortcut-first entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

Use this when the replay is already narrowed enough that the shortest top-level shortcut bridge is the most useful follow-up.

5. Suite-router attached HTML quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use this when the route should stay closer to the suite-router-side attached-page branch before widening again.

6. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when the suite-catalog-side attached-page bridge should stay visible before you narrow again.

7. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening back into the next-step matrix or the safe-route map.

8. Suite-router next-step matrix

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Use this when you want the executable branch matrix reprinted after the follow-up helper before choosing the narrower replay surface.

9. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

10. Safe-route entrypoints

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this when the route has already narrowed enough that the wrapper-heavy issue `#3` command surface is the next useful layer.

## Practical rule

Once `show_headed_validation_suites.ps1 -ChangeArea attached-html` has already made attached localhost follow-up the next obvious branch, prefer `show_google_issue3_top_level_attached_html_followup.ps1` before reopening the longer validation-chain notes again.

- replay reopened from `docs/WINDOWS_FULL_USE.md`: go from the Windows full-use attached-page route to `-ChangeArea attached-html`, then the top-level attached-html follow-up helper, then the broader attached-page flow helper or the compact top-level attached-page quickstart before narrowing again
- no pinned bundle inputs and no saved replay state yet: go from `-ChangeArea attached-html` to the follow-up helper, then the broader attached-page flow helper, then the compact top-level quickstart, then the top-level attached-page bridge, then the direct attached-page shortcut, then the next-step matrix, then the safe-route map
- explicit bundle paths already pinned: stay on the bundle-first helper after the follow-up helper so the known three-page compatibility set stays fixed before widening back into the broader Google-only path
- saved summary or repo-root override already present: reopen the follow-up helper with that same context first, then choose the broader flow helper, the compact top-level quickstart, the broader top-level attached-page bridge, the next-step matrix, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
