# Issue #3 Suite-Router Next-Step Matrix

This note captures the shortest read-first route from the top-level Windows headed validation suite catalog into the newer issue `#3` helper chain on `fork/headed-mode-foundation`.

Use it when the next replay starts from `show_headed_validation_suites.ps1` and you want the compact follow-up helper chosen quickly without widening back into the longer wrapper notes first.

## Goal

Keep the first issue `#3` discovery hop small and predictable:
- start from the suite catalog or `google-input` change-area view
- move into `show_google_issue3_suite_router_next_steps.ps1`
- let that helper choose between the replay-route helper, the attached-bundle-first helper, or the runner next-step helper based on the current saved context

## Read-first commands

When the replay is starting from the top-level suite catalog:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

When you already know the work is staying inside issue `#3` and want the narrower change-area surface first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

If the replay is running from a non-default checkout, from a saved summary, or from pinned attached HTML inputs, preserve that state directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Default helper choices

`show_google_issue3_suite_router_next_steps.ps1` currently prefers these next hops:

1. `replay_route`
Use this when no pinned bundle inputs or saved summary are already in play and you want the compact issue `#3` route before the narrower shortcut map.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

2. `attached_bundle_first`
Use this when the current saved or attached inputs are still the known three-page compatibility bundle and you want that locked route before reopening the broader Google-only wrappers.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

3. `runner_patch_next_step`
Use this only after a wrapper has already produced a saved summary path plus one of the current runner-patch states.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_google_issue3_runner_patch_next_step.ps1' -SummaryPath '<saved-summary-path>' -State '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'"
```

## Follow-up order after the next-step matrix

Use this order unless the current helper output explicitly routes somewhere narrower:

1. `show_google_issue3_suite_router_next_steps.ps1`
2. `show_google_issue3_replay_route.ps1`
3. `show_google_issue3_replay_shortcuts.ps1`
4. One of:
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`
- `show_google_issue3_safe_route_entrypoints.ps1`
- `show_google_issue3_runner_patch_next_step.ps1`

Keep `show_google_issue3_suite_router_handoff.ps1` as the broader fallback when you explicitly want the higher-level bridge output again, but prefer the next-step matrix first when the route is already known to be issue `#3`.

## Practical rule

If two entry helpers both seem plausible:
- prefer `show_google_issue3_suite_router_next_steps.ps1` when you are starting from the suite catalog and do not yet need the full bridge note or the broader handoff helper
- prefer `show_google_issue3_replay_route.ps1` when the route is already known to stay inside issue `#3`
- prefer `show_google_issue3_attached_bundle_first_entrypoint.ps1` when the attached three-page compatibility bundle is the active target
- prefer `show_google_issue3_runner_patch_next_step.ps1` only after the current wrapper has already emitted a concrete runner-patch state

## Related notes

Keep these nearby when the replay widens again:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
