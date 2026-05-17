# Issue #3 Suite-Router Shortcut Bridge

Use this note when issue `#3` work starts from the higher-level Windows validation router and the next replay should move quickly into the narrower helper chain without reopening the longer chain notes first.

This bridge now covers both of the compact suite-router entrypoints that matter most:

- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` when the top-level router already narrowed replay to the attached localhost HTML route

The shortcut-first helper now also keeps the broader attached-page localhost flow, the narrower Google-shaped attached-page flow, the dedicated issue-specific Google attached-page checker and entrypoint, the dedicated attached-page shortcut, the slightly broader replay-route helper, and the smaller replay-route shortcut surface visible beside the replay-shortcuts ladder, so this note should stay aligned with those surfaced follow-up helpers too.

## Shortcut-first bridge

If you want the shortest top-level issue `#3` bridge, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from an explicit attached-bundle path, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this when the top-level router already made it clear that the replay stays inside issue `#3`, but you do not need the attached-page-specific bridge yet.

## Attached HTML bridge

If the top-level router already narrowed replay to the attached localhost compatibility branch, jump straight to:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this when the next replay is already narrowed to attached-page compatibility follow-up and you want the shorter suite-router-side attached-page bridge visible before deciding whether to widen into the top-level attached-page quickstart, the broader top-level attached-page bridge, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, the replay-route helper, the replay-route shortcut, the pinned bundle-first branch, or the safe-route helper chain.

## Wider compact helpers

If you still want the wider compact bridge after either short entrypoint, keep these companion helpers nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use `check_google_issue3_google_attached_html_entrypoint_surface.ps1` when the route already narrowed to the Google-shaped attached-page lane and you want the issue-specific fail-fast surface reprinted before the shorter shortcut ladder takes over.

Use `show_google_issue3_google_attached_html_entrypoint.ps1` when the Google-shaped attached-page route is already obvious and you want the shortest issue-specific bridge back into the shortcut-first helper, replay shortcuts, contextual flow, the bundle-first branch, or the safe-route map.

Use `show_google_issue3_replay_route.ps1` when the route still needs the slightly broader attached-page, bundle-first, or safe-route bridge kept in one place before narrowing again.

Use `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the replay-route helper is already open and you want the shorter printed companion that keeps replay shortcuts, the next-step matrix, attached-page follow-up, the bundle-first branch, and the safe-route map visible from the same context.

## Goal

Keep the first issue `#3` commands stable when you start from:

- `show_headed_validation_suites.ps1 -SuiteName google-recommended`
- `show_headed_validation_suites.ps1 -ChangeArea google-input`
- `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- `show_google_issue3_google_attached_html_entrypoint.ps1`
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
- `show_google_issue3_suite_router_attached_html_quickstart.ps1`

Then hand off immediately into the narrower helper that fits the route instead of reopening the longer validation-chain notes too early.

## Default read-first sequences

Use this sequence when the route is already clearly inside issue `#3` and no attached-page-specific bridge, saved summary, or pinned bundle path needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this sequence when the route is already narrowed to attached localhost compatibility follow-up and no saved summary or pinned bundle path needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this alternate sequence when the top-level router already narrowed replay to the Google-shaped attached-page lane and you still want the broader attached-page helpers plus the issue-specific checker and entrypoint kept visible before replay shortcuts take over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use `show_google_issue3_windows_full_use_attached_html_route.ps1` before that shorter attached-page sequence when the replay was reopened from `docs/WINDOWS_FULL_USE.md` and the broader Windows runbook-side attached-page branch should stay visible first.

If you need the slightly broader helper because bundle routing, repo-root-aware state, or the runner next-step helper still matter, continue with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

If you already know the replay-route helper is active and you just want the smaller companion surface, continue with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

If you want the wider compact bridge before choosing the narrower branch, reopen either companion helper after the shortcut-first entrypoint or the attached HTML quickstart:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

## Suite-router next-step matrix

Use this compact map when you are starting from the top-level suite router and want the fastest correct next helper without reopening the longer chain notes first.

If you want the same matrix as executable commands in one compact helper, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

- `show_headed_validation_suites.ps1 -SuiteName google-recommended`
  Default next helper: `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
  Use this when you want the shortest top-level bridge back into the issue `#3` replay chain before deciding whether to widen into the suite-catalog bridge, next-step matrix, replay-route, or safe-route branches.
- `show_headed_validation_suites.ps1 -ChangeArea google-input`
  Default next helper: `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
  Use this when the route is already known to stay inside issue `#3` and you want the shortest top-level bridge before deciding whether to widen back into the suite-catalog bridge, next-step matrix, replay-route, bundle-first, or safe-route branches.
- `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
  Default next helper: `show_google_issue3_google_attached_html_entrypoint.ps1`
  Use this when the broader router already narrowed replay to the Google-shaped attached-page lane and you want the issue-specific attached-page checker and entrypoint kept visible before the shortcut-first helper, replay-shortcuts ladder, or replay-route bridge take over.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html`
  Default next helper: `show_google_issue3_suite_router_attached_html_quickstart.ps1`
  Use this when the next replay is already narrowed to attached-page compatibility follow-up and you want the shorter suite-router attached-page bridge visible immediately before deciding whether to widen into the top-level attached-page quickstart, the broader top-level attached-page bridge, replay shortcuts, the next-step matrix, the replay-route helper, the replay-route shortcut, the pinned bundle-first path, or the safe-route helper chain.
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
  Default next helper: `show_google_issue3_replay_shortcuts.ps1`
  Use this when the top-level router is already out of the way and you want the narrowest helper surface before choosing whether to widen into the broader attached-page helpers, replay-route, bundle-first, or safe-route map.
