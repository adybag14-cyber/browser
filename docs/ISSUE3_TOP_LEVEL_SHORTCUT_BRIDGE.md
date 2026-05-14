# Issue #3 Top-Level Shortcut Bridge

Use this note when issue `#3` work is re-entering from the top-level headed validation suite router and you want the shorter top-level shortcut-first helper kept visible before the replay widens back into the larger bridge notes.

If you want the shortest top-level issue `#3` bridge first, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

If the replay is already running from a non-default checkout, from an already-saved summary, or from explicit attached-bundle paths, preserve that same context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Keep these companion notes nearby when you want the wider route spelled out too:

- `docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md`
- `docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md`
- `docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md`
- `docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`

## Goal

Keep the first issue `#3` commands stable when you start from the higher-level suite router and already know the next replay should stay inside the newer shortcut-first helper chain.

Use this bridge when you want the top-level router commands, the attached-page compatibility branch, the replay-route shortcut, and the narrower issue `#3` shortcut helpers kept aligned in one small note before you widen back into the next-step matrix, replay-route helper, bundle-first branch, or safe-route wrappers.

## Default read-first sequence

Use these commands in order when no saved summary, non-default repo root, or pinned bundle inputs need to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1
```

Use that route when the top-level suite router already made issue `#3` obvious and you want the shorter helper chain reprinted before widening back into the broader replay-route or wrapper-heavy safe-route notes.

## Attached-page route handoff

If the replay is already narrowed to the attached localhost HTML route and you still want the top-level shortcut surface kept nearby, start from the top-level router, reopen the broader attached-page runbook and quickstart, and then reopen the top-level shortcut helper before choosing the narrower attached-page helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
```

From there, choose the follow-up that matches the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use the Windows full-use attached HTML route first when the replay was reopened from `docs/WINDOWS_FULL_USE.md` and the broader runbook-side attached-page bridge should stay visible before dropping back to the shortcut-first helper.

Use the top-level attached HTML quickstart first when the shorter attached-page bridge should stay visible beside the top-level shortcut surface before the route narrows again.

Use the top-level attached HTML entrypoint first when you still want the broader top-level attached-page bridge visible before narrowing into the suite-catalog-side attached-page bridge, the issue-specific attached-page shortcut, or the replay shortcuts.

Use the suite-catalog attached HTML entrypoint first when you want the suite-catalog-side attached-page bridge kept visible before narrowing into the issue-specific attached-page shortcut or the replay shortcuts.

Use the attached HTML shortcut first when the attached-page compatibility branch should stay visible before you widen back into replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route helpers.

Use the replay-route shortcut first when the route is already narrow enough that you want the smaller attached-page, replay-shortcuts, bundle-first, and safe-route companion surface before reopening the broader replay-route or matrix helpers.

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary, or pinned bundle inputs, keep that same context attached to the broader attached-page helpers before you narrow back into the top-level shortcut helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Then carry that same context into the narrower follow-up that matches the route you are on:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving route when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to later helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known three-page compatibility bundle

## Pick the next helper quickly

1. Suite-router shortcut entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```

Use this when you want the shortest bridge from the top-level shortcut surface into the narrower replay-route and replay-shortcuts path.

2. Suite-catalog attached HTML entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_attached_html_entrypoint.ps1
```

Use this when the replay is already coming from attached-page follow-up and you want the suite-catalog-side attached-page bridge kept visible before narrowing again.

3. Attached HTML shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1
```

Use this when the attached-page compatibility branch should stay visible before you widen back into replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route map.

4. Replay-route shortcut

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```

Use this when the route is already narrow enough that you want the smaller attached-page, replay-shortcuts, bundle-first, and safe-route companion surface before reopening the broader replay-route helper.

5. Replay shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1
```

Use this when the route is already clearly inside issue `#3` and you want the tightest compact helper surface before deciding whether to widen again.

6. Contextual flow

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_contextual_flow.ps1
```

Use this when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.

7. Attached bundle first

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
```

Use this when explicit `InputPath` values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.

## Practical rule

Start from the top-level headed validation suite router, then reopen `show_google_issue3_top_level_shortcut_first_entrypoint.ps1` when the route is already clearly inside issue `#3` and you want the shorter helper ladder printed before the replay widens again.

- no pinned bundle inputs and no saved replay state yet: go from the top-level suite router to the top-level shortcut helper, then the suite-router shortcut helper, then the replay-route shortcut helper, then replay shortcuts, then the safe-route map
- attached localhost HTML route already in focus: go from `-ChangeArea attached-html` to `show_google_issue3_windows_full_use_attached_html_route.ps1` when the replay was reopened from `docs/WINDOWS_FULL_USE.md`, then `show_google_issue3_top_level_attached_html_quickstart.ps1`, then the top-level shortcut helper, then the top-level attached-page bridge, the suite-catalog attached-page bridge, the attached-page shortcut, or the replay-route shortcut before widening again
- saved summary or repo-root override already present: use the broader attached-page helpers plus the top-level shortcut helper with that same context first, then choose contextual flow, replay-route shortcut, replay shortcuts, or the suite-catalog attached-page bridge only as needed
- explicit bundle paths already pinned: stay on the bundle-first helper before widening back into the broader Google-only path

Only reopen the longer validation-chain notes after the route has narrowed into the wrapper-heavy safe path.
