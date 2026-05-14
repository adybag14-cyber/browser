# Issue #3 Attached HTML Shortcut Bridge

Use this note when the current replay for issue `#3` on `fork/headed-mode-foundation` is already inside the attached localhost compatibility route and you want the shortest bridge into the narrower shortcut helpers without reopening the broader suite-catalog or replay-route notes first.

Keep these companion notes nearby when the replay needs more context:
- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
- `docs/WINDOWS_FULL_USE.md`

## Read-first discovery

Use the generic attached-page route from the top-level headed validation suite router when you want that broader attached localhost branch printed again before you narrow into the issue-specific shortcut helper:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
```

If the replay is already known to stay on the attached localhost route and you want the shortest issue-specific bridge immediately after the top-level router output, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that context directly in the attached-page shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

If you still want the broader top-level attached-page bridge visible before you drop to the shorter shortcut helper, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
```

If the replay is running from a non-default checkout, from an already-saved summary, or from an explicit bundle path, preserve that same context directly in the top-level attached-page bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

When the current pages are still the known three-page compatibility bundle and that pinned route should stay visible before widening back into the broader helper stack, use:

```powershell
.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
```

## Shortcut helper ladder

Use these in order when helpful:
- `show_headed_validation_suites.ps1 -ChangeArea attached-html` when the replay should start from the generic attached localhost compatibility route before narrowing further.
- `show_google_issue3_attached_html_shortcut_entrypoint.ps1` when the replay is already narrowed to attached-page follow-up and you want the shortest issue-specific bridge before reopening the wider helper family.
- `show_google_issue3_top_level_attached_html_entrypoint.ps1` when you still want the broader top-level attached-page bridge visible beside the issue-specific helper chain.
- `show_google_issue3_suite_router_shortcut_first_entrypoint.ps1` when no pinned bundle inputs need to take precedence and you want the tighter bridge back into the replay shortcuts, next-step matrix, or contextual flow helpers.
- `show_google_issue3_replay_route_shortcut_entrypoint.ps1` when the attached-page route is already confirmed and you want the smaller replay-route companion surface before widening again.
- `show_google_issue3_replay_shortcuts.ps1` when the route is already known to stay inside issue `#3` and you want the tightest current shortcut surface immediately.
- `show_google_issue3_suite_router_next_steps.ps1` when you want the explicit command matrix reprinted before choosing between the replay route, contextual flow, bundle-first branch, or runner-state helpers.
- `show_google_issue3_safe_route_entrypoints.ps1` only after the attached-page route has already narrowed the replay into the wrapper-heavy issue `#3` branch and you want the safe-route map surfaced again.

## Practical rule

Treat `show_google_issue3_attached_html_shortcut_entrypoint.ps1` as the default follow-up from `show_headed_validation_suites.ps1 -ChangeArea attached-html` whenever the current replay is already about the attached localhost compatibility pages and no explicit bundle inputs need to stay pinned first.

Prefer `show_google_issue3_top_level_attached_html_entrypoint.ps1` when you still want the broader top-level route beside the shortcut helper, and prefer the bundle-first route when explicit `InputPath` values are already pinned to the known three-page compatibility set.
