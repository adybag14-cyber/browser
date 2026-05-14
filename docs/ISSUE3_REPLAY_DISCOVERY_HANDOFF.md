# Issue #3 Replay Discovery Handoff

Use this note when issue `#3` needs a quick read-first route back into the
current Windows validation helpers on `fork/headed-mode-foundation`.

It bridges the top-level headed validation catalog into the newer top-level
shortcut-first helper, the suite-router attached-page quickstart, the
suite-catalog attached-page bridge, the next-step matrix, the context-preserving
replay helper, the suite-router handoff, replay-route, replay-route shortcut,
and replay-shortcuts helpers before the replay narrows into the longer safe-route
chain.

Keep this note beside:
- `docs/WINDOWS_FULL_USE.md` for the broader Windows validation catalog
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md` for the shortest current replay map
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md` for the compact top-level suite-router entrypoints map
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md` for the shortest suite-router-side attached-page bridge
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md` for the suite-catalog attached-page bridge
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md` for the attached-page-specific top-level bridge
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md` for the narrower replay-route follow-up surface
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md` for the narrower suite-router prose bridge
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the wrapper-heavy safe-route and runner-patch flow
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` when the replay has already narrowed to the direct runner patch loop

## Read-first baseline

Start with the shared catalog when you need to re-enter the Google validation
lane from the top:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

If the current replay is already centered on the attached localhost
compatibility pages, reprint that branch directly from the top-level validation
catalog first:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

Use that top-level attached-page router command when you want the broader
attached-page branch visible before you decide whether to move into the
suite-router attached-page quickstart, the top-level attached-page bridge, the
suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, or
the pinned bundle-first route.

## Fastest top-level bridge

After the baseline commands, prefer the top-level shortcut-first helper when the
top-level suite router already made issue `#3` obvious and no pinned bundle
inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

Preserve non-default replay context when needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that helper first when you want the shortest bridge from the top-level
suite router into the newer issue `#3` helper chain without reopening the wider
suite-catalog or replay-route surfaces first.

If you still want the widest compact bridge back into the current issue `#3`
replay chain before choosing the narrower branch, prefer the suite-catalog
bridge instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Attached-page route handoff

After `show_headed_validation_suites.ps1 -ChangeArea attached-html`, prefer the
suite-router attached-page quickstart when you want the shortest suite-router-side
attached-page bridge before choosing between the suite-catalog attached-page
bridge, the top-level attached-page bridge, the attached-page shortcut,
replay shortcuts, the next-step matrix, or the safe-route map:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is already known to stay on the narrower attached-page-specific
surface, reopen the top-level attached HTML bridge instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If the replay is entering the helper chain from the suite-catalog-side
attached-page surface and you want that bridge kept visible before narrowing
again, reopen the suite-catalog attached-page entrypoint next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Fastest default matrix

After the top-level shortcut helper, the suite-catalog bridge, or the
attached-page route handoff, prefer the next-step matrix when you already know
the work is staying inside issue `#3` and want the shortest executable helper
map before choosing the next branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that helper when you want the quickest route from the top-level suite router
into the current handoff, replay-route, bundle-first, and runner-state choices
without reopening the longer bridge notes first.

If the broader replay-route helper is already open and you want the narrower
follow-up surface without reopening the wider route notes first, prefer the
replay-route shortcut entrypoint next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Choose the next helper quickly

Use this compact matrix after the top-level router, the shortcut-first helper,
the suite-catalog bridge, or the attached-page route handoff when you want the
written route to match the current helper order without reopening several
scripts first.

- The top-level suite router already made issue `#3` obvious and no pinned bundle inputs are in play yet:
  `show_google_issue3_top_level_shortcut_first_entrypoint.ps1`
  Use this when you want the shortest bridge from the top-level suite router into the newer issue `#3` helper chain.
- You want the widest compact bridge back into the current helper chain before choosing the narrower branch:
  `show_google_issue3_suite_catalog_entrypoints.ps1`
  Use this when you want the exact top-level suite-router entrypoints, the Google flow helper, the next-step matrix, and the current replay helpers printed together on one surface.
- The current replay is already narrowed to the attached localhost HTML route and you want the shortest suite-router-side attached-page bridge first:
  `show_google_issue3_suite_router_attached_html_quickstart.ps1`
  Use this when the broader attached-page route should stay visible before the suite-catalog bridge, the top-level attached-page bridge, the attached-page shortcut, or replay shortcuts.
- The current replay is already narrowed to the attached localhost HTML route and you want the narrower attached-page-specific bridge instead:
  `show_google_issue3_top_level_attached_html_entrypoint.ps1`
  Use this when you want the attached-page-specific helper surface before the attached-page shortcut, replay-route shortcut, replay shortcuts, the bundle-first helper, or the safe-route map.
- The replay is entering from the suite-catalog-side attached-page route and you want that bridge kept visible:
  `show_google_issue3_suite_catalog_attached_html_entrypoint.ps1`
  Use this when you want the suite-catalog attached-page route to stay explicit before narrowing into the Google attached-page entrypoint, the attached-page shortcut, replay shortcuts, or the next-step matrix.
- `RepoRoot`, `SummaryPath`, or fixed `InputPath` already matter:
  `show_google_issue3_contextual_flow.ps1`
  Use this when the next surface should keep a non-default checkout, a saved summary, or pinned bundle inputs attached while you choose the narrower helper.
