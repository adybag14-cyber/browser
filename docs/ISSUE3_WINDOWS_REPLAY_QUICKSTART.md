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
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
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

Because `show_headed_validation_suites.ps1` now prints the issue `#3` top-level attached HTML route, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the bundle-first helper directly from the broader `google-recommended` and `google-input` entrypoints, reopen one of those top-level router surfaces first when attached localhost follow-up has become the next obvious branch but the replay has not been narrowed to `-ChangeArea attached-html` yet.

Keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` nearby when the replay is being reopened from `docs/WINDOWS_FULL_USE.md` first and you want that broader Windows runbook entrypoint to stay aligned with the narrower attached-page helper order described in this quickstart.

Use this route when you want the attached-page re-entry surfaced directly from the main validation catalog before you drop into the narrower issue-specific attached-page helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If you are arriving from `docs/WINDOWS_FULL_USE.md` rather than the replay quickstart itself, reopen `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` or print its companion helper first and then follow the same top-level router sequence so the broader Windows runbook and this narrower replay note stay in sync:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
```

Use that route when:
- the broader issue `#3` router already made attached localhost follow-up obvious
- you still want the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the suite-router attached-page quickstart, and the catalog quickstart visible before the route narrows again
- the suite-catalog-side attached-page bridge and the bundle-first helper should remain easy to reopen from that same top-level surface before you widen back into the wrapper-heavy path

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

If the replay is already narrowed to the attached localhost route and you want the compact top-level attached-page quickstart plus the suite-catalog-side attached-page bridge kept visible together before the helper chain narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the top-level attached-page catalog quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md` nearby when you want the written version of that same compact top-level attached-page plus suite-catalog route beside the quickstart.

If the replay is already narrowed to the attached localhost route but you want the suite-catalog-side attached-page bridge kept visible before reopening the wider helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the suite-catalog attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` nearby when you want the written version of that suite-catalog-side attached-page route beside the quickstart.

If the replay still stays inside issue `#3` and you already know the next run should stay on the current shortcut surface, reopen the shortcut helper immediately after the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, or the suite-catalog attached-page bridge:

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

If you still want the fuller branch matrix before choosing between the handoff, replay-route, bundle-first, shortcut, or safe-route helpers, reopen the current next-step matrix after the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, or the suite-catalog attached-page bridge:

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
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` when the broader Windows runbook has already narrowed the replay to attached localhost follow-up and you want the shortest written bridge from `docs/WINDOWS_FULL_USE.md` into the suite-router attached-page quickstart, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, replay shortcuts, and the safe-route entrypoints without reopening the broader suite-catalog helper first
- `-SuiteName google-recommended` when you want the top-level suite router to surface the broader issue `#3` runner and its companion checkpoints first, then jump straight to `show_google_issue3_suite_router_quickstart.ps1`, `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, `show_google_issue3_top_level_attached_html_quickstart.ps1`, or `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` when the attached localhost route is already the next obvious branch, or jump straight to `-ChangeArea attached-html-target-bundle` when the current inputs are the pinned three-page compatibility bundle
- `-ChangeArea google-input` when you may need to branch into a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice instead of the broader recommended replay, and when the attached localhost route is already the next obvious branch reopen `show_google_issue3_top_level_attached_html_quickstart.ps1`, `show_google_issue3_top_level_attached_html_entrypoint.ps1`, `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`, or `show_google_issue3_suite_router_attached_html_quickstart.ps1` immediately after the router output; when the next run already knows it should stay on the current shortcut surface reopen `show_google_issue3_suite_router_quickstart.ps1`, `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`, or `show_google_issue3_replay_shortcuts.ps1` instead; when the current inputs are the pinned three-page compatibility bundle prefer `-ChangeArea attached-html-target-bundle` before the broader wrapper-heavy helpers
- `-ChangeArea attached-html` when the current replay is already centered on the attached localhost compatibility pages and you want the main validation catalog to print the broader attached-page route before you branch into the suite-router attached-page quickstart, the issue-specific attached-page bridge, the top-level shortcut bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the replay shortcuts, the next-step matrix, or the pinned bundle-first route
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` when the replay is already narrowed to the attached localhost route from the main suite router and you want the shortest suite-router-side bridge before deciding between the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map
- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the top-level suite router already narrowed the replay to issue `#3` and you want the shortest top-level shortcut bridge that still keeps the attached localhost branch visible beside the replay helpers
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` when the replay is already narrowed to the attached localhost route and you want the shortest top-level attached-page bridge into the issue-specific attached-page helper, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, replay-route shortcut, replay shortcuts, the next-step matrix, or the pinned bundle-first branch without reopening the wider suite-catalog surface first
- `show_google_issue3_top_level_attached_html_quickstart.ps1` when the replay is already narrowed to the attached localhost route from the top-level suite router and you want the shortest top-level helper that keeps the suite-router attached-page quickstart, the top-level attached-page catalog quickstart, and the suite-catalog attached-page bridge visible before choosing between the issue-specific attached-page bridge, replay shortcuts, the next-step matrix, contextual flow, the bundle-first helper, or the safe-route map
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1` when the replay is already narrowed to the attached localhost route and you want the compact top-level attached-page quickstart plus the suite-catalog-side attached-page bridge kept visible together before the route narrows again
- `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1` when the replay is already narrowed to the attached localhost route but you want the suite-catalog-side attached-page bridge kept visible after the top-level attached-page catalog quickstart before widening into the Google attached-page entrypoint, the attached-page shortcut, replay shortcuts, the next-step matrix, contextual flow, the bundle-first helper, or the safe-route map
- `show_google_issue3_replay_route.ps1` when you want the same read-first bridge plus the attached three-page bundle branch, the current safe-route map, and the repo-root-aware runner next-step helper preserved together in one route
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the replay-route helper is already open and you want the narrowest stable bridge into the attached-page shortcut, replay shortcuts, bundle-first helper, or safe-route entrypoints before reopening the broader handoff notes again
- `show_google_issue3_replay_shortcuts.ps1` when the catalog helper, the suite-router quickstart helper, the suite-router attached-page quickstart, the top-level suite router, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, or the replay-route shortcut helper already narrowed the replay enough that you want the tightest current shortcut surface immediately, or when the matrix or contextual flow has already narrowed the replay back inside issue `#3` and you want that same tight shortcut surface before deciding whether to widen into the handoff, replay-route, bundle-first, or safe-route helpers
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

