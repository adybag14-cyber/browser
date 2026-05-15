# Issue #3 Top-Level Shortcut-First Entrypoint

Use this note when issue `#3` replay is re-entering from the top-level headed validation catalog and you want the shortest written bridge into the narrower issue-specific helper chain before the route widens again.

This note matches `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`

## Goal

Start from the higher-level validation router, keep the top-level shortcut bridge visible, and only reopen the broader attached-page notes when the replay is clearly narrowing into attached localhost follow-up.

Use this note when:
- the route is already clearly inside issue `#3` and you want the shortest top-level bridge first
- the route may narrow into attached localhost follow-up next, but you do not want to reopen the longer attached-page note family too early
- you still want the replay-side, suite-router, and suite-catalog companion notes easy to reach from one written entrypoint

## Shortcut-first bridge

If you want the shortest top-level issue `#3` bridge, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this when the top-level router already made it clear that the replay stays inside issue `#3`, but you still want the shorter attached-page helpers nearby in case the route narrows there next.

## Broader router surfacing

If you want the broader validation-router surfaces visible before the shortcut-first bridge narrows the route, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```
```

Use that route when the replay is still re-entering from the shared validation catalog and you want the broader Google lane reprinted before the top-level shortcut-first bridge hands off to the narrower issue `#3` helpers.

## Attached HTML handoff

If attached localhost follow-up is already the next obvious branch, keep the shorter attached-page ladder visible before the route drops back into the narrower shortcut helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the replay is already centered on the attached-page compatibility branch and you want the top-level attached-page quickstart, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the broader top-level shortcut-first bridge, the attached-page shortcut, and the narrower suite-router shortcut-first helper all kept on the same written ladder.

## Google-shaped attached HTML handoff

If the replay still needs the broader Google-shaped attached-page surface visible before the route narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

Use that route when the replay still needs the Google-specific attached-page surface checker and helper flow visible before it collapses back into the shorter issue `#3` route.

## Bundle-first route

If the current pages are still the pinned three-page compatibility bundle, keep that route visible first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the known three-page compatibility set should stay explicit before the replay widens back into the broader issue `#3` helper chain.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the helper you reopen next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:
- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this as the default follow-up when the route is already clearly inside issue `#3` and no attached-page-specific branch needs to stay visible first.

2. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when attached localhost follow-up is already obvious and you want the shorter top-level attached-page bridge before the suite-router attached-page quickstart or the broader attached-page notes.

3. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this when the route has already narrowed to attached-page follow-up and you want the suite-router-side attached-page bridge reprinted before the suite-catalog bridge, the attached-page shortcut, replay shortcuts, or the next-step matrix.

4. `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`

Use this when the suite-catalog-side attached-page bridge should stay visible before the route narrows again.

5. `show_google_issue3_attached_html_shortcut_entrypoint.ps1`

Use this when the attached-page compatibility branch itself should stay visible before the route widens back into replay shortcuts or the safe-route map.

6. `show_google_issue3_google_attached_html_entrypoint.ps1`

Use this when the replay still needs the broader Google-shaped attached-page helper visible before it narrows again.

7. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clear and you want the narrowest stable helper surface.

8. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle state already matters and the next helper should keep that replay context aligned.

9. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after the top-level shortcut-first bridge before choosing the narrower replay surface.

10. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Start from the top-level headed validation catalog, then use `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3`. If attached localhost follow-up becomes the next obvious branch, reopen `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_suite_router_attached_html_quickstart.ps1`, then `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`, and only then narrow into `show_google_issue3_attached_html_shortcut_entrypoint.ps1` or `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`. Stay on the bundle-first route whenever explicit bundle inputs are already pinned, and only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
