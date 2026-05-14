# Issue #3 Windows Replay Quickstart

Use this note when you want the shortest current replay path for issue `#3` on `fork/headed-mode-foundation` without reopening the longer routing notes first.

Keep these companion notes nearby when the replay needs more detail:
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md`

## Read-first discovery

Use this helper first when you are re-entering issue `#3` from the higher-level headed validation catalog and want the top-level suite-router entrypoints plus the current replay helpers printed together before choosing the narrower live branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the catalog helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the top-level suite router already made issue `#3` obvious and you want the shortest bridge from that router into the newer replay helpers without reopening the wider catalog helper first, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the suite-router quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you still want the exact top-level suite-router commands surfaced directly from the main validation catalog, use:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

Use `-ChangeArea attached-html` when the current replay is already centered on the attached localhost compatibility pages and you want the main validation catalog to print that broader attached-page branch before you drop into the issue-specific attached-page bridge, the replay shortcuts, the next-step matrix, or the pinned bundle-first route.

## Top-level router surfacing for attached localhost replay

Because `show_headed_validation_suites.ps1` now prints the issue `#3` top-level attached HTML route, the compact top-level attached-page quickstart, and the bundle-first helper directly from the broader `google-recommended` and `google-input` entrypoints, reopen one of those top-level router surfaces first when attached localhost follow-up has become the next obvious branch but the replay has not been narrowed to `-ChangeArea attached-html` yet.

Use this route when you want the attached-page re-entry surfaced directly from the main validation catalog before you drop into the narrower issue-specific attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

Use that route when:
- the broader issue `#3` router already made attached localhost follow-up obvious
- you still want the compact top-level attached-page quickstart and the broader top-level attached-page bridge visible before the suite-router attached-page quickstart narrows the route again
- the bundle-first helper should remain easy to reopen from that same top-level surface before you widen back into the wrapper-heavy path

If the replay is already narrowed to the attached localhost route from the main suite router and you want the shortest suite-router-side attached-page bridge before reopening the wider issue-specific helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the suite-router attached-page quickstart:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` nearby when you want the written version of that same suite-router-side attached-page route beside the quickstart.

If the top-level suite router already narrowed the replay to issue `#3` and you want the shortest top-level shortcut bridge that still keeps the attached localhost branch visible beside the replay helpers, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the top-level shortcut bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md` nearby when the route is already clearly inside issue `#3` and you want the written shortcut-first bridge that matches the narrower helper order in this quickstart before reopening the broader router or safe-route notes.

If the replay is already narrowed to the attached localhost route and you want the shorter top-level attached-page bridge before reopening the wider catalog helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the top-level attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` nearby when you want the written version of that same route beside the quickstart.

If the replay is already narrowed to the attached localhost route from the top-level suite router and you want the shortest top-level helper that keeps the suite-router attached-page quickstart visible before widening back into the broader replay surfaces, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the top-level attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` nearby when you want the written version of that same compact top-level attached-page route beside the quickstart.

If the replay is already narrowed to the attached localhost route but you want the suite-catalog-side attached-page bridge kept visible before reopening the wider helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the suite-catalog attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` nearby when you want the written version of that suite-catalog-side attached-page route beside the quickstart.

If the replay still stays inside issue `#3` and you already know the next run should stay on the current shortcut surface, reopen the shortcut helper immediately after the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, or the suite-catalog attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

When those top-level suite-router commands are pointing at the current attached three-page compatibility bundle, stay on the pinned bundle-first route before reopening the broader wrapper-heavy issue `#3` helpers:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
```

If you still want the fuller branch matrix before choosing between the handoff, replay-route, bundle-first, shortcut, or safe-route helpers, reopen the current next-step matrix after the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, or the suite-catalog attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the matrix helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If RepoRoot, a saved SummaryPath, or fixed bundle inputs are already in play and you want the broader issue `#3` route kept on one context-preserving command surface before narrowing again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the contextual helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

After the contextual flow or the matrix narrows the route, reopen the shortcut surface when you want the tighter branch back into the live helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you want that same read-first bridge plus the current replay-shortcuts, bundle-first, and safe-route-map helpers printed together in one place, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1
```

If you want the broader localhost-first issue `#3` ladder printed before you choose between the newer safe-route wrappers and the narrower later-stage probes, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1
```

If you want those read-first commands plus the attached three-page bundle branch, the current safe-route map, and the repo-root-aware runner next-step helper printed together in one place, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1
```

If the replay is running from a non-default checkout or from an already-saved summary, preserve that context directly in the replay-route helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

