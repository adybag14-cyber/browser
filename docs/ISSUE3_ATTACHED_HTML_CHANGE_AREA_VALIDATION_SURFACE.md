# Issue #3 Attached HTML Change-Area Validation Surface

Use this note when the next headed replay is already narrowed to `show_headed_validation_suites.ps1 -ChangeArea attached-html` and you want the fail-fast surface check for that branch before trusting the smaller attached-page helper chain.

## Goal

Make sure the issue `#3` attached localhost change-area route is still intact before you spend time reopening helper ladders, staging attached pages, or launching a headed browser.

The matching checker is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1
```

## Default read-first sequence

Use this compact sequence when no non-default checkout, saved summary, or pinned attached bundle path needs to take precedence first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use that route when:

- the top-level validation router already made attached localhost follow-up the next obvious branch
- you want missing notes, helper scripts, or attached-page follow-up surfaces to fail fast before replay narrows further
- you want the broader attached-page flow helper and the Google-shaped attached-page flow helper kept nearby after the surface check passes

## Preserve replay context

If the replay is already running from a non-default checkout, an already-saved summary, or explicit attached bundle paths, preserve that same context in the narrower attached-page helper right after the surface check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1 -RepoRoot '<repo-root>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'
```

Use that form when:

- `LIGHTPANDA_REPO_ROOT` must stay aligned with later attached-page helpers
- a saved `SummaryPath` already points at current replay outputs
- explicit `InputPath` values are already pinned to the known attached-page compatibility set

## What the checker guards

The surface check confirms that the attached-html change-area route still has the written notes and helper scripts it depends on before replay narrows into issue-specific helpers.

That includes the main route families behind this branch:

- `docs/WINDOWS_FULL_USE.md` and the Windows-first attached-page notes
- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md` and the newer attached-page quickstart notes
- `scripts/windows/show_headed_validation_suites.ps1` and the attached-html change-area helper scripts
- the broader attached-page flow helper and the Google-shaped attached-page flow helper
- the validation-router, top-level, suite-router, suite-catalog, bundle-first, replay-shortcut, and safe-route follow-up helpers that the change-area quickstart can reopen

## After a failure

If the checker fails, repair the missing note, helper, or follow-up script before you trust the attached localhost change-area route.

Start with the smallest missing surface first:

1. Restore the missing note or helper named by the checker.
2. Re-run `check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1`.
3. Only reopen `show_google_issue3_attached_html_change_area_quickstart.ps1` after the surface check returns cleanly.
4. Widen back out to `show_attached_html_validation_flow.ps1` or `show_google_attached_html_validation_flow.ps1` only when the attached-page route itself is intact again.

## Practical rule

Once `show_headed_validation_suites.ps1 -ChangeArea attached-html` has already made attached localhost replay the next obvious branch, prefer this surface checker before the smaller quickstart helper whenever the branch may have moved, helpers may have been renamed, or you are reopening the route after a longer pause.

Keep these companion notes nearby when you want the written route beside the checker:

- `docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md`
- `docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md`