- The current saved or attached inputs are the known three-page compatibility bundle:
  `show_google_issue3_attached_bundle_first_entrypoint.ps1`
  Stay on the pinned bundle route before widening back into the broader Google-only safe-route chain.
- You want the broader bridge after the matrix because the replay-route, attached-bundle, or runner-state choices still need to stay visible together:
  `show_google_issue3_replay_route.ps1`
- The replay-route helper is already open and you want the smaller follow-up surface immediately:
  `show_google_issue3_replay_route_shortcut_entrypoint.ps1`
  Use this when you want the narrower attached-page, replay-shortcuts, bundle-first, or safe-route choices without reopening the broader replay-route helper first.
- The route is already clearly inside issue `#3` and you want the narrowest command surface:
  `show_google_issue3_replay_shortcuts.ps1`
- The safe-route wrapper already emitted `ready-for-runner-patch`, `already-direct`, or `runner-already-wired-regenerate-outputs`:
  `show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>`
  Use this instead of reopening the longer validation-chain or decision-table note first.

## Discovery helpers

Use these helpers in this order when you want the narrowest stable bridge back
into the current issue `#3` replay chain.

### 1. Top-level shortcut-first bridge

Use this first when the top-level suite router already made issue `#3` obvious
and you want the shortest bridge into the current helper chain.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 2. Suite-catalog bridge

Use this when you want the exact top-level suite-router entrypoints, the Google
flow helper, the next-step matrix, and the current replay helpers printed
before narrowing further.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 3. Suite-router attached HTML quickstart

Use this when the top-level suite router already narrowed the replay to
attached localhost HTML and you want the shortest suite-router-side bridge
before widening again.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 4. Top-level attached HTML bridge

Use this when the top-level suite router already narrowed the replay to
attached localhost HTML and you want the attached-page-specific bridge instead
of the wider shortcut surface.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 5. Suite-catalog attached HTML bridge

Use this when the replay is entering from the suite-catalog-side attached-page
route and you want that bridge kept visible before narrowing again.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 6. Suite-router next-step matrix

Use this when you want the one-command matrix that keeps the higher-level
suite-router start points, the handoff helper, the replay-route helper, the
bundle-first route, and the runner-state follow-up choices together before
narrowing further.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 7. Context-preserving flow

Use this when repo-root overrides, saved-summary state, or pinned bundle inputs
should stay visible while you decide between replay shortcuts, the attached
bundle route, the recommended runner, live trace, or the wrapper-heavy
safe-route helpers.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 8. Suite-router handoff

Use this when you want the read-first commands, replay shortcuts, bundle-first
route, and safe-route entrypoints surfaced together on one command surface
after the bridge or matrix has already narrowed the likely route.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 9. Replay route bridge

Use this when you want the same read-first bridge plus the attached three-page
bundle route, the current safe-route map, and the repo-root-aware runner
next-step helper printed together before choosing the next replay path.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 10. Replay-route shortcut

Use this when the replay-route helper is already open and you want the narrower
follow-up surface before widening again.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

### 11. Replay shortcuts

Use this when you already know the replay should stay on the narrower Google
route, attached bundle branch, and return-to-safe-route helpers without
reopening the broader bridge first.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Pinned three-page bundle

When the current saved or attached inputs are the known three-page compatibility
bundle, stay on the bundle-aware route before widening back into the
wrapper-heavy safe route:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

After the bundle replay clarifies the next failure state, reopen
`docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` for the safe-route entrypoints,
wrapper precedence, and runner-output follow-up.

## Practical rule

- Start with the top-level shortcut-first helper when the top-level suite router already made issue `#3` obvious and you want the shortest bridge into the live helper chain.
- Start with the suite-catalog bridge when you still want the widest compact view of the top-level Windows validation entrypoints plus the current issue `#3` helpers.
- Reopen `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the top-level suite router should reprint the broader attached-page branch before you drop into the attached-page-specific helper chain.
- Move to the suite-router attached-page quickstart when you want the shortest suite-router-side attached-page bridge before choosing between the suite-catalog attached-page bridge, the top-level attached-page bridge, the attached-page shortcut, replay shortcuts, or the safe-route map.
- Move to the top-level attached HTML bridge when the attached localhost route is already clear and you want the narrower attached-page-specific bridge before replay-route shortcut, replay shortcuts, the bundle-first helper, or the safe-route map.
- Move to the suite-catalog attached-page bridge when the replay is entering the helper chain from the suite-catalog-side attached-page surface and that bridge should stay visible before narrowing again.
- Move to the suite-router next-step matrix when you want the shortest executable bridge from the top-level Windows validation router into the current issue `#3` helper branches.
- Move to the contextual flow when repo-root, saved-summary, or pinned bundle state should stay visible while you choose the next narrower helper.
- Move to the suite-router handoff when you want the wider read-first bridge reprinted after the bridge, matrix, or contextual flow already narrowed the likely route.
- Move to the replay-route helper when the next choice depends on bundle routing, repo-root-aware state, or the runner next-step helper, and move to the replay-route shortcut when that broader helper is already open but the next choice should stay narrower.
- Use replay shortcuts when the replay is already narrowed and you want the shortest command surface.
- Reopen the validation-chain note once the replay is ready to move from discovery into the wrapper-heavy safe-route and runner-patch stages.
