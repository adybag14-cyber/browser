# Issue #3 Enter-Submit Attached HTML Recheck

Use this note after the runtime slice in `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` is replayed in a writable checkout and the reduced Google fixture is green again.

This is the shortest branch-local bridge from the runtime fix back to the three attached localhost compatibility pages. It keeps the validation order narrow so the next run can tell whether a regression is still:

- inside the reduced Enter-submit runtime boundary
- specific to the Google-shaped attached-page route
- broader across the full three-page compatibility bundle

Keep these nearby:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_headed_validation_suites.ps1`
- `scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `scripts/windows/show_google_attached_html_validation_flow.ps1`
- `scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1`

## Goal

Prove that the runtime fix still behaves correctly after the replay leaves the reduced Google fixture and widens into the saved attached-page route.

The healthy path is:

1. Reduced Google fixture accepts typing and defers native Enter submit until the keypress phase.
2. The Google-shaped attached-page route stays usable on the same browser build.
3. The pinned three-page compatibility bundle still works in order, starting with the Google Safety Centre page.

If a failure appears, stop on the earliest failing rung. Do not widen the route further until that smaller surface is understood.

## Validation order

Run the steps in this order.

### 1. Reconfirm the reduced runtime surface

Use the runtime note first and do not widen out until its reduced checks are green again:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Do not continue if the reduced Google probe still drops text, submits too early on Enter keydown, or stops changing title state at the keypress boundary.

### 2. Reopen the attached-page replay ladder

Once the reduced runtime rung is healthy, reopen the narrow attached-page ladder before jumping straight into the bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use this rung to keep the replay-side checker, the Google-shaped attached-page flow, and the bundle-aware re-entry visible on one smaller surface before the route widens again.

### 3. Keep the pinned bundle surface visible

Before the actual three-page run, print the compact bundle surface again:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
```

Use this rung when the replay should stay locked to the known three-page bundle instead of drifting into a broader saved-page set.

## Pinned three-page bundle

Treat this exact set as the current compatibility bundle:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer the Google Safety Centre export as the first page when the route needs one Google-like checkpoint before the rest of the bundle.

## Page-by-page proof loop

Use this as the smallest honest replay once the runtime rung and the attached-page ladder are both back in place.

### 1. Google Safety Centre

Confirm all of these before moving on:

- the page title resolves to `Control your online safety and privacy – Google Safety Centre`
- the cookie banner renders
- `Agree` and `No thanks` both remain activatable
- one top navigation target such as `Safer by design` or `Product protections` can be focused or opened

If this page fails, keep the replay pinned here. Do not widen back out to the rest of the bundle yet.

### 2. Anthropic application page

Confirm all of these before moving on:

- the live application form is reachable
- one select-style field such as `Gender` can be opened and closed
- `Submit application` remains reachable after scrolling

### 3. UAP encounters page

Confirm all of these before calling the bundle healthy:

- the title resolves to `Presidential Unsealing and Reporting System for UAP Encounters | U.S. Department of War`
- the search input accepts focus and typed text
- one `record-row` entry opens the detail modal
- `Close` returns to the list
- pagination advances without crashing the headed session

## Stop rules

Stop on the first failing rung and record the narrowest truthful boundary.

- Reduced Google fixture fails: stay inside `Page.zig` plus `win32_backend.zig` runtime work.
- Reduced fixture passes but the Google attached-page flow fails: stay on the Google-shaped attached-page route.
- Google attached-page flow passes but one later bundle page fails: treat that as a broader compatibility regression, not a reason to reopen the Enter-submit runtime slice by default.

## Logs to inspect

If the replay diverges before submit or page-level interaction:

- `runtime-input-backend-*.log`
- `wndproc-input-*.log`
- any saved manifest output from the attached-page launcher helpers

Compare the first bad title transition or first missing UI state against the validation rung where the replay last stayed healthy.

## Practical rule

After the runtime slice is replayed, always re-enter the attached-page route through the reduced Google fixture first, then the Windows replay attached-html quickstart, then the Google-shaped attached-page flow, and only then the pinned three-page proof loop.

That order keeps the next writable checkout from blaming the full compatibility bundle too early when the smaller runtime or Google-shaped surfaces would have isolated the regression faster.
