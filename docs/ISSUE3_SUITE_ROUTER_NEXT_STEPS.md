# Issue #3 Suite Router Next Steps

Issue `#3` now has several small read-first helpers that sit between the top-level
Windows validation router, the newer attached-page branches, and the narrower
safe-route replay chain.

This note is the compact decision guide for choosing the right next helper after
opening one of the higher-level validation entrypoints.

## Start here

Open one of the high-level issue `#3` entrypoints first:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1
```

If you want the helper to choose the fastest correct follow-up for you, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
```

Before trusting the printed matrix after helper or note edits, rerun the fail-fast checks that protect the current route surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
```

Use those checks when:
- the suite-router next-step note or helper output just changed and you want the compact decision surface to fail fast before reuse
- the replay is about to narrow into the broader Google-shaped attached-page route and you want that wider helper surface revalidated first
- the replay is about to narrow from the broader Google-shaped attached-page route into the issue-specific entrypoint and you want the narrower checker rerun before trusting that bridge

## Next-step matrix

Use these defaults after the top-level router:

1. `show_headed_validation_suites.ps1 -SuiteName google-recommended`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

2. `show_headed_validation_suites.ps1 -ChangeArea google-input`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`

3. `show_headed_validation_suites.ps1 -ChangeArea attached-html`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1`

4. `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1`

5. `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1`

6. `show_google_issue3_suite_router_handoff.ps1`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1`

7. `show_google_issue3_replay_route.ps1`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1`

8. Saved summary or current pinned context already in play
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1`

9. Context-preserving late-stage handoff
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1`

10. Safe-route wrapper emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`
    Next helper:
    `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>`

## Preserve replay context

When the replay is already using a non-default checkout, a saved summary, or a
pinned three-page compatibility bundle, carry that same context through the
next helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

That same context should stay attached when you reopen the handoff,
replay route, replay-route shortcut, replay shortcuts, contextual flow,
validation-router attached-html quickstart, suite-router attached-html
quickstart, attached-html flow helper, Google attached-html surface check,
Google attached-html flow helper, Google-attached-html entrypoint,
attached-bundle-first helper, safe-route entrypoints, or runner next-step
helper.

If the replay is already carrying a non-default checkout, keep that same repo root on the fail-fast checks too:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1 -RepoRoot '<repo-root>'
```

## When to choose each branch

- Use `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when you want the shorter issue `#3` bridge immediately after the higher-level suite router before deciding whether to widen into replay shortcuts, contextual flow, the replay-route shortcut, or the bundle-first path.
- Use `show_google_issue3_suite_router_handoff.ps1` when you want the broadest issue `#3` read-first surface before the replay narrows.
- Use `show_google_issue3_replay_shortcuts.ps1` after the shortcut-first entrypoint, the suite-router handoff, or the replay-route shortcut when the route is already known to stay inside issue `#3` and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first.
- Use `show_google_issue3_replay_route.ps1` when you want the broader compact bridge that keeps the bundle path, safe-route map, and runner next-step helper together.
- Use `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when replay-route follow-up is already open and you want the shorter printed bridge before the bundle-first route or the wrapper-heavy safe-route chain takes over.
- Use `show_google_issue3_contextual_flow.ps1` when `RepoRoot`, `SummaryPath`, or pinned `InputPath` values already matter and you want the next helper surface to keep that context aligned before choosing between the recommended runner, replay shortcuts, replay-route shortcut, attached bundle, live trace, or later-stage follow-up commands.
- Use `show_google_issue3_validation_router_attached_html_quickstart.ps1` when the broader validation router already narrowed the replay to attached localhost follow-up and you want the validation-router bridge, the broader attached-page flow helper, and the dedicated Google-shaped attached-page follow-up kept visible before the route drops to the smaller issue `#3` helpers.
- Use `show_google_issue3_suite_router_attached_html_quickstart.ps1` when the replay is already inside the issue `#3` helper chain and you want the shorter suite-router-side attached-page bridge visible before the wider replay helpers return.
- Use `show_google_attached_html_validation_flow.ps1` when the Google-shaped attached-page lane still matters and you want the broader sidecar-bundle audit, the wider Google attached-html surface check, the narrower issue-specific checker, and the dedicated flow reopened before the route narrows into the issue-specific bridge.
- Use `show_google_issue3_google_attached_html_entrypoint.ps1` only after `show_google_attached_html_validation_flow.ps1` is already back in view and the broader plus narrower checks have been rerun, so the issue-specific bridge narrows the route instead of skipping the sidecar-first branch too early.
- Use `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the current saved or attached pages are still the known three-page compatibility bundle and you want that pinned route exercised first.
- Use `show_google_issue3_safe_route_entrypoints.ps1` after the broader suite-router work is already done and the replay is ready to choose between fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, or runner-wiring helpers.
- Use `show_google_issue3_runner_patch_next_step.ps1` only after a safe-route wrapper has already emitted one of the current runner-patch states.

## Keep these references open

- `docs/WINDOWS_FULL_USE.md` for the broader Windows validation runbook
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the compact validation-router bridge that now sits between the top-level router and the narrower attached-page helpers
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the prose bridge from the suite router into the narrower issue `#3` helper chain
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the shorter suite-router-side attached-page bridge
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` for the compact top-level attached-page route that now sits beside the suite-router bridge
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the broader top-level attached-page companion note
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md` for the catalog-flavored top-level attached-page companion route
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md` for the shortest written map of which top-level attached-page notes should stay nearby
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` for the suite-catalog-side attached-page bridge that now sits beside the top-level and suite-router routes
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` for the replay-side attached-page companion route
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` for the shorter replay-route companion note
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` for the dedicated Google-shaped attached-page flow that now sits beside the broader attached-page router
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md` for the Google-shaped attached-page bridge that stays available before the route collapses into the narrower issue `#3` helpers
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence once the replay narrows into the safe-route path
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the exact next move after the replay lands on one of the current runner-patch states

## Recommended use

When returning to issue `#3` after time away, prefer this order:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
```

If the Google-shaped attached-page lane is already obvious, prefer this narrower branch instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
```

That keeps the higher-level router, the suite-router matrix surface check, the broader Google-shaped attached-page surface check, the narrower issue-specific checker, the sidecar-first Google attached-page flow, the issue-specific bridge, the executable next-step matrix, the shortcut-first checker, the shortcut-first bridge, and the replay shortcuts aligned on the same current branch guidance.