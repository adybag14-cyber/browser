# Issue #3 Attached HTML Target Bundle Manual Checklist

Use this note when the headed replay is already narrowed to the current three-page attached HTML compatibility bundle and you want the shortest honest manual validation loop before widening back into the longer route docs.

Keep these nearby:
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md`
- `docs/WINDOWS_FULL_USE.md`
- `tmp-browser-smoke/attached-pages/README.md`

## Current pinned bundle

Use this exact file set when a note says the replay is pinned to the current compatibility bundle:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

## Purpose

This checklist is for quick signal, not exhaustive coverage.

Use it to answer three questions fast:
- does headed startup still reach the local bundle cleanly
- do the three pages still exercise the expected interaction classes
- did the failure boundary move closer to Google-specific input, broader form/input behavior, or broader headed stability

## Recommended order

Run the pages in this order and stop at the first hard failure:

1. Google Safety Centre
2. Anthropic application
3. U.S. Department of War UAP page

That order keeps the issue `#3` Google-shaped signal first, then widens into richer form and modal behavior only if the first page stays healthy.

## Preflight

If branch state or attached-page inputs may have drifted, rerun the compact guards first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -InputPath '<bundle-folder-or-html>'
```

If those are already known-good and the bundle is unchanged, move straight to the manual loop below.

## Launch route

Use the normal attached-pages launcher path so the replay stays on localhost-backed copies of the pinned bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<bundle-folder-or-html>' -PreferredInitialPage 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath '<bundle-folder-or-html>' -PreferredInitialPage 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -InputPath '<bundle-folder-or-html>' -PreferredInitialPage 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' -Wait
```

If the replay already has a pinned repo root or browser binary, carry the same `-RepoRoot` and `-BrowserExe` through all three commands.

## Page checks

### 1. Google Safety Centre

Minimum pass conditions:
- title resolves to `Control your online safety and privacy – Google Safety Centre`
- the cookie banner becomes interactive
- both `Agree` and `No thanks` can be activated in separate runs without freezing the page
- one top navigation target such as `Safer by design` or `Product protections` can be focused or opened

Strong signal:
- a failure here still points most directly at the issue `#3` Google-shaped input and interaction path

### 2. Anthropic application

Minimum pass conditions:
- the application form reaches an interactive state
- one select-style field such as `Gender` opens and closes
- `Submit application` remains reachable after scrolling
- the session stays alive after a longer form-style interaction loop

Strong signal:
- a failure here widens the problem toward general form, focus, or scroll stability rather than only the Google homepage path

### 3. U.S. Department of War UAP page

Minimum pass conditions:
- title resolves to `Presidential Unsealing and Reporting System for UAP Encounters | U.S. Department of War`
- the search input accepts focus and typed text
- one `record-row` entry opens the detail modal
- `Close` returns to the list cleanly
- pagination advances without crashing the headed session

Strong signal:
- a failure here widens the problem toward modal, list, or pagination behavior on denser app-like pages

## Failure capture

When the first failing page is identified, keep the next replay narrow and save the smallest useful evidence set:

- page name
- first failing action
- whether focus appeared visible
- whether typed text actually committed
- whether navigation, modal open, or modal close fired
- whether the whole headed session stayed alive
- fresh `runtime-input-backend-*.log` and `wndproc-input-*.log` files when the failure still looks input-related

Do not widen back into the longer route stack until that first failing page is written down.

## Result matrix

Use this matrix to pick the next lane quickly:

- Google fails first: reopen the issue `#3` runtime slice in `src/browser/Page.zig` and `src/display/win32_backend.zig`
- Google passes but Anthropic fails: widen toward shared form, focus, scroll, or select behavior
- Google and Anthropic pass but UAP fails: widen toward modal, list, pagination, or denser app-surface behavior
- All three pass: treat the pinned compatibility bundle as green and move back to the highest-priority headed runtime or broader product lane

## Practical rule

This checklist is meant to shorten future scheduled runs.

Use the longer route notes when the launch surface itself is unclear. Use this checklist when the launch route is already known and the next question is simply which page fails first and what that says about the next headed-mode lane.