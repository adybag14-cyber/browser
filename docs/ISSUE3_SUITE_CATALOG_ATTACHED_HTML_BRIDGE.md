# Issue #3 Suite-Catalog Attached HTML Bridge

Use this note when issue `#3` work is re-entering from the suite-catalog
surface and you want the attached localhost HTML route kept visible before the
replay narrows into replay shortcuts, the pinned bundle route, or the broader
safe-route wrappers.

This note should stay aligned with the dedicated attached-html helper surface
printed by:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Keep the broader suite-catalog guide nearby when the replay still needs the
wider catalog surface before dropping to the narrower attached-html ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
```

Fail fast before trusting the narrower chain when helper names, note paths, or
delegated bundle follow-ups may have drifted:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1 -RepoRoot '<repo-root>'
```

If the replay is already running from a non-default checkout, from an
already-saved summary, or from explicit attached bundle paths, preserve that
context directly in the dedicated helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Goal

Keep the attached-page route aligned with the dedicated suite-catalog
attached-html helper ordering:

1. Confirm the suite-catalog surface is intact.
2. Reprint the broader `show_headed_validation_suites.ps1` entrypoints for
   `google-recommended`, `google-input`, `attached-html`,
   `google-attached-html`, and `attached-html-target-bundle`.
3. Reopen the attached-html change-area helper, the broader attached-html flow,
   the dedicated Google attached-html surface check, and the dedicated Google
   attached-html flow before narrowing further.
4. Reopen the replay-side and validation-router attached-html quickstarts.
5. Reopen the suite-catalog-to-top-level, suite-router, and top-level
   attached-html bridges in the same order printed by the helper.
6. Narrow into replay shortcuts, contextual flow, replay-route, or the pinned
   bundle lane only after the broader attached-page route has been surfaced.
7. Reopen the safe-route wrappers only after the narrower attached-page and
   bundle-specific branches are already in view.

## Current Default Next Helper

The live attached-html helper chooses its default next command from replay
context:

- No pinned bundle inputs, non-default repo root, or saved summary:
  `show_google_issue3_replay_shortcuts.ps1`
- Non-default repo root or saved summary already in play:
  `show_google_issue3_contextual_flow.ps1`
- Explicit bundle input paths already pinned:
  `show_google_issue3_attached_bundle_first_entrypoint.ps1`

Treat that recommendation order as the source of truth for this bridge note.
If the note and the helper ever disagree again, refresh the note to the helper,
not the other way around.

## Read-First Bridge

Use this compact bridge when the route is entering from the suite catalog and no
saved replay state needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use that bridge when you want one written route that matches the narrower
attached-html helper surface instead of reopening from the broader suite-catalog
note alone.

## Pinned Bundle Re-Entry

If explicit `InputPath` values are already pinned to the known three-page
compatibility bundle, keep the bundle-specific lane visible before widening
again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`,
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`, and
`docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md` nearby when that route
is already the likely next move. Keep the broader attached-page flow helper and
the dedicated Google attached-page flow helper visible on that same pinned route
first when you still want the wider attached-page ladder rediscoverable before
the bundle-first helper locks onto those three pages.

## Preserve Replay Context

If the replay already carries a non-default repo root, a saved summary path, or
pinned bundle inputs, preserve that same context on the attached-html helper and
its narrower follow-ups:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -NoProfile -ExecutionPolicy Bypass -Command "`$env:LIGHTPANDA_REPO_ROOT = '<repo-root>'; & '.\scripts\windows\show_attached_html_validation_flow.ps1' -InputPath '<bundle-html-or-folder>'"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep the broader attached-page flow helper pinned to the same attached-page set
before the route narrows into the dedicated Google-shaped helper, replay
shortcuts, contextual flow, or the bundle-first lane.

## Companion Notes

Keep these nearby when you want the written route beside the helper output:

- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Practical Rule

From the suite-catalog attached-html side, trust the helper ordering over older
note wording. Default to replay shortcuts only when there is no pinned bundle
input, no non-default repo root, and no saved summary already in play. Move to
contextual flow when replay context already matters. Move to the bundle-first
helper when the three-page compatibility set is already pinned. Reopen the
broader safe-route wrappers only after the narrower attached-page and
bundle-specific branches have already been surfaced.