- `show_google_issue3_google_attached_html_entrypoint.ps1`
  Default next helper: `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`
  Use this when the Google-shaped attached-page route is already confirmed and you want the shortest issue-specific bridge back into the newer shortcut-first helper before deciding whether to widen into replay shortcuts, contextual flow, the bundle-first branch, or the safe-route map.
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
  Default next helper: `show_google_issue3_attached_bundle_first_entrypoint.ps1`
  Use this when the current saved or attached inputs are still the pinned three-page compatibility bundle and you want the one-command bundle-first helper to keep that locked route plus the safe-route return visible before the broader Google-only wrappers.
- `show_google_issue3_suite_router_handoff.ps1`
  Default next helper: `show_google_issue3_replay_shortcuts.ps1`
  Use this when the higher-level issue `#3` router state is already confirmed and you want the narrower shortcut map next before deciding whether to widen back into replay-route, stay pinned to attached-bundle-first, or reopen the safe-route helper.
- `show_google_issue3_replay_route.ps1`
  Default next helper: `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
  Use this when you want the narrower replay-route companion before deciding between the attached-bundle-first route, the fresh safe-route replay, or the wrapper-heavy safe-route entrypoints map.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
  Default next helper: `show_google_issue3_replay_shortcuts.ps1`
  Use this when replay-route is already open and you want the shorter printed bridge kept visible before widening back into replay shortcuts, the bundle-first route, or the wrapper-heavy safe-route map.
- Wrapper-emitted runner state already known
  Default next helper: `show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>`
  Use this when the current replay already has a saved summary path plus one of the three runner-patch states and you want the shortest exact next-step command map.

## Bundle-first read-first sequence

Use this alternate route when the current saved or attached pages are still the known three-page compatibility bundle and the replay should stay pinned to that bundle before reopening the broader Google-only helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Preserve non-default replay context

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit attached bundle path, preserve that context directly in the matching compact helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you already know you want the replay-route helper right away, preserve that same repo-root and summary context directly in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you already know you want the replay-route shortcut helper right away, preserve that same repo-root and summary context directly in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you already know you want the narrower shortcut helper right away, preserve that same context directly in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Notes to keep nearby

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current issue `#3` replay route
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md` for the top-level suite-router companion note
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the attached-page-specific compact bridge
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md` for the issue-specific Google-shaped attached-page bridge and checker route
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` for the narrower Google-shaped attached-page flow that the shortcut helper now keeps visible beside the broader attached-page ladder
- `docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md` for the dedicated attached-page shortcut that now sits beside the broader attached-page flow helpers
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md` when the replay was reopened from the broader Windows full-use runbook first
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md` for the shorter top-level attached-page bridge that now sits directly after the suite-router attached-page quickstart
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the broader top-level attached-page helper that follows the shorter quickstart
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md` for the written map of which nearby attached-page notes should stay visible beside that top-level helper
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md` for the wider prose bridge from the top-level validation catalog into the current helper chain
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` for the shorter replay-route companion that now sits between the broader replay-route helper and the heavier safe-route map
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md` for the pinned three-page bundle handoff once replay-route has already narrowed that far
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and the larger safe-route ordering
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay lands on one of the three runner-patch states
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` when the replay is already narrowed to a direct runner-source edit

## Practical rule

Start from the top-level headed validation suite router, then choose the compact helper that matches the route you already know you are on.

- route already clearly inside issue `#3` with no attached-page-specific bridge needed yet: go straight to `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then reopen `show_attached_html_validation_flow.ps1`, `show_google_attached_html_validation_flow.ps1`, or `show_google_issue3_attached_html_shortcut_entrypoint.ps1` when the broader attached-page ladder still matters, then continue to replay shortcuts, replay route, the replay-route shortcut helper, and the safe-route entrypoints helper when the route has narrowed enough
- route already narrowed to attached localhost compatibility follow-up: go straight to `show_google_issue3_suite_router_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then `show_google_issue3_top_level_attached_html_entrypoint.ps1`, then the suite-catalog attached-page bridge or attached-page shortcut, then replay shortcuts, then replay route, then the replay-route shortcut helper, then the safe-route entrypoints helper
- route already narrowed to the Google-shaped attached-page lane: rerun `check_google_issue3_google_attached_html_entrypoint_surface.ps1`, then `show_google_issue3_google_attached_html_entrypoint.ps1`, then `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1`, then the broader attached-page flow helper, the narrower Google-shaped flow helper, or the dedicated attached-page shortcut before narrowing into replay shortcuts, replay route, and the replay-route shortcut helper
- saved summary or repo-root override already present: reopen the matching compact helper with that same context first, then widen into replay route, the replay-route shortcut helper, contextual flow, or the next-step matrix only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- broader read-first bridge still needed: reopen `check_google_issue3_google_attached_html_entrypoint_surface.ps1`, `show_google_issue3_google_attached_html_entrypoint.ps1`, `show_google_issue3_suite_catalog_entrypoints.ps1`, `show_google_issue3_suite_router_next_steps.ps1`, `show_google_issue3_suite_router_handoff.ps1`, `show_google_issue3_replay_route.ps1`, or `show_google_issue3_replay_route_shortcut_entrypoint.ps1` only when you still want the wider compact bridge or explicit start-point matrix reprinted before choosing the narrower branch

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
