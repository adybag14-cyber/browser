# Issue #3 Suite Router Context Handoff

This note is for Windows headed issue `#3` replays that start at the top-level validation suite router and then need to preserve a chosen checkout, browser binary, host, summary path, and input strings across the narrower Google helpers.

Use it when:
- the replay started from `.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended` or `.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input`
- `RepoRoot`, `BrowserExe`, `Host`, `SummaryPath`, or the current issue `#3` input text already matters
- the next move is no longer broad discovery and should keep that same context through submit-timing, shared Enter-order, live-trace, or attached-page follow-up

## Default handoff

1. Reopen the suite router or the next-step matrix only until the likely route is clear.
2. Switch to `show_google_issue3_contextual_flow.ps1` as soon as repo root, summary path, browser path, host, or input text must stay aligned.
3. From that helper, choose only one narrower follow-up before widening again.

## Read-first commands

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>' -BrowserExe '<browser-exe>' -Host '<host>' -SubmitTimingInputText '<submit-text>' -SharedInputText '<shared-text>' -TraceInputText '<trace-text>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>' -BrowserExe '<browser-exe>' -Host '<host>' -InputText '<submit-text>' -SharedInputText '<shared-text>' -TraceInputText '<trace-text>'
```

## Narrower follow-up commands

Use the contextual-flow helper as the bridge into one of these narrower routes:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -InputText '<submit-text>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -SharedInputText '<shared-text>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1 -RepoRoot '<repo-root>' -BrowserExe '<browser-exe>' -Host '<host>' -InputText '<trace-text>' -LeaveOpen
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```

## Practical rule

- Stay on `show_google_issue3_suite_router_next_steps.ps1` only while the replay still needs route selection.
- Move to `show_google_issue3_contextual_flow.ps1` as soon as the replay needs to preserve the same repo root, browser path, host, summary path, or issue `#3` input text across multiple later-stage helpers.
- If the current pages are still the pinned three-page compatibility bundle, prefer the attached-bundle flow before reopening the broader Google-only safe-route chain.
- Keep `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md` open beside this note when the replay is about to re-enter the wrapper-heavy safe-route helpers.
