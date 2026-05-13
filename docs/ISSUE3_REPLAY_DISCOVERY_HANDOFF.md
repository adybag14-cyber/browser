# Issue #3 Replay Discovery Handoff

Use this note when issue `#3` needs a quick read-first route back into the current Windows validation helpers on `fork/headed-mode-foundation`.

It bridges the top-level headed validation catalog to the newer suite-router and replay-route helpers before the replay narrows into the longer safe-route chain.

Keep this note beside:
- `docs/WINDOWS_FULL_USE.md` for the broader Windows validation catalog
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the wrapper-heavy safe-route and runner-patch flow
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay has already narrowed to the direct runner patch loop

## Read-first baseline

Start with the shared catalog when you need to re-enter the Google validation lane from the top:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

## Discovery helpers

Use these helpers in this order when you want the narrowest stable bridge back into the current issue `#3` replay chain.

### 1. Suite-router handoff

Use this first when you want the read-first commands, replay shortcuts, bundle-first route, and safe-route entrypoints surfaced together on one command surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 2. Replay route bridge

Use this when you want the same read-first bridge plus the attached three-page bundle route, the current safe-route map, and the repo-root-aware runner next-step helper printed together before choosing the next replay path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 3. Replay shortcuts

Use this when you already know the replay should stay on the narrower Google route, attached bundle branch, and return-to-safe-route helpers without reopening the broader bridge first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Pinned three-page bundle

When the current saved or attached inputs are the known three-page compatibility bundle, stay on the bundle-aware route before widening back into the wrapper-heavy safe route:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

After the bundle replay clarifies the next failure state, reopen `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the safe-route entrypoints, wrapper precedence, and runner-output follow-up.

## Practical rule

- Start with the suite-router handoff when you want the widest read-first bridge.
- Move to the replay-route helper when the next choice depends on bundle routing, repo-root-aware state, or the runner next-step helper.
- Use replay shortcuts when the replay is already narrowed and you want the shortest command surface.
- Reopen the validation-chain note once the replay is ready to move from discovery into the wrapper-heavy safe-route and runner-patch stages.
