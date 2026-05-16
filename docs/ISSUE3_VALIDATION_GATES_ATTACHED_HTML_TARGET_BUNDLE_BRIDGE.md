# Issue #3 Validation-Gates Attached HTML Target-Bundle Bridge

Use this note when `docs/HEADED_MODE_VALIDATION_GATES.md` already narrowed issue
`#3` to the attached HTML bundle gate and you want the newer compact bundle
suite-surface helper visible before the replay drops into the pinned three-page
bundle runner.

Keep these nearby:

- `docs/HEADED_MODE_VALIDATION_GATES.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`

## Read-first route

Start from the same top-level validation-gates branch, then reopen the compact
bundle suite surface before narrowing further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
```

Use that route when the current attached pages are still the known three-page
compatibility bundle and you want the compact bundle surface, the broader
attached-page helper, and the narrower Google-shaped attached-page helper
visible together before bundle-only execution.

## Keep the neighboring attached-page ladders visible

When the route may still widen back out after the pinned bundle replay, keep
both attached-page helper ladders nearby:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that broader view when one of the pinned bundle pages still makes the wider
attached-page or Google-shaped attached-page route the next likely follow-up.

## Narrower issue #3 re-entry

If the top-level validation-gates route is already carrying explicit bundle
paths, a saved summary, or a non-default repo root, keep the bundle-aware
re-entry helpers nearby too:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use the bundle-first helper when the replay is already pinned to the current
bundle inputs and the next step is choosing the narrowest issue `#3` bridge
before the delegated bundle runner.

## Context-preserving form

If the replay is already running from a non-default checkout, a saved summary,
or explicit attached bundle paths, preserve that same context on the bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Practical rule

- Start from `docs/HEADED_MODE_VALIDATION_GATES.md` when the task is still being
  chosen from the top-level validation router.
- Reopen the compact bundle suite helper immediately after the
  `attached-html-target-bundle` change-area command when the three-page bundle
  is already the likely next route.
- Keep the broader attached-page helper and the narrower Google-shaped
  attached-page helper visible until the pinned bundle replay makes the next
  failure state clear.
- Once the bundle route is understood, widen back into the broader issue `#3`
  helper chain instead of staying pinned to the bundle lane longer than needed.
