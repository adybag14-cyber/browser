# Issue #3 Validation-Router Attached HTML Quickstart

Use this note when you are re-entering issue `#3` from the broader headed validation router and want the shortest stable bridge into the newer attached localhost helper chain before reopening the longer replay notes.

This note matches `show_google_issue3_validation_router_attached_html_quickstart.ps1`.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`

## Goal

Start from one of the broader validation-router surfaces:
- `show_headed_validation_suites.ps1 -SuiteName google-recommended`
- `show_headed_validation_suites.ps1 -ChangeArea google-input`
- `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`

Then move into `show_google_issue3_validation_router_attached_html_quickstart.ps1` so the route narrows through the compact top-level attached-page quickstarts instead of jumping straight back into the longer replay stack.

## Default read-first route

Use this compact sequence when no non-default repo root, saved summary, or explicit bundle inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:
- the broader validation router already made attached localhost follow-up obvious
- you want the newer top-level attached-page quickstarts visible before the route narrows into replay shortcuts or the next-step matrix
- you do not need repo-root, saved-summary, or pinned-input context to steer the next helper first

## Context-preserving variants

If a non-default repo root or saved summary already matters, reopen the broader issue `#3` bridge first so the same context stays attached before the route narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

If explicit bundle inputs are already pinned to the current three-page compatibility set, keep that same input path attached from the start and prefer the bundle-first branch before widening back into the broader helper stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use those forms when:
- `LIGHTPANDA_REPO_ROOT` must stay aligned through later helpers
- a saved `SummaryPath` already points at the current replay outputs
- explicit `InputPath` values are already pinned to the known attached three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this as the default follow-up when no pinned bundle inputs, non-default repo root, or saved summary need to steer the route first.

2. `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`

Use this when you want the compact top-level quickstart and the suite-catalog attached-page bridge kept visible together before the route narrows again.

3. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when you want the broader top-level attached-page bridge reprinted beside the compact quickstarts before reopening replay shortcuts or the next-step matrix.

4. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route should stay on the suite-router side of the attached-page helper chain before choosing between the catalog quickstart, catalog bridge, shortcut entrypoint, or replay shortcuts.

5. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page path is already clear and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, or the safe-route map.

6. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest helper surface before deciding whether to widen again.

7. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after the validation-router quickstart before choosing the narrower replay surface.

8. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit bundle inputs are already pinned or when the next replay should stay on the current three-page compatibility set before widening back into the broader helper chain.

## Practical rule

When the broader headed validation catalog already made attached localhost follow-up the next obvious branch, run `show_google_issue3_validation_router_attached_html_quickstart.ps1` first, then prefer the compact top-level attached-page quickstarts before reopening the longer replay and safe-route notes.

Only widen back into the broader wrapper-heavy issue `#3` route after the top-level attached-page quickstart, catalog quickstart, or bundle-first branch has narrowed the next move enough to make that wider surface useful again.
