# Issue #3 Suite Router Entrypoint Guide

This note is the shortest bridge from the top-level headed validation suite map
into the current issue `#3` replay helpers.

Use it when you start from `show_headed_validation_suites.ps1` and want the
next helper chosen quickly without reopening the longer Windows runbook or the
full wrapper-heavy safe-route notes first.

## Start points

Use either of these top-level headed validation router entrypoints first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

If the replay is already running from a non-default checkout, keep that same
repo-root context attached to those top-level entrypoints:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -SuiteName 'google-recommended'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_headed_validation_suites.ps1' -ChangeArea 'google-input'"
```

If the current replay is still entering issue `#3` from the attached-page
follow-up surface before the bundle is pinned, keep this change-area entrypoint
nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
```

If the current replay is already narrowed to the attached localhost HTML route
itself and you want the shortest top-level bridge into the attached-page helper
chain, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

When that attached-html route is already in focus and you want the shortest
suite-router-side attached-page bridge before choosing between the catalog
attached-page bridge, the top-level attached-page bridge, the attached-page
shortcut, replay shortcuts, the next-step matrix, or the safe-route map,
reopen the dedicated suite-router attached HTML quickstart right after that
start point:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached-bundle paths, preserve that
same context on the suite-router attached HTML helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the next replay should stay pinned to the known attached three-page
compatibility bundle, keep this change-area entrypoint nearby as well:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

When the top-level suite router has already narrowed the work to issue `#3`
and you want the tightest current helper surface immediately, reopen the new
shortcut-first top-level bridge right after those start points:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached-bundle paths, preserve that
same context on the top-level shortcut helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

When the top-level suite router has already narrowed the work to the attached
localhost HTML route and you want the attached-page-specific bridge instead of
the wider shortcut surface, reopen the dedicated top-level attached HTML
entrypoint right after that start point:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached-bundle paths, preserve that
same context on the top-level attached HTML helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Default next helper

After the top-level suite router, print the top-level shortcut-first entrypoint
first when you want the shortest current bridge back into the issue `#3`
replay chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the top-level suite router already made it clear that the replay should stay
on the attached localhost HTML route, print the suite-router attached HTML
quickstart first when you want the shorter suite-router-side attached-page
bridge before deciding whether to continue into the suite-catalog bridge, the
top-level attached-page bridge, the attached-page shortcut, replay shortcuts,
the next-step matrix, or the safe-route map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
the suite-router attached HTML helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the top-level suite router already made it clear that the replay should stay
on the attached localhost HTML route and you want the top-level attached-page
bridge instead, print the top-level attached HTML entrypoint first so the
narrower attached-page helper chain stays visible:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
the attached HTML helper too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you still want the wider compact bridge after the top-level shortcut helper,
print the suite-catalog bridge next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Then print the current issue `#3` next-step helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

When the replay is running from a non-default checkout, from an already-saved
summary, or from explicit attached-bundle paths, preserve that same context on
both helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the top-level suite router already made it clear that the replay should stay
inside issue `#3` and you do not need the wider catalog bridge or next-step
matrix repeated again, jump from the top-level shortcut helper straight to the
compact replay-shortcuts helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Which helper should come next

The current default is:

- `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` immediately after the top-level suite router when you want the shortest current bridge back into the issue `#3` helper chain
- `show_google_issue3_suite_router_attached_html_quickstart.ps1` immediately after `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the route is already narrowed to the attached localhost HTML branch and you want the shortest suite-router-side attached-page bridge before deciding between the suite-catalog bridge, the top-level attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route entrypoints
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` immediately after `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the route is already narrowed to the attached localhost HTML branch and you want the shortest attached-page-specific bridge before the attached-page shortcut, replay-route shortcut, replay shortcuts, bundle-first helper, or safe-route entrypoints
- `show_google_issue3_suite_catalog_entrypoints.ps1` after the top-level shortcut helper when you still want the widest compact bridge back into the current issue `#3` helper chain
- `show_google_issue3_suite_router_next_steps.ps1` once the route is already known to stay inside issue `#3` and you want the fastest executable matrix before choosing the narrower branch
- `show_google_issue3_replay_shortcuts.ps1` as the direct next helper after the top-level shortcut helper when the route is already narrow enough and you want the tightest shortcut surface before deciding whether to widen back into replay route, the bundle-first helper, or the safe-route entrypoints
- `show_google_issue3_google_flow_context_bridge.ps1` when `RepoRoot`, `BrowserExe`, `Host`, a saved `SummaryPath`, or pinned bundle inputs already matter and you still want the broader Google flow kept aligned with the newer issue `#3` helper chain before narrowing again
- `show_google_issue3_replay_route.ps1` when a `SummaryPath` is already available and the replay should stay narrow on the current saved-output context
- `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the current three-page compatibility set
- `show_google_issue3_suite_router_handoff.ps1` when you explicitly want the broader read-first bridge reprinted after the top-level shortcut helper, catalog helper, or matrix has already narrowed the likely route
- `show_google_issue3_safe_route_entrypoints.ps1` once the top-level shortcut helper, the suite-router attached HTML helper, the top-level attached HTML helper, replay-route, replay-shortcuts, the broader handoff helpers, or the context bridge have already confirmed the current branch and you want the current safe-route commands plus the runner-state helper printed before the next fresh replay or reuse-current-outputs step

Use `show_google_issue3_replay_route.ps1` whenever you want the broader
attached-bundle branch, the current safe-route map, and the repo-root-aware
runner next-step helper printed together before narrowing again.

Use `show_google_issue3_replay_shortcuts.ps1` after the top-level shortcut
helper, the suite-router attached HTML helper, the top-level attached HTML
helper, or replay-route when you want the narrower shortcut surface for the
attached-bundle branch, bundle-first helper, and safe-route entrypoints before
choosing a wrapper-heavy next step.

Use `show_google_issue3_google_flow_context_bridge.ps1` before replay-route,
replay-shortcuts, or the safe-route entrypoints when the replay still needs the
broader `show_google_input_validation_flow.ps1` ladder, but the route also has
to preserve repo root, browser path, host, saved-summary state, or pinned
attached-bundle inputs all the way through the newer issue `#3` helpers.

