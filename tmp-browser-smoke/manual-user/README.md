# Manual User Validation

This directory is the follow-up path for real saved pages after the bounded
headed suites are green.

Use it for:

- attached or saved `.html` pages that should be served on localhost
- manual headed checks that need the real Win32 surface instead of a pure DOM
  or screenshot-only check
- issue slices where the reduced probe is green and the next question is
  whether the same behavior holds on a more realistic page snapshot

Do not start here when a narrower `tmp-browser-smoke/` suite already exists for
what you changed. Run the smallest bounded suite first.

## Quick Start

Serve a directory of saved pages and open the first page in headed mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -LaunchBrowser `
  -Wait
```

Choose a specific page first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -InitialPage subdir\page.html `
  -LaunchBrowser `
  -Wait
```

Stage mixed saved files or folders into one clean localhost run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_staged_localhost_html_validation.ps1 `
  -InputPath C:\path\to\saved-page.html, C:\path\to\saved-folder `
  -LaunchBrowser `
  -Wait
```

Stage Unicode-heavy standalone exports into an ASCII-safe localhost root while
preserving sibling `*_files` asset folders and the preferred first page:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1 `
  -InputPath C:\path\to\Control your online safety and privacy – Google Safety Centre.html, C:\path\to\saved-folder `
  -Wait
```

Auto-discover attached HTML files already present in the current workspace,
prefer `user_files/` before `agent_files/`, and launch the preferred page in
headed mode:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 `
  -Wait
```

When the same attached HTML set is part of the Google-style issue `#3` follow-up,
print the dedicated localhost-first command order without restating the file set:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Run that same Google-style attached HTML follow-up directly in one command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 `
  -Wait
```

Use `-PreferredInitialPage` when one Google-like page should stay first, or
pass `-InputPath` / `-PageRoot` when you want the attached Google helpers to
skip auto-discovery and target an explicit saved-page set.

Inventory a saved-page directory before you choose the first page to open:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\summarize_localhost_html_pages.ps1 `
  -PageRoot C:\path\to\saved-pages
```

Only print the attached HTML inventory and recommended first page without
launching the browser yet:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 `
  -SummaryOnly
```

Use the current attached-page folder as the page root when the run already has
saved HTML snapshots available locally. Use the staged wrapper when the run has
a mix of standalone HTML files and saved-page folders or when you want a
per-run manifest of exactly which HTML files were served. Use the sanitized
runner when those standalone exports have Unicode-heavy filenames, sibling
`*_files` asset folders, or need to be staged into one ASCII-safe localhost
root before the headed browser starts. Use the attached HTML runner when those
snapshots already live under `user_files/` or `agent_files/` and you want the
helper to pick the inputs and preferred initial page automatically. Use the
Google-style attached HTML helpers when those same snapshots are part of the
issue `#3` typing and Enter-submit follow-up and you want the localhost-first
Google flow preserved without reshaping the general saved-page commands by hand.

## What The Helper Records

`start_localhost_html_validation.ps1` writes the session summary and server logs
under:

- `tmp-browser-smoke\manual-user\localhost-html-validation\`

That session record includes:

- the page root that was served
- the initial page and URL
- the full list of discovered HTML pages
- the server PID
- the browser PID when `-LaunchBrowser` is used
- the stdout and stderr log paths for the local server

`start_staged_localhost_html_validation.ps1` also writes
`staged-input-manifest.json` inside the staged page root that it prepares for
each run.

`run_sanitized_saved_page_localhost_validation.ps1` writes
`sanitized-input-manifest.json` inside the staged page root that it prepares for
each run.

`summarize_localhost_html_pages.ps1` writes a JSON summary under the same
artifact root with:

- page titles when present
- URL-safe relative paths for localhost serving
- a simple interactive score to help pick the first manual follow-up page
- lightweight counts for forms, inputs, buttons, textareas, links, scripts,
  iframes, images, canvas, and `contenteditable`
- `recommended_bounded_suites` for each saved page so you can run the closest
  `tmp-browser-smoke/` gate before the manual follow-up
- `overall_recommended_suites` for the full saved-page set when several files
  or folders should be covered together
- `manual_follow_up_suite` and `next_step` guidance for the localhost pass

## Recommended Flow

1. Pick the bounded suite for the subsystem you changed with `scripts/windows/show_headed_validation_suites.ps1`.
2. Run that suite and one nearby shared-behavior suite if the change crossed subsystems.
3. If the run already has attached HTML files under `user_files/` or `agent_files/`, use `run_attached_html_localhost_validation.ps1` first so the helper can discover the inputs and choose a preferred initial page automatically.
4. If the same attached HTML set is part of the issue `#3` Google-style follow-up, use `show_google_attached_html_validation_flow.ps1` to print the localhost-first order or `run_google_attached_html_validation.ps1` to execute that same route directly.
5. If the saved pages are spread across several files or folders, stage them first with `start_staged_localhost_html_validation.ps1`. If those exports have Unicode-heavy filenames or standalone `*_files` siblings, prefer `run_sanitized_saved_page_localhost_validation.ps1` so the headed launch uses one ASCII-safe localhost root.
6. Run `summarize_localhost_html_pages.ps1` when you need a quick inventory, a suggested first page, or a recommended bounded-suite set for the saved HTML pages.
7. Run one or two of the suggested bounded suites from the summary JSON before you start the localhost manual pass.
8. Start the saved-page localhost pass from this directory's helper flow.
9. Keep notes about which attached pages still fail and whether the failure looks like input, rendering, navigation, or storage.
10. Only move to live-site checking after the saved-page pass is stable.

