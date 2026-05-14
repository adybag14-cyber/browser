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

If the replay is already centered on the attached localhost branch from the broader validation router and you want the shortest bridge into the newer top-level attached-page quickstarts before reopening the wider issue-specific helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the validation-router attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Top-level router surfacing for attached localhost replay

Because `show_headed_validation_suites.ps1` now prints the issue `#3` top-level attached HTML route, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, and the bundle-first helper directly from the broader `google-recommended` and `google-input` entrypoints, reopen one of those top-level router surfaces first when attached localhost follow-up has become the next obvious branch but the replay has not been narrowed to `-ChangeArea attached-html` yet.

Keep `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` nearby when the replay is being reopened from `docs/WINDOWS_FULL_USE.md` first and you want that broader Windows runbook entrypoint to stay aligned with the narrower attached-page helper order described in this quickstart.

If the broader validation router already narrowed the replay to `-ChangeArea attached-html` and you want the shortest handoff into the compact top-level attached-page quickstarts before reopening the wider issue-specific helper chain, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the validation-router attached-page quickstart helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this route when you want the attached-page re-entry surfaced directly from the main validation catalog before you drop into the narrower issue-specific attached-page helper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1
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
- you still want the validation-router attached-page quickstart, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the suite-router attached-page quickstart, and the catalog quickstart visible before the route narrows again
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

If the replay still stays inside issue `#3` and you already know the next run should stay on the current shortcut surface, reopen the shortcut helper immediately after the catalog helper, the suite-router quickstart helper, the validation-router attached-page quickstart, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, or the suite-catalog attached-page bridge:

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

If you still want the fuller branch matrix before choosing between the handoff, replay-route, bundle-first, shortcut, or safe-route helpers, reopen the current next-step matrix after the catalog helper, the suite-router quickstart helper, the validation-router attached-page quickstart, the suite-router attached-page quickstart, those top-level router commands, the top-level shortcut bridge, the top-level attached-page bridge, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, or the suite-catalog attached-page bridge:

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