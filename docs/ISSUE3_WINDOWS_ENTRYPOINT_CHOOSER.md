# Issue #3 Windows Entrypoint Chooser

Use this note when you want the shortest reliable way to start the current Windows replay for issue `#3` without reopening every longer routing note first.

Keep these companion notes nearby when the replay needs more detail:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md`
- `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md`
- `docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`

## Start-here decision table

### I need the broad headed validation router first

Use this when you are still choosing the right issue `#3` lane or when the change may widen back out to attached HTML, local fixtures, or another nearby shared suite.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
```

What it is best for:
- picking the narrowest bounded suite before a replay
- seeing the nearby Google, shared-input, attached-page, and localhost follow-up suites in one place
- deciding whether to stay in the bounded title, submit-path, shared Enter-order, or attached-page follow-up slices

### I already know I am staying inside the issue #3 flow

Use this when you want the full localhost-first issue `#3` sequence printed in order before running anything.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1
```

What it is best for:
- printing the reduced localhost, title, quick, homepage-fixture, submit-path, submit-timing, shared Enter-order, attached-page, trace, and manual follow-up sequence in one place
- keeping the current issue `#3` bounded steps in order before widening into live Google or attached HTML
- reusing the same command surface when `-LeaveOpen`, `-ManualGoogleStyle`, `-ManualInitialPage`, or `-ManualInputPath` are needed

### I have attached HTML pages and need the right localhost route first

Use this when the next replay is already about saved or attached localhost pages and you want the helper to classify the current inputs before you choose between the general attached-html route, the stricter Google-style route, or the pinned three-page compatibility bundle.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_current_attached_html_fixture_routes.ps1
```

What it is best for:
- classifying the current attached HTML inputs as `general`, `google-style`, or `google-branded-non-search`
- surfacing the right first command before you widen into the broader attached-page helper chain
- spotting when the current replay should stay on the pinned compatibility bundle and reopen `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`

If the replay is anchored to a non-default checkout, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_current_attached_html_fixture_routes.ps1 -RepoRoot '<repo-root>'
```

Use the returned route like this:
- `google-style`: reopen `show_google_attached_html_validation_flow.ps1` first.
- `google-branded-non-search`: stay on `show_attached_html_validation_flow.ps1` unless a real search-style fixture is also present.
- `general`: stay on `show_attached_html_validation_flow.ps1` and let the bounded suite hints choose the first localhost gate.

If the current files still match the known three-page compatibility bundle, keep these nearby before widening back out:
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`

### I only need the current safe-route replay entrypoints

Use this when the replay is already narrowed into the safe-route helper chain and you want the current fresh replay, reuse-current-outputs, refresh-status, handoff-safe, summary-guide-safe, and runner-wiring-safe commands printed together.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1
```

What it is best for:
- reopening the shortest current issue `#3` replay path
- preserving repo-root and saved-summary context for non-default checkouts
- choosing between a fresh replay and a reuse-current-outputs pass without reopening the longer validation-chain note first

If the replay is anchored to a non-default checkout or an already-saved summary, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>'
```

## Fresh replay versus reuse-current-outputs

Start with the fresh replay route when current issue `#3` outputs may be stale or missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```

Use the reuse-current-outputs wrapper only when the current artifacts are already present and trusted:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1
```

## If the safe-route handoff narrows to the direct runner patch loop

Open `docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md` immediately when the handoff artifact lands on one of these states:
- `ready-for-runner-patch`
- `already-direct`
- `runner-already-wired-regenerate-outputs`

Use `docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md` beside the decision table when the replay still needs the direct output-object source edit in `scripts/windows/run_google_issue3_recommended_validation.ps1`.

## After the safe-route chain is green

Only widen back out after the refresh-status and runner-wiring helpers agree that the chain is ready.

Then reopen the higher-level route from `docs/WINDOWS_FULL_USE.md` for:
- attached or saved localhost HTML follow-up
- the fixed local-fixture replay
- the current three-page compatibility bundle
- manual headed comparison against the same Google-shaped input checkpoints

If the next step is attached localhost follow-up, run the route classifier first so the replay opens on the right attached-page lane instead of guessing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_current_attached_html_fixture_routes.ps1
```

## Practical rule of thumb

Use the entrypoints in this order:
1. `show_headed_validation_suites.ps1 -ChangeArea google-input` when you are still picking the narrowest lane.
2. `show_google_input_validation_flow.ps1` when you know the work stays inside issue `#3` but want the whole current flow printed.
3. `show_current_attached_html_fixture_routes.ps1` when the next pass is already about attached localhost pages and you need the right attached-page route before running a helper.
4. `show_google_issue3_safe_route_entrypoints.ps1` when the replay is already narrowed into the safe-route helper chain and you only need the shortest current command map.