## Google-Style Input Work

If the issue is headed Google-style typing or Enter-submit behavior:

1. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1` when you want the current reusable issue #3 flow printed first
2. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1` when you want the current localhost-first issue #3 ladder in one command
3. run `google-investigation-next/` when you need to inspect the reduced Google-style localhost fixtures directly
4. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick` for the bounded title-plus-watch first pass
5. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home`
6. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1` when the next question is whether a saved Google homepage fixture still reaches focus, typed text, and Enter submit
7. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1` when the earlier title and reduced-homepage gates are already green and you want the later saved-homepage-fixture, submit-timing, and shared Enter-order slices in one narrower command
8. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing`
9. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order`
10. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` when the next pass should stay on the auto-discovered attached HTML set but keep the same localhost-first Google ordering
11. run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait` when you want the same attached HTML Google-style route to launch directly
12. then use `run_attached_html_localhost_validation.ps1`, `run_sanitized_saved_page_localhost_validation.ps1`, `start_localhost_html_validation.ps1`, or `start_staged_localhost_html_validation.ps1` for any broader saved HTML snapshots that are not part of the direct issue `#3` attached-page follow-up
13. finish with the smallest live-site pass that proves the same behavior

Use `-Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch` when you want the runner to execute the localhost-first Google flow in one pass before the saved-page follow-up.

## Useful Flags

- `-Port 8124` uses a different localhost port
- `-Host 0.0.0.0` exposes the same saved pages to another device on the LAN
- `-LeaveServerRunning` keeps the server alive after the wait prompt
- omit `-LaunchBrowser` when you only want the localhost URLs and logs first
- `run_attached_html_localhost_validation.ps1 -SummaryOnly` prints the auto-discovered attached-page inventory without launching the browser
- `run_attached_html_localhost_validation.ps1 -PreferredInitialPage <saved-page.html>` keeps one attached HTML page as the first headed target when the auto-selected page is not the one you want
- `run_google_attached_html_validation.ps1 -PreferredInitialPage <saved-page.html>` keeps the dedicated issue `#3` attached-page follow-up on one chosen Google-like page first
- `show_google_attached_html_validation_flow.ps1 -PreferredInitialPage <saved-page.html>` prints the same attached-page Google order with an explicit first page override
- `run_google_attached_html_validation.ps1 -InputPath <file-or-folder>, <file-or-folder>` keeps the same Google-style route while targeting an explicit saved-page set instead of auto-discovery
- `show_google_attached_html_validation_flow.ps1 -InputPath <file-or-folder>, <file-or-folder>` prints the same attached-page Google order while targeting an explicit saved-page set instead of auto-discovery
- `start_staged_localhost_html_validation.ps1 -InputPath <file-or-folder>, <file-or-folder>` stages a mixed saved-page set into one clean localhost root before the normal helper runs
- `run_sanitized_saved_page_localhost_validation.ps1 -InputPath <file-or-folder>, <file-or-folder>` stages Unicode-heavy or exported standalone saved pages into an ASCII-safe localhost root before launch
- `-InitialPage C:\path\to\saved-page.html` works with the staged wrapper when you want a specific source file to open first
- `summarize_localhost_html_pages.ps1 -PageRoot <saved-page-dir> -Port 8124` lets the saved-page inventory reflect a non-default localhost port before you launch the browser
