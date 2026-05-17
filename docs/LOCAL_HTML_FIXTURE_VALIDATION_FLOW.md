# Local HTML Fixture Validation Flow

Use this note when a headed-mode failure is already best reproduced by a small,
fixed list of saved HTML pages and you want the shortest read-first path before
replaying them through localhost.

This route is narrower than the broader attached-page helpers. It is meant for
cases where the current reproduction set is already known and you want one
repeatable screenshot-and-title proof pass before widening back out into the
larger wrapper chain.

## Goal

- fail fast if the reusable local fixture validation surface drifted
- replay the same saved HTML pages through localhost and headed `browse`
- capture screenshots and confirm the native window title matches each page
  `<title>`
- keep the broader attached-page fallbacks visible for the next step

## Default sequence

Start with the shared suite router when you want to rediscover the saved-page
fixture route from the main Windows validation catalog, then run the dedicated
surface check and the fixed-list probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea local-html-fixtures
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_local_html_fixture_validation_flow.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1 -InputPath '<saved-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 -FixturePaths '<saved-html-or-folder>'
```

Use that route when:

- the current failure is already narrowed to one small saved-page set
- you want the reusable localhost probe rather than the broader attached-page
  wrapper
- screenshot-and-title proof is the next most useful checkpoint

## What the probe proves

For each saved HTML page, the probe:

- stages the HTML file behind a localhost server
- stages a sibling `<page-base>_files/` asset directory when one exists
- launches headed `browse`
- captures a screenshot
- checks that the native window title matches the page `<title>`

Outputs land under:

- `tmp-browser-smoke/local-html-fixtures/output/fixture-results.json`
- `tmp-browser-smoke/local-html-fixtures/output/*.png`
- browser and server stdout/stderr logs under
  `tmp-browser-smoke/local-html-fixtures/output/`

## Broader fallbacks

If the saved-page replay makes the next failure state clear but the route now
needs the wider wrapper chain, reopen the broader attached-page helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
```

Use the broader attached-page flow when the fixed list is no longer the right
reproduction set. Use the Google-shaped attached-page flow when the replay
should stay aligned with the issue `#3` Google-style branch.

## Practical rule

Prefer this fixed-list route when the current reproduction set is already known.
Prefer the broader attached-page helpers when the next run still needs discovery,
bundle routing, or the larger issue `#3` helper surface.
