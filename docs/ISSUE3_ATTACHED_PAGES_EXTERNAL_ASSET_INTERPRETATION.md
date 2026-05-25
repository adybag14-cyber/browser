# Issue #3 Attached Pages External Asset Interpretation

Use this note when the attached-pages localhost helpers report external assets and
you need to decide whether a replay problem belongs to an incomplete saved
bundle, to a page that still depends on the network, or to the headed browser
itself.

Keep this note next to:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `tmp-browser-smoke/attached-pages/README.md`
- `scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`

## Why this note exists

The attached-pages helpers already separate two different failure classes:

- missing sidecars or missing local assets inside the saved export bundle
- external URLs that the saved page still expects to fetch at replay time

Those signals should not be treated as the same thing.

A page with missing local assets is not yet a closed localhost replay bundle.
A page with external assets may still launch, but the replay is no longer a
pure saved-export signal because remote fonts, scripts, images, media, or other
resources can still influence the result.

## Current builder-attached bundle facts

The current builder-attached three-page compatibility bundle is:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

The focused attached-pages asset audit previously confirmed this bundle shape:

- Google Safety Centre: `7` external assets, `0` missing local assets
- Anthropic application: `2` external assets, `0` missing local assets
- U.S. Department of War UAP page: `94` external assets and `69` missing local assets

Treat those counts as route-selection guidance, not as browser verdicts.

## Practical interpretation rules

1. If sidecars are missing, stop before deeper browser diagnosis. The export
   bundle itself is incomplete.
2. If local assets are missing, treat the replay as bundle repair work first.
   A headed failure on that page is not yet clean evidence against the browser.
3. If local assets are complete but external assets remain, the replay is still
   useful, but classify it as network-backed. Use it to spot obvious headed
   regressions without overstating offline fidelity.
4. If a page has neither missing local assets nor external assets, treat it as
   the cleanest localhost-first compatibility signal.
5. Prefer cleaner pages earlier in the replay ladder so the first failure gives
   the narrowest possible blame surface.

## Recommended replay order for the current bundle

Use this order when the run is trying to make honest headed-mode progress from
the current three attached exports:

1. Google Safety Centre first. It keeps the strongest Google-like route while
   avoiding missing-local-asset noise.
2. Anthropic second. It is still network-backed, but the local bundle is closed,
   so form and interaction failures are easier to attribute than on the UAP page.
3. UAP last. Its current saved export still mixes missing local assets with a
   large external dependency set, so it is the noisiest replay signal.

## Commands to reopen the audit quickly

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<bundle-folder-or-html>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath '<bundle-folder-or-html>' -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<bundle-folder-or-html>' -PreferredInitialPage '<preferred-page>'
```

Use `-PreferredInitialPage` with the Google Safety Centre export when you want
that cleaner Google-shaped page to stay first while the rest of the three-page
bundle remains pinned.

## What to record after a replay

When a replay fails, record which of these states applied to the page that
failed first:

- missing sidecars
- missing local assets
- external assets only
- fully local bundle

That one line prevents future runs from re-reading a noisy attached-page result
as if it were a clean headed-browser regression.
