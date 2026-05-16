# Issue #3 Attached HTML Router Fallbacks

Use this note when issue `#3` replay is already narrowed to attached localhost HTML follow-up but the current top-level validation router still leaves the broader attached-page fallback as a manual next step.

Start here when you want one compact helper that reprints the broader attached-page fallback commands before the route narrows again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_router_fallbacks.ps1
```

If the replay already carries a non-default checkout, a saved summary, or pinned attached bundle paths, preserve that context directly in the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_router_fallbacks.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

## Goal

Keep the broader attached-page fallback visible from the issue `#3` attached-page lane without reopening the full validation-note chain by hand.

Use this helper when you want these routes reprinted together on one compact surface:

- `show_headed_validation_suites.ps1 -ChangeArea attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
- `show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle`
- `show_google_issue3_attached_html_change_area_quickstart.ps1`
- `show_attached_html_validation_flow.ps1`
- `show_google_attached_html_validation_flow.ps1`
- `show_google_issue3_validation_router_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_quickstart.ps1`
- `show_google_issue3_top_level_attached_html_entrypoint.ps1`
- `show_google_issue3_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1`
- `show_google_issue3_attached_bundle_first_entrypoint.ps1`

## Practical rule

1. Start with the router fallback helper when the replay is already on the attached localhost branch and you want the broader attached-page fallback commands surfaced directly.
2. Stay on `show_google_issue3_attached_html_change_area_quickstart.ps1` plus `show_attached_html_validation_flow.ps1` when the route should remain generic attached-page first.
3. Switch to `show_google_attached_html_validation_flow.ps1` when the current attached page set is still clearly Google-shaped.
4. Stay on `show_google_issue3_attached_bundle_first_entrypoint.ps1` when explicit `InputPath` values are already pinned to the known three-page compatibility bundle.
5. Use `show_google_issue3_contextual_flow.ps1` when `RepoRoot`, `SummaryPath`, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned.

## Companion notes

Keep these nearby when you want the written route beside the helper output:

- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md`
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
