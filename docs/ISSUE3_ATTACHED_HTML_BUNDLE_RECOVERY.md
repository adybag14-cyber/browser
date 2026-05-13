# Issue #3 Attached HTML Bundle Recovery

Use this note when the next issue `#3` replay should stay pinned to the known attached three-page compatibility bundle before widening back into the broader Google-only headed validation chain.

This is the shortest bundle-first companion note to:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Use this route when

Choose the bundle-first route first when:
- the current saved or attached inputs are still the known three-page compatibility set
- the replay should prove the pinned localhost bundle before another live Google retry
- you want the same fixed `InputPath` values preserved through the checker, flow helper, and delegated runner
- you only want to reopen the wrapper-heavy safe-route helpers after the bundle replay makes the next failure state clear

## Shortest route

Use these commands in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Read-first bundle entrypoint

If you want the pinned bundle route, the return-to-safe-route command, and the companion replay shortcuts printed together in one helper, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

## Non-default checkout or explicit bundle paths

When the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you want the lower-level bundle flow helper itself to stay pinned to explicit bundle inputs, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
```

## Before launch

Fail fast on the bundle surfaces first when the branch has moved or the current attached pages may have drifted:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

Use those checks before the replay when you want to confirm that:
- the pinned bundle guide, checker, helper, and runner still exist
- the current attached pages still resolve to the expected three-page compatibility set
- the same locked input paths will be reused by the later flow helper and runner

## Return after bundle replay

After the pinned bundle replay, reopen the broader issue `#3` route only when the next state is clear again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use `show_google_issue3_replay_shortcuts.ps1` first when you want the tighter recovery surface.

Use `show_google_issue3_safe_route_entrypoints.ps1` when the replay is ready to step back into the current wrapper-heavy recovery path.

## Practical rule

If the replay is still about the attached compatibility targets, stay on the bundle-first route.

If the bundle replay has already made the next Google-style input or submit failure clear, return to the replay shortcuts or safe-route entrypoints with the same `RepoRoot`, `SummaryPath`, and `InputPath` context preserved.