Use this when you want the helper to print the current:
- fresh replay command
- reuse-current-outputs command
- refresh-status safe-path route
- handoff-safe helper
- summary-guide safe helper
- runner-wiring safe helper
- runner-patch next-step helper for `ready-for-runner-patch`, `already-direct`, and `runner-already-wired-regenerate-outputs`

## Attached Three-Page Bundle Route

When the next replay should stay pinned to the current attached HTML compatibility bundle before widening back into the wrapper-heavy issue `#3` safe route, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit saved-page set, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

That helper prints the same bundle-first commands plus the return-to-safe-route command in one place. The underlying route is still:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
```

These match the attached-bundle commands printed by `show_google_issue3_safe_route_entrypoints.ps1`.

Use this route when:
- the current saved or attached pages are the known three-page compatibility bundle
- you want the pinned bundle surface check, flow helper, and delegated localhost runner to keep the same locked inputs all the way through replay
- you want to return to `show_google_issue3_safe_route_entrypoints.ps1` only after the bundle replay makes the next Google-style input or submit failure state clear

## Default fresh replay

Start here when current issue `#3` outputs may be stale or missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

Why this is the default:
- reruns the recommended issue `#3` validation flow
- preserves the newest runner-patch handoff artifact
- narrows the next move to one of three states instead of reopening the full helper chain by hand

## State helper

Use this after the fresh replay or reuse-current-outputs wrapper tells you which state you landed on:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State ready-for-runner-patch
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State already-direct
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State runner-already-wired-regenerate-outputs
```

If the replay is already running from a non-default checkout or from an already-saved summary, preserve that context directly in the state helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State ready-for-runner-patch
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State already-direct
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -State runner-already-wired-regenerate-outputs
```

Use that form when the safe-route wrapper already narrowed the replay inside a non-default checkout or a reused summary, so the state helper keeps the same replay context on its recovery commands.

Use it when you want the exact next commands printed without reopening the longer decision table first.

## If the current saved outputs are already trustworthy

Use this reopen-only wrapper instead of a fresh replay:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```

Use this only when you intentionally want to reuse the current saved outputs and reopen the safe-route guidance without another broader run first.

## State to next move

### `ready-for-runner-patch`

Meaning:
- the replay still needs a direct edit in `scripts/windows/run_google_issue3_recommended_validation.ps1`

Do this next:
1. Open `tmp-browser-smoke\\headed-probe\\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json` first.
2. Keep `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` and `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` open beside that artifact before editing the runner.
3. Patch both saved output writers in `scripts/windows/run_google_issue3_recommended_validation.ps1`.
4. Keep these fields present in both objects:
   - `refresh_chain_artifact_path`
   - `refresh_chain_artifact_error`
   - `handoff_artifact_path`
   - `handoff_artifact_error`
5. Re-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status.ps1
```

### `already-direct`

Meaning:
- the runner source already carries the direct contract fields that the wrapper expected

Do this next:
- do not patch `scripts/windows/run_google_issue3_recommended_validation.ps1` again
- reopen the safe wiring audit immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
```

### `runner-already-wired-regenerate-outputs`

Meaning:
- the source is already wired, but the saved outputs still need regeneration or repair

Do this next:
1. Treat it as an output-refresh problem, not another direct source edit.
2. Prefer the emitted repair command from the wrapper artifact.
3. If you want the stable default repair route, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1
```

## After the runner-output contract is green

Continue with the next safe route instead of widening immediately:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_refresh_status_safe_path_route.ps1
```

If the refresh and wiring helpers agree that the chain is ready, only then widen into the attached or saved localhost HTML follow-up from `docs/WINDOWS_FULL_USE.md`.

## Repo-root note

If the replay is running from a non-default checkout, keep `LIGHTPANDA_REPO_ROOT` and the current summary path aligned through the safe wrappers. Use `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md` before reopening the runner-output or refresh-status checkpoints when the working tree location changed.
