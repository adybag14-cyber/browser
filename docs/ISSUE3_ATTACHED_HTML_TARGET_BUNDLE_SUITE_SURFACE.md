# Issue #3 Attached HTML Target-Bundle Suite Surface

Use this note when issue `#3` replay is already close to the known three-page attached HTML compatibility bundle and you want the compact suite-level route printed with both the broader attached-page helper flow and the narrower Google-shaped attached-page flow still visible beside it.

Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md` nearby when the replay is already pinned to the exact three-page bundle, and keep `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` nearby when one of those pages makes the Google-shaped attached-page route the next likely follow-up.

## Goal

Start from the dedicated suite-surface helper when the current replay is already near `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle` and you want the bundle surface, the broader attached-page suite surfaces, the broader attached-page flow helper, and the dedicated Google-shaped attached-page flow helper visible in one compact place before the replay narrows into bundle-only execution.

## Read-first commands

Use this compact suite-level route when the attached bundle is the likely next move but you still want the neighboring suite and flow surfaces printed beside it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when:

- the current attached pages are still the known three-page compatibility bundle or are very likely to narrow to it next
- you want the `attached-html-target-bundle` change-area output reprinted with the broader attached-page suite surface and the Google-shaped attached-page suite surface still visible beside it
- you want the broader attached-page flow helper and the dedicated Google-shaped attached-page flow helper kept in view before the replay locks onto the delegated bundle validation runner

## Use the dedicated helper first

Prefer the dedicated suite-surface helper first when you want the smallest issue `#3` command surface that still keeps the bundle lane connected to the broader attached-page follow-up ladders:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
```

That helper is the best starting point when:

- the replay is already close to bundle-only validation and the broader route context only needs a compact reminder
- you want the `attached-html-target-bundle`, `attached-html`, and `google-attached-html` suite commands kept together beside the broader and Google-shaped attached-page flow helpers
- you want the bundle surface checker, bundle flow helper, bundle runner, bundle-first entrypoint, replay route, and replay shortcuts printed on one smaller issue `#3` surface before you choose the next replay branch

## Bundle-first follow-up

If explicit bundle paths or replay context are already pinned, keep the narrower bundle-first helper nearby before the delegated bundle runner takes over:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when the next replay decision still depends on preserving explicit bundle inputs, a saved summary path, or a non-default repo root while the bundle lane remains the most likely next branch.

## Preserve replay context

If the replay already carries a non-default checkout, a saved summary, or pinned bundle inputs, keep that same context attached to the suite-surface helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` already points at a non-default checkout
- `SummaryPath` already captures the current replay outputs
- explicit `InputPath` values should stay pinned through the suite surface, the narrower bundle-first helper, and the replay-route helpers without relying on auto-discovery

## Practical rule

Prefer the dedicated suite-surface helper when the replay is already close to the attached bundle lane and only needs a compact re-entry surface before bundle-only validation. Reopen the broader `attached-html` or `google-attached-html` suite surfaces first only when the replay still needs the wider attached-page route visible before it commits to the pinned three-page bundle. Once the bundle runner or the reusable attached-page flow helpers make the next failure state clear, widen back into the broader issue `#3` helper chain instead of keeping the replay artificially pinned to the bundle lane.
