# Attached HTML Localhost Validation

Use this runbook when headed-mode work needs a manual follow-up against saved or
attached standalone `.html` snapshots instead of only the built-in
`tmp-browser-smoke/` fixtures.

This is the narrowest path for the three attached compatibility targets that are
currently carried with the headed-mode workspace, but the same flow also works
for any future saved-page set.

Read this with:
- `docs/WINDOWS_FULL_USE.md`
- `tmp-browser-smoke/README.md`
- `tmp-browser-smoke/manual-user/README.md`
- `docs/HEADED_MODE_VALIDATION_GATES.md`

## Rule

Do not start with a manual saved-page browse when a bounded headed suite already
covers the subsystem you changed.

Use this order:
1. Pick the closest bounded suite first.
2. Run that suite and one nearby shared-behavior suite when the change crosses
   subsystems.
3. Move to this localhost saved-page follow-up only after the bounded proof is
   green or the bounded failure is already understood.

## Current attached snapshot profile

The current attached HTML files fall into three different validation shapes.
The recommendations below come from their current structure, not just from the
page names.

### 1. Safety Centre-style document page

Current example:
- `Control your online safety and privacy ... Google Safety Centre ... .html`

Observed shape:
- no forms or text inputs
- many links and images
- multiple scripts and iframes

Best first suites:
- `layout-smoke`
- `wrapped-link`
- `rendered-link-dom`
- `image-smoke`

Use this page when the suspected regression is mostly visual layout, image
loading, link hit-testing, or general document-shell rendering.

### 2. Application-form page

Current example:
- `Job Application for ... Anthropic ... .html`

Observed shape:
- one form
- many inputs and buttons
- several textareas
- scripts and iframes

Best first suites:
- `form-controls`
- `inline-flow`
- `layout-smoke`
- `wrapped-link`

Use this page when the suspected regression is typing, focus order, Enter
submit behavior, label/control interaction, or mixed form-plus-layout behavior.

### 3. Dense navigation and control page

Current example:
- `Presidential Unsealing and Reporting System for UAP Encounters ... .html`

Observed shape:
- one form
- many links and buttons
- moderate image usage
- heavy script presence

Best first suites:
- `wrapped-link`
- `form-controls`
- `layout-smoke`
- `rendered-link-dom`

Use this page when the suspected regression is navigation chrome, complex link
activation, button behavior, or script-heavy page interaction that still stays
within one saved snapshot.

## Fast inventory commands

When the saved pages are already sitting in a local `agent_files` directory,
start by capturing them as one input list:

```powershell
$attached = Get-ChildItem .\agent_files\*.html | Select-Object -ExpandProperty FullName
```

Summarize the set and let the helper suggest the first page plus the closest
bounded suites:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\summarize_localhost_html_pages.ps1 `
  -InputPath $attached
```

If you already know which page should open first, keep that choice explicit.
For the current attached set, the application-form snapshot is the most useful
first page for input and focus work:

```powershell
$preferred = $attached | Where-Object { $_ -like '*Anthropic*' } | Select-Object -First 1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\summarize_localhost_html_pages.ps1 `
  -InputPath $attached `
  -PreferredInitialPage $preferred
```

## Localhost launch flow

Stage the mixed standalone HTML files into one clean localhost run and open the
preferred page directly in the headed browser:

```powershell
$attached = Get-ChildItem .\agent_files\*.html | Select-Object -ExpandProperty FullName
$preferred = $attached | Where-Object { $_ -like '*Anthropic*' } | Select-Object -First 1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_staged_localhost_html_validation.ps1 `
  -InputPath $attached `
  -InitialPage $preferred `
  -LaunchBrowser `
  -Wait
```

If the pages already live under one clean saved-page directory, skip staging and
serve that directory directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_localhost_html_validation.ps1 `
  -PageRoot C:\path\to\saved-pages `
  -InitialPage form\page.html `
  -LaunchBrowser `
  -Wait
```

## Flow helper commands

Print the command order without launching anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_localhost_html_validation_flow.ps1 `
  -InputPath $attached `
  -PreferredInitialPage $preferred
```

Use the Google-specific saved-page flow only when the summary helper or the
actual regression makes the page look like a search-box, delayed-readiness, or
Enter-submit issue related to issue `#3`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 `
  -InputPath $attached `
  -PreferredInitialPage $preferred
```

For the current three attached snapshots, the general localhost flow is the
right default. They are not the first stop for the live Google homepage issue.

## Expected artifacts

The localhost helpers write their run artifacts under:
- `tmp-browser-smoke\manual-user\localhost-html-validation\`

Keep these from every saved-page pass:
- the summary JSON from `summarize_localhost_html_pages.ps1`
- `localhost-html-session.json`
- the staged manifest when staging was used
- server stdout and stderr logs
- notes on which page still failed and whether the failure looked like input,
  rendering, navigation, downloads, or storage

## Decision guide

Use the attached application-form page first when:
- the suspected bug is typing
- focus is unstable
- Enter submit order matters
- textareas or mixed form controls are involved

Use the Safety Centre-style page first when:
- the suspected bug is visual
- links or images do not line up with what is painted
- iframes or general document composition look wrong

Use the dense navigation page first when:
- the suspected bug is activation order across many links and buttons
- the page feels script-heavy but does not need a live network follow-up yet
- you want a more stressful saved snapshot before leaving localhost validation

If none of the saved pages matches the behavior you changed, return to the
bounded `tmp-browser-smoke/` suite map and pick the better synthetic probe
instead of forcing the wrong manual page into service.
