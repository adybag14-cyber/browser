# Issue #3 Suite-Catalog Attached HTML Flow Context

Use this note when the issue `#3` suite-catalog route is already open but the broader attached-page localhost flow still needs to keep the same `RepoRoot`, saved summary, or pinned attached-page inputs before the replay narrows back into the shorter helper chain.

If you want that compact context-preserving bridge first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_flow_context.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_flow_context.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Goal

Start from `show_google_issue3_suite_catalog_entrypoints.ps1`, rerun the suite-catalog surface check when needed, reopen `show_headed_validation_suites.ps1` for `attached-html`, `google-attached-html`, and `attached-html-target-bundle`, then move into the broader attached-page localhost flow with the same repo-root override and pinned inputs still attached before the replay narrows into the validation-router quickstart, Windows replay quickstart, suite-catalog attached-page bridge, attached-page shortcut, replay shortcuts, or bundle-first helper.

## Default context-preserving route

Use this route when the suite-catalog helper is already the right entry surface but the broader attached-page flow still needs the current replay context:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
```

Use that route when:

- the suite-catalog helper already made attached localhost follow-up obvious
- the broader attached-page localhost flow must stay on the same pinned saved pages instead of widening back to generic auto-discovery
- the narrower Google-shaped attached-page flow should stay visible beside the broader attached-page helper before the route narrows again
- the replay may still need to pivot into the known three-page compatibility bundle without losing the current pinned inputs

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or pinned bundle inputs, keep that same context attached to the broader attached-page flow helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_flow_context.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -Command "$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_attached_html_validation_flow.ps1' -InputPath '<bundle-html-or-folder>'"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned to a non-default checkout
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned and the broader attached-page localhost flow should stay on those same pages

## Pinned bundle route

If the current pages are already the known three-page compatibility bundle, keep the broader attached-page flow and the bundle-first helper on the same locked input set:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_flow_context.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -Command "& '.\scripts\windows\show_attached_html_validation_flow.ps1' -InputPath '<bundle-html-or-folder>'"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when the replay should stay pinned to the known three-page compatibility bundle before widening back into the broader issue `#3` helper chain.

## Practical rule

Keep `show_google_issue3_suite_catalog_attached_html_flow_context.ps1` nearby whenever the suite-catalog route is already open and the next replay still depends on the broader attached-page localhost flow staying on the same repo-root override or pinned inputs. Narrow back into the shorter attached-page quickstarts only after that broader context-preserving flow is clear.
