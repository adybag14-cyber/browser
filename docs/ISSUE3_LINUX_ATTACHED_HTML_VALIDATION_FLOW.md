# Issue #3 Linux Attached HTML Validation Flow

Use this note when the next issue `#3` replay should preflight the saved HTML
bundle on Linux before the route hands back into the Windows headed helpers.

The matching Linux companion commands are:

```bash
bash scripts/linux/check_google_issue3_attached_pages_launcher_companion_validation_surface.sh
bash scripts/linux/show_google_issue3_attached_pages_launcher_companion.sh \
  --repo-root /path/to/browser-repo \
  --input-path /path/to/attached-html-or-folder \
  --preferred-initial-page "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html"
```

Use the checker first when the Linux note, the cross-platform launcher, or the
Windows replay handoff may have drifted. Use the helper second when you want one
compact Linux-side surface that keeps the preflight report, sidecar audit,
broader asset audit, strict manifest gates, and Windows replay handoff together.

## Current compatibility bundle

The current scheduled-run compatibility bundle is the three attached HTML
exports currently present in `agent_files/`:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer `Control your online safety and privacy – Google Safety Centre
(09_05_2026 21：23：40).html` as the first page when the replay should keep one
Google-like page first while the bundle still stays pinned end to end.

## Linux-side route

Use this order on purpose:

1. `attached_pages_preflight_report.py`

Use the preflight report first when the next run needs one compact readiness
summary before narrower route selection.

2. `start_attached_pages_catalog.py --google-style --audit-sidecars`

Use the sidecar audit next so missing sibling `_files` bundles fail before the
broader local asset crawl.

3. `start_attached_pages_catalog.py --google-style --audit-assets`

Use the asset audit after the sidecar bundle exists so missing local CSS,
script, font, or image files stay visible before the browser is blamed.

4. `start_attached_pages_catalog.py --google-style --require-complete-sidecars --require-complete-assets --print-manifest`

Use the strict manifest route when the bundle must be fully closed before the
Windows replay route is trusted.

5. `show_google_issue3_windows_replay_attached_html_quickstart.ps1` or `show_google_attached_html_validation_flow.ps1`

Use one of the Windows helpers only after the Linux-side bundle preflight is
green. The Linux companion is for honest attached-bundle preparation, not for
runtime proof that non-Windows headed fallback is sufficient for issue `#3`.

## Companion surfaces

Keep these nearby when the route needs more context:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `tmp-browser-smoke/attached-pages/README.md`
- `scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `scripts/windows/show_google_attached_html_validation_flow.ps1`

## Minimal example

```bash
bash scripts/linux/check_google_issue3_attached_pages_launcher_companion_validation_surface.sh
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --repo-root /path/to/browser-repo \
  --input /path/to/attached-html-or-folder \
  --google-style
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root /path/to/browser-repo \
  --input /path/to/attached-html-or-folder \
  --google-style \
  --audit-sidecars
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root /path/to/browser-repo \
  --input /path/to/attached-html-or-folder \
  --google-style \
  --audit-assets
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root /path/to/browser-repo \
  --input /path/to/attached-html-or-folder \
  --google-style \
  --require-complete-sidecars \
  --require-complete-assets \
  --print-manifest
```

If the strict manifest route fails, treat that as an export-bundle problem
first. If it succeeds, reopen the Windows replay quickstart or the dedicated
Google attached HTML flow with the same pinned inputs.
