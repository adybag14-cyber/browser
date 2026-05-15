# Issue #3 Suite-Catalog Entrypoints Guide

Use this note when the replay is entering issue `#3` from the suite-catalog
surface and you want one compact command map before the route narrows into the
replay-side attached HTML, validation-router, top-level attached-page,
shortcut-first, contextual-flow, replay-route, bundle-first, or safe-route
helpers.

The matching helper script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

If the suite-catalog surface or any attached-html sidecar may have moved, fail
fast before trusting the route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1 -RepoRoot '<repo-root>'
```

Run that checker first after branch updates, helper renames, or when replay is
resuming from a different checkout and you want the compact suite-catalog route
to catch missing notes or delegated helpers before the replay-side chain opens.

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached bundle paths, preserve that
context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

If the route is about to narrow through the shorter top-level shortcut branch,
also keep `docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md` and
`docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md` nearby so that shortcut-first ladder
stays aligned with the broader attached-page route instead of drifting into the
replay-side notes too early.

## Goal

Start from the suite-catalog entry surface, keep the broader
`show_headed_validation_suites.ps1` routes visible, then move through the
broader Windows full-use attached-page route when needed, its route-level
surface check, the Windows-to-validation-router bridge, the Windows full-use
attached-page catalog quickstart, the replay-side attached-html surface check,
the replay-side attached-html quickstart, the attached-html change-area
quickstart, the validation-router attached-page quickstart, the
suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog
attached-page bridge, the suite-router quickstart, the suite-router
attached-page quickstart, the top-level attached-page quickstart, the top-level
attached-page catalog quickstart, the top-level shortcut-first bridge, the
broader top-level attached-page bridge, the current Google flow helper, the
issue-specific attached-page bridge, the attached-page shortcut, replay
shortcuts, the next-step matrix, contextual flow, the suite-router handoff, the
replay route, and the bundle-first branch before the replay widens back into
the wrapper-heavy safe route.

## Top-level suite-catalog entrypoints

Use these when you want the suite catalog itself to choose the first branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Use `google-recommended` when you want the broader localhost-first issue `#3`
ladder.
Use `google-input` when the next replay might still need title,
homepage-fixture, submit-path, shared Enter-order, or live-trace gates.
Use `attached-html` when the route is already narrowed to attached-page
follow-up.
Use `google-attached-html` when the broader Google-shaped attached-page surface
still matters.
Use `attached-html-target-bundle` when the current inputs are already pinned to
the known three-page compatibility bundle.

## Recommended next helper

The helper chooses its default next step from current replay context:

- no pinned bundle inputs, repo-root override, or saved summary: prefer `show_google_issue3_replay_shortcuts.ps1`
- non-default repo root or saved summary already in play: prefer `show_google_issue3_contextual_flow.ps1`
- explicit bundle input paths already pinned: prefer `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use the helper script itself first when you want that recommendation printed
together with the wider suite-catalog route map.

## Default read-first bridge

Use this compact sequence when the replay is entering from the suite catalog and
no saved replay state needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when you want one written bridge that keeps the suite-catalog
surface, the suite-catalog surface check, the replay-side attached-html ladder,
the attached-html change-area quickstart, the validation-router quickstart, the
suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog
attached-page bridge, the suite-router quickstart, the suite-router attached-page
quickstart, the top-level attached-page quickstarts, the top-level
shortcut-first bridge, its shortcut companion notes, the broader top-level
attached-page bridge, the Google flow helper, the issue-specific attached-page
bridge, the attached-page shortcut, replay shortcuts, the next-step matrix,
contextual flow, the suite-router handoff, the replay route, the bundle-first
branch, and the safe-route map all visible before the replay narrows further.

## Windows-first re-entry

If the broader Windows runbook already made attached localhost follow-up the
next obvious issue `#3` branch, reopen the wider Windows-first route before the
suite-catalog guide narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

Use that route when you want the broader Windows-first surface check, the
Windows-to-validation-router bridge, the Windows-side catalog quickstart, the
replay-side attached-html quickstart, the suite-catalog guide, the
suite-catalog surface check, the validation-router quickstart, the
suite-catalog-to-top-level catalog quickstart, the suite-catalog attached-page
bridge, the suite-router attached-page quickstart, the top-level attached-page
quickstarts, and the top-level shortcut-first bridge printed before the replay
falls back into the narrower attached-page helper chain.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or
pinned bundle inputs, keep that same context attached to the suite-catalog
helper and the narrower follow-ups:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_windows_replay_attached_html_quickstart.ps1`

Use this when the replay already narrowed to the Windows replay attached
localhost lane and you want the replay-side attached-html ladder visible before
the top-level helpers.

2. `show_google_issue3_attached_html_change_area_quickstart.ps1`

Use this when the replay already narrowed through the replay-side attached-html
quickstart and you want the shorter attached-page change-area bridge visible
before the validation-router quickstart or the top-level note family.

3. `show_google_issue3_validation_router_attached_html_quickstart.ps1`

Use this when the replay is re-entering from the broader validation router and
you want the shortest bridge into the narrower attached-page ladder.

4. `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`

Use this when the suite-catalog surface is already open and you want the
replay-side attached-html ladder plus the top-level attached-page catalog
quickstart visible together before the route narrows.

5. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when you want the suite-catalog surface to stay focused on
attached-page follow-up before deciding whether to narrow into the attached-page
shortcut, replay shortcuts, or the bundle-first branch.

6. `show_google_issue3_suite_router_quickstart.ps1`

Use this when the top-level suite router already made issue `#3` obvious and
you want the shortest bridge into replay shortcuts, the next-step matrix, the
bundle-first helper, and the safe-route map.

7. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route is already narrowed to attached localhost follow-up
from the top-level suite router and you want the shortest suite-router-side
attached-page bridge before choosing between the narrower helpers.

8. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when the route is already clearly inside the top-level attached-page
lane and you want the shortest top-level attached-page bridge kept visible
before the broader top-level and shortcut helpers.

9. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level attached-page plus suite-catalog-side
bridge visible before you decide whether to widen again.

10. `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`

Use this when the route is already known to stay inside issue `#3` and you want
the shorter top-level bridge before the replay narrows into the tighter helper
chain, while keeping the top-level shortcut companion notes aligned with the
broader attached-page route.

11. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader top-level attached-page bridge
visible before narrowing again.

12. `show_google_input_validation_flow.ps1`

Use this when the localhost-first Google flow helper still needs to stay visible
before the route narrows further.

13. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader Google-shaped attached-page
bridge visible before narrowing again.

14. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when you want the shortest attached-page bridge before widening into
replay shortcuts, the next-step matrix, or the safe-route map.

15. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the
tightest compact helper surface before deciding whether to widen again.

16. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you want the executable branch matrix reprinted after the
suite-catalog attached-page bridge before choosing the narrower replay surface.

17. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and
the next helper surface should keep that replay state aligned.

18. `show_google_issue3_suite_router_handoff.ps1`

Use this when you want the wider compact bridge that keeps the exact
suite-router entrypoints beside the current replay helpers before narrowing
further.

19. `show_google_issue3_replay_route.ps1`

Use this when you want the smaller replay-route companion after the shorter
issue `#3` helper chain is already in view.

20. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay
should stay on the known three-page compatibility bundle before widening back
into the broader Google-only issue `#3` path.

21. `show_google_issue3_safe_route_entrypoints.ps1`

Use this when the attached-page branch is already out of the way and you want
the current wrapper-heavy issue `#3` path, notes, and next-state helpers
surfaced in one place.

## Practical rule

Start from the suite-catalog surface, then keep the broader suite-catalog
entrypoints, the suite-catalog surface check, the broader Windows full-use
attached-page route when needed, its route-level surface check, the
Windows-to-validation-router bridge, the Windows-side catalog quickstart, the
replay-side attached-html surface check, the replay-side attached-html
quickstart, the attached-html change-area quickstart, the validation-router
attached-page quickstart, the suite-catalog-to-top-level attached-page catalog
quickstart, the suite-catalog attached-page bridge, the suite-router
attached-page quickstart, the top-level attached-page quickstarts, the
top-level shortcut-first bridge, the top-level shortcut companion notes, the
broader top-level attached-page bridge, the Google flow helper, the
issue-specific attached-page bridge, the attached-page shortcut, replay
shortcuts, the next-step matrix, contextual flow, the suite-router handoff, the
replay route, the bundle-first branch, and the safe-route map visible before
reopening the longer validation-chain notes.

- branch just moved or helper names may have drifted: rerun the suite-catalog surface checker before the broader replay-side checker so the compact route fails fast on missing notes or delegated helpers
- no pinned bundle inputs and no saved replay state yet: go from the suite-catalog helper to replay shortcuts when you only need the tightest current helper surface, or reopen the broader attached-html ladder first when attached localhost follow-up is already obvious
- broader Windows-first route already in view: rerun the Windows full-use attached-page route, its route-level surface check, the Windows-to-validation-router bridge, the Windows-side catalog quickstart, the replay-side attached-html surface check, the replay-side attached-html quickstart, and the suite-catalog surface checker before returning to the suite-catalog helper
- broader Google-shaped attached-page surface still matters: reopen `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` before the narrower helper chain
- explicit bundle paths already pinned: keep `show_google_issue3_attached_bundle_first_entrypoint.ps1` in front of the delegated bundle runner so the known three-page compatibility set stays fixed before widening back into the broader issue `#3` path
- saved summary or repo-root override already present: reopen this guide with the same context first, rerun the suite-catalog surface checker for that checkout, then choose contextual flow, replay shortcuts, the suite-router handoff, replay route, or the safe-route map only as needed

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
