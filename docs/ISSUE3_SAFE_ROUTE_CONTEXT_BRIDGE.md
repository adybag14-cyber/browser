# Issue #3 Safe-Route Context Bridge

Use this note when issue `#3` replay is moving from the higher-level read-first helpers into the wrapper-heavy safe-route path and the current run already depends on a non-default checkout, a saved summary, or the pinned attached bundle inputs.

## Goal

Keep `RepoRoot`, `SummaryPath`, and optional bundle input context attached while you move from the suite-router or replay-shortcuts stage into the current safe-route entrypoints and runner-state follow-up.

## Recommended order

1. Reprint the higher-level issue `#3` bridge with the current context:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

2. Reopen the narrower replay-shortcuts helper with that same context when you already know the replay should stay on issue `#3`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

3. When the next move should stay on the wrapper-heavy safe route, reopen the safe-route entrypoints map with the same checkout and summary:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

4. If the current saved or attached pages are still the known three-page compatibility bundle, prefer the bundle-first helper before widening back into the broader Google-only wrapper chain:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## When the runner state is already known

After the safe-route wrapper or reuse-current-outputs helper lands on `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`, use the exact `show_google_issue3_runner_patch_next_step.ps1` command printed by the current helper output instead of rewriting it by hand. The emitted command keeps the same repo-root and saved-summary context attached.

## Practical rule

- Use the suite-router handoff helper when you still want the broader read-first commands beside the current shortcuts.
- Use the replay-shortcuts helper when you already know the replay is staying on issue `#3`.
- Use the safe-route entrypoints helper when the replay is already narrowing into the wrapper-heavy path.
- Use the bundle-first helper when the current input set is still the pinned three-page compatibility bundle.
- Use the emitted runner next-step command once a wrapper has already named the current runner state.

## Keep Nearby

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