If the replay-route helper is already open and you want the shortest follow-up back into the narrower attached-page, replay-shortcuts, bundle-first, or safe-route surfaces without reopening the broader route notes first, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If the replay is already carrying a non-default checkout, an already-saved summary, or an explicit bundle path, preserve that same context directly in the replay-route shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` nearby when you want the written version of that narrower replay-route follow-up beside the quickstart.

If the replay is running from a non-default checkout or from an already-saved summary, preserve that context directly in the suite-router handoff helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

These match the `read_first_*` commands printed by `show_google_issue3_safe_route_entrypoints.ps1`.

Use them in this order when helpful:
- `show_google_issue3_suite_catalog_entrypoints.ps1` when you want the exact top-level suite-router entrypoints and the current issue `#3` replay helpers surfaced together before choosing the narrower branch
- `show_google_issue3_suite_router_quickstart.ps1` when the top-level suite router already made issue `#3` obvious and you want the shortest bridge from that router into the newer replay helpers without reopening the wider catalog helper first
- `-SuiteName google-recommended` when you want the top-level suite router to surface the broader issue `#3` runner and its companion checkpoints first, then jump straight to `show_google_issue3_suite_router_quickstart.ps1`, `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, or `show_google_issue3_top_level_attached_html_quickstart.ps1` when the attached localhost route is already the next obvious branch, or jump straight to `-ChangeArea attached-html-target-bundle` when the current inputs are the pinned three-page compatibility bundle
- `-ChangeArea google-input` when you may need to branch into a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice instead of the broader recommended replay, and when the attached localhost route is already the next obvious branch reopen `show_google_issue3_top_level_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_entrypoint.ps1`, or `show_google_issue3_suite_router_attached_html_quickstart.ps1` immediately after the router output; when the next run already knows it should stay on the current shortcut surface reopen `show_google_issue3_suite_router_quickstart.ps1`, `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, or `show_google_issue3_replay_shortcuts.ps1` instead; when the current inputs are the pinned three-page compatibility bundle prefer `-ChangeArea attached-html-target-bundle` before the broader wrapper-heavy helpers
- `-ChangeArea attached-html` when the current replay is already centered on the attached localhost compatibility pages and you want the main validation catalog to print the broader attached-page route before you branch into the suite-router attached-page quickstart, the issue-specific attached-page bridge, the top-level shortcut bridge, the top-level attached-page quickstart, the replay shortcuts, the next-step matrix, or the pinned bundle-first route
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` when the replay is already narrowed to the attached localhost route from the main suite router and you want the shortest suite-router-side bridge before deciding between the suite-catalog attached-page bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the top-level suite router already narrowed the replay to issue `#3` and you want the shortest top-level shortcut bridge that still keeps the attached localhost branch visible beside the replay helpers
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` when the replay is already narrowed to the attached localhost route and you want the shortest top-level attached-page bridge into the issue-specific attached-page helper, the top-level attached-page quickstart, replay-route shortcut, replay shortcuts, the next-step matrix, or the pinned bundle-first branch without reopening the wider suite-catalog surface first
- `show_google_issue3_top_level_attached_html_quickstart.ps1` when the replay is already narrowed to the attached localhost route from the top-level suite router and you want the shortest top-level helper that keeps the suite-router attached-page quickstart visible before choosing between the issue-specific attached-page bridge, replay shortcuts, the next-step matrix, contextual flow, the bundle-first helper, or the safe-route map
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` when the replay is already narrowed to the attached localhost route but you want the suite-catalog-side attached-page bridge kept visible before widening into the Google attached-page entrypoint, the attached-page shortcut, replay shortcuts, the next-step matrix, contextual flow, the bundle-first helper, or the safe-route map
- `show_google_issue3_replay_route.ps1` when you want the same read-first bridge plus the attached three-page bundle branch, the current safe-route map, and the repo-root-aware runner next-step helper preserved together in one route
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the replay-route helper is already open and you want the narrowest stable bridge into the attached-page shortcut, replay shortcuts, bundle-first helper, or safe-route entrypoints before reopening the broader handoff notes again
- `show_google_issue3_replay_shortcuts.ps1` when the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, the top-level suite router, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the suite-catalog attached-page bridge, or the replay-route shortcut helper already narrowed the replay enough that you want the tightest current shortcut surface immediately, or when the matrix or contextual flow has already narrowed the replay back inside issue `#3` and you want that same tight shortcut surface before deciding whether to widen into the handoff, replay-route, bundle-first, or safe-route helpers
- `show_google_issue3_suite_router_next_steps.ps1` when you want the fastest command matrix from the top-level suite router before deciding between the handoff, replay-route, bundle-first, shortcut, or safe-route branches
- `show_google_issue3_contextual_flow.ps1` when RepoRoot, SummaryPath, or fixed bundle inputs are already in play and you want the broader issue `#3` route kept on one context-preserving command surface before deciding between replay shortcuts, the later-stage probes, the attached-bundle route, or the wrapper-heavy safe-route helpers
- `show_google_issue3_suite_router_handoff.ps1` when you want the suite-router read-first commands plus the current replay-shortcuts, bundle-first, and safe-route-map helpers surfaced together before you decide whether the next replay should stay broad or narrow
- `show_google_input_validation_flow.ps1` when you want the current localhost-first issue `#3` ladder printed before you choose between the newer safe-route wrappers and the narrower later-stage probes
- `-ChangeArea attached-html-target-bundle` when the next replay should stay pinned to the known three-page compatibility bundle before you reopen the broader attached-page or wrapper-heavy issue `#3` helpers, and treat it as the default follow-up from `-SuiteName google-recommended` or `-ChangeArea google-input` whenever the current inputs match that pinned bundle

## One-command entrypoints map

Use this helper when you want the current issue `#3` safe-route commands printed in one place before choosing the next replay step:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
```

If the replay is running from a non-default checkout or from an already-saved summary, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```
