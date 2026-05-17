# Issue #3 Top-Level Attached HTML Bundle Re-Entry

Use this note when the replay is already reopening from the top-level attached localhost HTML route and the next step should stay pinned to the known three-page compatibility bundle.

Keep these nearby:

- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`

## Goal

Print one smaller route that keeps the broader top-level attached-page context visible while the replay narrows into the compact bundle suite surface, the pinned bundle surface check, the bundle flow helper, the narrower bundle-first handoff, the delegated bundle runner, and the proof follow-up.

## Read-first route

Use this sequence when no explicit bundle inputs are pinned yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_bundle_reentry.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
```

Use that route when:

- the top-level attached-page bridge is already the right issue `#3` entry surface
- the current replay is likely to stay on the known three-page compatibility bundle
- you want the broader attached-page flow and the dedicated Google-shaped attached-page flow visible beside the compact bundle route before the bundle lane is trusted
- you want the pinned bundle surface check to fail fast before the delegated bundle runner takes over

## Context-preserving route

If a non-default repo root, saved summary, or explicit bundle paths are already in play, keep that same context attached to every step:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_bundle_reentry.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>' -Wait
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- explicit bundle inputs are already pinned and should stay attached to the narrower bundle-first handoff
- a saved summary already points at the current replay outputs
- the replay should move from the broader top-level bridge straight into the pinned bundle lane without rediscovering the helper order by hand

## Practical rule

Start with the broader top-level attached-page bridge when the route still needs that wider context reprinted. Once the bundle lane is the likely next branch, prefer this smaller bundle re-entry helper before the replay widens back into replay shortcuts, contextual flow, or the wrapper-heavy safe-route notes.
