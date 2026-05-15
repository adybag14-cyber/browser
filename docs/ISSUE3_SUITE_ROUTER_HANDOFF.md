# Issue #3 Suite-Router Handoff

Use this note when issue `#3` replay is re-entering from the higher-level suite router and you want one compact written bridge before the route narrows into the attached localhost helpers, replay shortcuts, suite-catalog guide, replay-route helper, or the bundle-first branch.

This note matches `show_google_issue3_suite_router_handoff.ps1`.

If you want the compact handoff surface first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby:

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`

## Goal

Start from the higher-level suite-router surface, keep the attached localhost change-area route, the suite-router attached-page quickstart, the top-level attached-page quickstart, the broader top-level attached-page bridge, the shortcut-first bridge, the replay shortcuts, the next-step matrix, the suite-catalog guide, the replay-route helper, and the bundle-first branch visible together long enough to choose the next narrower helper deliberately.

Prefer one of these narrower follow-ups before reopening the longer wrapper-heavy safe-route notes:

- `show_google_issue3_suite_router_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
- `show_google_issue3_replay_shortcuts.ps1`
- `show_google_issue3_suite_router_next_steps.ps1`
- `show_google_issue3_suite_catalog_entrypoints.ps1`
- `show_google_issue3_replay_route.ps1`
- `show_google_issue3_contextual_flow.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`

## Read-first bridge

Use this compact sequence when no explicit bundle inputs, non-default repo root, or saved summary state need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

Use that route when the broader suite router already made issue `#3` obvious and you want the attached-page route, the narrower suite-router attached-page bridge, the top-level attached-page helpers, the shortcut-first bridge, the replay shortcuts, the next-step matrix, the suite-catalog guide, the broader Google flow helper, the replay-route helper, and the bundle-first branch all visible before the route narrows again.

## Attached localhost handoff

If the replay is already narrowed to attached localhost follow-up and you want the shortest handoff into the written attached-page ladder before returning to replay shortcuts or the next-step matrix, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the attached-page branch is already clear and you want the suite-router-side quickstart, the top-level attached-page quickstart, the broader top-level attached-page bridge, the shortcut-first bridge, and the narrower replay-shortcuts surface kept aligned on one smaller handoff.

## Suite-catalog re-entry

If the route still needs the wider suite-catalog guide visible before it narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when you want the wider suite-catalog entry surface reprinted without losing the narrower attached-page bridge that the suite router already surfaced.

## Replay-route and bundle re-entry

If the next replay should widen slightly before narrowing again, use one of these routes:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use the replay-route handoff when you still want the attached bundle and safe-route map kept on one slightly broader surface before narrowing again.
Use the bundle-first handoff when the current saved or attached pages are still the known three-page compatibility bundle and the replay should stay pinned there first.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle paths, keep that same context attached to the suite-router handoff first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then choose the narrower follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Use this as the default follow-up when no pinned bundle inputs, repo-root override, or saved summary need to steer the route first.

2. `show_google_issue3_top_level_attached_html_quickstart.ps1`

Use this when the route is already clearly inside the top-level attached-page lane and you want the shortest top-level bridge kept visible before narrowing again.

3. `show_google_issue3_top_level_attached_html_entrypoint.ps1`

Use this when the broader top-level attached-page bridge should stay visible beside replay shortcuts or the next-step matrix before the route narrows again.

4. `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

Use this when you want the shortest shortcut-first bridge reprinted before replay shortcuts or the bundle-first branch take over.

5. `show_google_issue3_replay_shortcuts.ps1`

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

6. `show_google_issue3_suite_router_next_steps.ps1`

Use this when you still want the executable branch matrix reprinted after the attached-page bridges before choosing the narrower replay surface.

7. `show_google_issue3_suite_catalog_entrypoints.ps1`

Use this when the wider suite-catalog entry surface still needs to stay visible beside the narrower suite-router handoff.

8. `show_google_issue3_replay_route.ps1`

Use this when you want the slightly broader replay-route handoff before dropping back into the shorter replay-route shortcut or safe-route map.

9. `show_google_issue3_contextual_flow.ps1`

Use this when repo-root, summary, or pinned bundle context already matters and the next helper surface should keep that replay state aligned.

10. `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the current three-page compatibility set before widening back into the broader helper chain.

## Practical rule

Once the higher-level suite router has already made issue `#3` obvious, prefer the attached localhost route, then `show_google_issue3_suite_router_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, then `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, and then `show_google_issue3_replay_shortcuts.ps1` before reopening the longer validation-chain notes.

- broader suite-router context still matters: keep `show_google_issue3_suite_catalog_entrypoints.ps1` and `show_google_issue3_suite_router_next_steps.ps1` nearby before the route collapses further
- replay should widen slightly before narrowing again: reopen `show_google_issue3_replay_route.ps1` before dropping to replay-route shortcuts or the safe-route map
- explicit bundle paths already pinned: keep `show_google_issue3_attached_bundle_first_entrypoint.ps1` in front of the delegated bundle runner so the known three-page compatibility set stays locked through replay
- saved summary or repo-root override already present: pass that same context through the suite-router handoff first, then choose contextual flow or the narrower attached-page helpers only as needed

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.