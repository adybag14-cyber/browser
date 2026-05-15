# Issue #3 Replay Shortcuts

Use this note when `show_google_issue3_replay_shortcuts.ps1` is already the current helper surface and you want the written companion for its compact replay map on `fork/headed-mode-foundation`.

This guide keeps the broader Windows-first attached-page route, the narrower replay-side attached-page bridge, the top-level attached-page helpers, the suite-catalog guide, the next-step matrix, the bundle-first route, and the safe-route wrappers visible from one smaller note before the route widens again.

Keep these companion notes nearby:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`

## Default compact route

Use this route when no explicit bundle inputs, saved summary, or non-default repo root need to take priority first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Use that route when the replay still needs the broad issue `#3` picture visible long enough to choose whether the next useful move is Windows-first attached-page follow-up, the narrower replay-side attached-page bridge, the top-level attached-page ladder, the next-step matrix, or the wrapper-heavy safe-route surface.

## Windows replay attached-page bridge

If the replay is already clearly inside `show_google_issue3_replay_shortcuts.ps1` and the next step should stay on the Windows replay attached-page ladder for another beat, narrow through this bridge first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
```

Use that route when:
- the broader Windows full-use attached-page route still matters
- the replay-side fail-fast check should be rerun before trusting the narrower attached-page ladder
- you still want the Windows-side catalog step, the validation-router attached-page quickstart, and the top-level attached-page helpers visible before the route collapses into the smallest attached-page shortcut

## Context-preserving route

If `RepoRoot`, `SummaryPath`, or pinned `InputPath` values already matter, keep that same context attached to the next helper you open:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use the contextual flow helper when the next choice needs to preserve the current checkout root, saved summary, or explicit bundle inputs while you decide between the attached-page helpers, replay route, next-step matrix, or safe-route wrappers.

## Bundle-first route

When explicit `InputPath` values are already pinned to the known three-page compatibility bundle, keep the replay on that locked route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the next useful choice depends on whether the pinned bundle still reproduces the current headed issue `#3` state.

## Safe-route follow-up

When outputs may be stale or missing, prefer the fresh safe-route replay first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

When a saved `SummaryPath` already exists and those outputs are still trusted, reopen the wrapper against the current outputs instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```

After either wrapper names the current runner-patch state, use `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the exact next-step command map and `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` for the direct runner-field rules.

## Practical rule

Start from `show_google_issue3_replay_shortcuts.ps1` when the replay is already clearly inside issue `#3` and you want the smallest stable command surface that still keeps Windows-first attached-page follow-up, the top-level attached-page route, the bundle-first branch, and the wrapper-heavy safe-route map easy to reopen.

- broader Windows-first attached-page route still matters: reopen `show_google_issue3_windows_full_use_attached_html_route.ps1`, then `show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1`, then the replay-shortcuts Windows replay attached-page bridge
- replay-side attached-page ladder is already the best mental model: go straight from the replay-shortcuts bridge to `show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- saved summary or repo-root override already exists: reopen `show_google_issue3_contextual_flow.ps1` before choosing the next narrower helper
- explicit bundle paths are already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- current outputs may be stale: prefer the fresh safe-route replay wrapper before trusting narrower route notes

Only reopen the longer validation-chain notes after the route has narrowed as far as it can go through the smaller replay shortcuts and attached-page helpers.