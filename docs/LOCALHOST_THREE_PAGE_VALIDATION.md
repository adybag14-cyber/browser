# Localhost Three-Page Validation

Use this runbook when the headed branch should be checked against the pinned
three-page compatibility bundle through a plain localhost server instead of the
saved-page router alone.

Read this together with:
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_VALIDATION_MATRIX.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## When To Use This

Use this loop when:
- the branch already passed the smallest bounded probe for the area you changed
- you want a real headed-browser pass on the saved compatibility pages through
  `http://127.0.0.1/...`
- you want to separate localhost serving problems from saved-page router
  problems

Do not start here when a smaller bounded probe already reproduces the bug.
Start with the matching bounded route from `docs/HEADED_MODE_VALIDATION_MATRIX.md`
first, then widen into this loop only after the smaller signal is clear.

## Required Bundle

Keep these three exports and their sidecars/assets together in one folder:

- Google Safety Centre export
- Anthropic application export
- U.S. Department of War UAP export

If the exact exported filenames are awkward to type, use the Python directory
listing page as the launch surface instead of hand-writing encoded URLs.

## Localhost Bring-Up

From the folder that contains the three saved pages, run:

```powershell
python -m http.server 8000 --bind 127.0.0.1
```

Then start the headed browser and open the directory listing:

```powershell
.\zig-out\bin\lightpanda.exe browse --headed http://127.0.0.1:8000/
```

Use the listing page to open each export in the order below. Keep the same
headed session alive across all three pages unless the failure itself forces a
restart.

## Page Order And Proof Targets

### 1. Google Safety Centre

Open the Google Safety Centre export first.

Confirm:
- the page title resolves to the Google Safety Centre page instead of a blank,
  partial, or fallback title
- the cookie surface renders
- both `Agree` and `No thanks` can be activated
- one top navigation destination such as `Safer by design` or
  `Product protections` can be focused or opened

If this page fails before text entry or click behavior becomes meaningful,
classify it as a shared startup, rendering, or attached-page completeness
problem before assuming the issue is Google-specific.

## 2. Anthropic Application

Open the Anthropic application export second.

Confirm:
- the application form reaches an interactable settled state
- one select-style field such as `Gender` can be opened and dismissed cleanly
- scrolling keeps the form usable
- `Submit application` stays reachable after scrolling

If this page fails while Google passed, treat it as a stronger signal for
form-control, combobox, scroll, or focus-management regressions than for the
issue #3 Google-only Enter path.

## 3. UAP Page

Open the U.S. Department of War UAP export third.

Confirm:
- the title surface renders instead of collapsing into a blank or partial page
- the search input accepts focus and typed text
- one `record-row` entry opens the detail modal
- `Close` returns to the list view
- pagination advances without crashing the headed session

If this page fails while the first two pass, treat it as a likely signal for
modal, pagination, dense rendering, or broader DOM interaction drift instead of
for the narrower Google-form timing path.

## How To Classify Failures

### Only Google Safety Centre fails

Run the smallest matching follow-up first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
```

Use that ladder before reopening live Google or replaying the attached bundle
again.

### Google passes but Anthropic fails

Start with the smaller shared form checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
```

Then rerun the nearest input or rendering route from the validation matrix if
combobox, scrolling, or dense form layout still looks suspect.

### First two pass but UAP fails

Start with the closest shared surface checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\find\chrome-find-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\zoom\chrome-zoom-probe.ps1
```

Use those before blaming the entire attached-page route.

### All three fail early

Treat that as a shared headed startup, localhost serving, or attached-page
completeness problem first.

Check:
- the Python server is still alive on `127.0.0.1:8000`
- the saved pages and sidecars are all present in the served folder
- the headed browser can still open other bounded localhost probes such as
  `tmp-browser-smoke\wrapped-link\index.html`
- the attached-pages router still prints the expected bundle-first routes from
  `docs/HEADED_MODE_VALIDATION_MATRIX.md`

## Exit Signal

Count the localhost three-page pass as green only when:
- all three pages remain usable in one headed session
- no page needs a crash-recovery restart to continue
- focus, click, scroll, and at least one meaningful interaction on each page
  behave coherently
- the failure boundary, if any, is narrow enough to send back into one bounded
  probe family instead of broad manual replay
