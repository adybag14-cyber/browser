# Issue #3 Replay Discovery Handoff

Use this note when issue `#3` needs a quick read-first route back into the current Windows validation helpers on `fork/headed-mode-foundation`.

It bridges the top-level headed validation catalog and the newer suite-catalog bridge helper into the suite-router next-step matrix, suite-router handoff, replay-route, and replay-shortcuts helpers before the replay narrows into the longer safe-route chain.

Keep this note beside:
- `docs/WINDOWS_FULL_USE.md` for the broader Windows validation catalog
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower suite-router prose bridge
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the wrapper-heavy safe-route and runner-patch flow
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay has already narrowed to the direct runner patch loop

## Read-first baseline

Start with the shared catalog when you need to re-enter the Google validation lane from the top:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

## Fastest top-level bridge

After those three baseline commands, prefer the suite-catalog bridge when you want the exact top-level router entrypoints, the Google flow helper, the next-step matrix, and the current replay helpers printed together before choosing the next branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that helper first when you want the widest compact bridge back into the current issue `#3` replay chain without reopening the longer bridge notes first.

## Fastest default matrix

After the suite-catalog bridge or the three baseline commands, prefer the next-step matrix when you already know the work is staying inside issue `#3` and want the shortest executable helper map before choosing the next branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that helper when you want the quickest route from the top-level suite router into the current handoff, replay-route, bundle-first, and runner-state choices without reopening the longer bridge notes first.

## Discovery helpers

Use these helpers in this order when you want the narrowest stable bridge back into the current issue `#3` replay chain.

### 1. Suite-catalog bridge

Use this first when you want the exact top-level suite-router entrypoints, the Google flow helper, the next-step matrix, and the current replay helpers printed together on one compact surface before narrowing further.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 2. Suite-router next-step matrix

Use this next when you want the one-command matrix that keeps the higher-level suite-router start points, the handoff helper, the replay-route helper, the bundle-first route, and the runner-state follow-up choices together before narrowing further.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 3. Suite-router handoff

Use this when you want the read-first commands, replay shortcuts, bundle-first route, and safe-route entrypoints surfaced together on one command surface after the bridge or matrix has already narrowed the likely route:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 4. Replay route bridge

Use this when you want the same read-first bridge plus the attached three-page bundle route, the current safe-route map, and the repo-root-aware runner next-step helper printed together before choosing the next replay path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 5. Replay shortcuts

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

- Start with the suite-catalog bridge when you want the exact top-level Windows validation entrypoints plus the current issue `#3` replay helpers on one compact surface.
- Move to the suite-router next-step matrix when you want the shortest executable bridge from the top-level Windows validation router into the current issue `#3` helper branches.
- Move to the suite-router handoff when you want the wider read-first bridge reprinted after the bridge or matrix already narrowed the likely route.
- Move to the replay-route helper when the next choice depends on bundle routing, repo-root-aware state, or the runner next-step helper.
- Use replay shortcuts when the replay is already narrowed and you want the shortest command surface.
- Reopen the validation-chain note once the replay is ready to move from discovery into the wrapper-heavy safe-route and runner-patch stages.