Use `show_google_issue3_safe_route_entrypoints.ps1` after the top-level
shortcut helper, the suite-router attached HTML helper, the top-level attached
HTML helper, replay-route, replay-shortcuts, the broader suite-router handoff,
or the context bridge when you want the current safe-route commands, notes, and
runner next-step helper surfaced in one place before choosing between the fresh
replay wrapper and the reuse-current-outputs wrapper.

## Read-first helper order

Use this compact sequence when the replay begins from the higher-level suite
router and no pinned bundle or saved summary has forced a narrower path yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this sequence when the replay is still entering issue `#3` from the
attached-page route before any bundle inputs are pinned:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when the replay is already narrowed to the attached
localhost HTML route and should stay on the attached-page-specific bridge
before widening again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this slightly wider sequence when you still want the compact bridge and the
start-point matrix reprinted after the top-level shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

Use this compact sequence when saved-summary state, repo-root overrides,
browser-path selection, host overrides, or pinned bundle inputs already matter
and the replay should keep the broader Google flow aligned before narrowing
further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_flow_context_bridge.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host 127.0.0.1 -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use this compact sequence when the replay should stay pinned to the current
attached three-page compatibility bundle first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use this compact sequence when you explicitly want the broader bridge helper
reprinted before choosing between replay-route, replay-shortcuts, the
bundle-first helper, or the safe-route map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

## Keep these references nearby

- `docs/WINDOWS_FULL_USE.md` for the broader Windows headed runbook
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md` for the wider prose bridge from the top-level validation catalog into the current helper chain
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower prose bridge from the top-level shortcut helper into replay shortcuts
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the suite-router-side attached-page bridge when the route is already narrowed to the attached localhost HTML branch
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the attached-page-specific bridge from the top-level suite router into the narrower attached localhost helper chain
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current safe-route replay path
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for wrapper precedence and fresh replay entrypoints
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` for the direct runner patch loop after the safe-route handoff emits `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`

## Practical rule

Start from the top-level headed validation suite router, then move immediately
into `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the
route is already clearly inside issue `#3` and no saved summary or pinned
bundle inputs need to take precedence first. Reopen
`show_google_issue3_suite_catalog_entrypoints.ps1` or
`show_google_issue3_suite_router_next_steps.ps1` only when you still want the
wider compact bridge or explicit start-point matrix reprinted before choosing
the narrower branch.

- no saved summary and no explicit bundle paths: go straight from the top-level suite router to the top-level shortcut helper, then replay shortcuts, then open the safe-route entrypoints helper before the next wrapper-heavy replay step
- current replay still entering from the attached-page issue `#3` surface: reopen `show_headed_validation_suites.ps1 -ChangeArea google-attached-html` first, then move into the top-level shortcut helper before narrowing into replay shortcuts or the safe-route map
- current replay already narrowed to the attached localhost HTML route: reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` first, then move into `show_google_issue3_suite_router_attached_html_quickstart.ps1` before choosing between the suite-catalog attached-page bridge, the top-level attached-page bridge, the attached HTML shortcut, replay shortcuts, or the safe-route map
- top-level suite router already narrowed the route and no wider bridge is needed: jump from the top-level shortcut helper straight to replay shortcuts, then open the safe-route entrypoints helper or widen back into replay route only if the next choice still is not obvious
- saved summary, browser path, repo-root override, host override, or pinned bundle inputs already present: use the top-level shortcut helper with that same context first, then widen into the context bridge, replay route, or the next-step matrix only as needed
- saved summary already present and the replay is already narrowed: go to replay route first, then narrow into replay shortcuts and the safe-route entrypoints helper only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path
- broader read-first bridge still needed: reopen `show_google_issue3_suite_router_handoff.ps1` after the top-level shortcut helper, catalog helper, or matrix has already re-established the likely route, then continue into the safe-route entrypoints helper when the replay is ready for the wrapper-heavy branch

Only reopen the longer validation-chain notes after the route has narrowed into
the wrapper-heavy safe path.
