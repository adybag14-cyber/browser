# Issue #3 Local HTML Fixture Entrypoints

Use this note when issue `#3` work starts from saved local HTML exports instead of a fresh network session and you want the shortest written bridge from the generic Windows fixture replay path into the narrower attached-page helpers.

Keep these companion notes nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md`

## Goal

Start from the reusable local-fixture replay surface, confirm the saved HTML pages and their sibling asset folders still stage correctly behind localhost, then pick the narrowest issue `#3` attached-page route that matches the current replay.

This is the right entrypoint when the current bundle still includes the saved Google Safety Centre page, the Anthropic job page, and the UAP reporting page, or when a nearby variation of that same saved-page bundle is already available on disk.

## Start with the generic local-fixture probe

Use the reusable local-fixture probe first when you want a quick headed smoke pass before the issue `#3` helper chain narrows further:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 `
  -FixturePaths `
    "C:\path\to\Control your online safety and privacy – Google Safety Centre.html",`
    "C:\path\to\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic.html",`
    "C:\path\to\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
```

Use that route when:

- you want a quick headed replay that stages each saved file behind localhost
- you want screenshots and window-title checks before reopening the more specialized issue `#3` notes
- you need to confirm that sibling `<page-base>_files` asset folders still sit next to the saved HTML pages before spending time on a narrower regression run

## Route the replay through the validation catalog

Once the generic local-fixture probe is still healthy, reopen the attached-page surfaces from the validation catalog before choosing a narrower issue `#3` helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- the broader validation catalog already points at attached localhost follow-up
- you want the bundle-first, generic attached-page, and Google-shaped attached-page lanes visible together before narrowing again
- the replay needs a written bridge from the generic fixture probe into the issue `#3` helper family

## Pinned three-page bundle route

If the replay should stay locked to the known three-page compatibility bundle, use the bundle-first route next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -InputPath '<bundle-html-or-folder>' -Wait
```

Use that route when:

- the current replay still targets the saved three-page bundle exactly
- you want the bundle surface check to fail fast before reopening a headed window
- the next step should stay on the compatibility bundle instead of widening into the broader attached-page chain

## Google-shaped attached-page route

If the current saved-page bundle still includes a Google-like page and you want the stricter Google-first helper chain visible before the route narrows again, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- the replay still needs the Google-shaped attached-page flow printed before narrowing into the shorter issue `#3` quickstarts
- you want the Google-specific surface check and attached-page flow helper visible on the same pinned input set
- the next handoff is likely to reopen the Google search-box debugging lane instead of the more generic attached-page route

## Replay-side quickstart

If the replay already came from the broader Windows runbook or the issue `#3` replay shortcuts, drop into the replay-side attached-page quickstart next:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -InputPath '<bundle-html-or-folder>'
```

Use that route when:

- the replay is already inside the issue `#3` helper chain and just needs the attached-page ladder reopened
- you want the replay-side quickstart to stay aligned with the broader attached-page route and the bundle-first branch
- the narrower follow-up should be chosen from the replay-side notes rather than from the top-level Windows runbook again

## Preserve replay context

If the replay already carries a non-default repo root, a saved summary path, or explicit bundle paths, preserve that same context on the next helper instead of retyping the route from scratch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_catalog_entrypoints.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that context-preserving form when:

- `LIGHTPANDA_REPO_ROOT` must stay attached to the follow-up helpers
- a saved summary already points at current replay outputs
- explicit bundle paths are already pinned to the saved local HTML exports
