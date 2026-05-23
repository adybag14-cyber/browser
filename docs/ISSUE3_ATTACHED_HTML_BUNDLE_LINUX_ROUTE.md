# Issue #3 Attached HTML Bundle Linux Route

Use this note when the next issue `#3` replay should stay pinned to the current
three-page attached HTML compatibility bundle from `agent_files/`, but the run
is happening from a Linux or WSL checkout instead of the Windows wrapper lane.

This route complements:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md`
- `tmp-browser-smoke/attached-pages/README.md`
- `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/linux/show_issue3_attached_html_bundle_linux_route.sh`

## Goal

Give Linux or WSL runs one compact branch-local helper surface for:

- pinning the replay to the current three attached HTML exports
- keeping the Google Safety Centre export first across the replay bundle
- running the combined preflight report before the deeper sidecar and asset
  audits
- printing the strict manifest route that refuses to continue when sidecars or
  local assets are missing
- starting the localhost catalog with the same pinned inputs once the bundle is
  clean enough to blame the browser instead of the export

## Current pinned bundle

The compatibility bundle is the three attached HTML exports currently expected
under `agent_files/` beside the repo workspace:

- `Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

Prefer the Google Safety Centre export as the first page so the same
Google-shaped replay stays at the front of the bundle before the route widens
back into the broader attached-page ladders.

## Run the helper

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_attached_html_bundle_linux_route.sh
```

If the attached pages live somewhere other than the default `../agent_files`
directory beside the repo workspace, override the input root explicitly:

```bash
bash ./scripts/linux/show_issue3_attached_html_bundle_linux_route.sh \
  --repo-root /path/to/browser \
  --input-root /path/to/attached-html-bundle
```

Pass `--browser-exe` when you want the helper to also print the final headed
browser launch command after the strict localhost route:

```bash
bash ./scripts/linux/show_issue3_attached_html_bundle_linux_route.sh \
  --browser-exe /path/to/zig-out/bin/lightpanda
```

Use `--json` when another helper or automation layer needs the command set as
structured output.

## Suggested route

The helper keeps the route short and ordered:

1. Run `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
   first so the selected bundle, recommended next step, and localhost routes
   stay on one compact surface.
2. Run the sidecar audit before the broader asset audit so missing sibling
   `*_files` directories are separated from deeper asset drift.
3. Run the strict manifest command before launch when the replay should stop on
   missing sidecars or missing local assets.
4. Start the strict localhost catalog only after the pinned bundle is intact.
5. Walk the bundle in this order once the catalog is up:
   Google Safety Centre, Anthropic application, then the U.S. Department of
   War page.

## Manual form

If you want the same route without the helper, keep these commands pinned to the
exact three attached pages:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --repo-root . \
  --google-style \
  --preferred-initial-page 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' \
  --input ../agent_files/'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --preferred-initial-page 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' \
  --input ../agent_files/'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html' \
  --audit-sidecars

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --preferred-initial-page 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' \
  --input ../agent_files/'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html' \
  --audit-assets

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --preferred-initial-page 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' \
  --input ../agent_files/'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html' \
  --require-complete-sidecars \
  --require-complete-assets \
  --print-manifest

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --preferred-initial-page 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html' \
  --input ../agent_files/'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html' \
  --input ../agent_files/'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html' \
  --require-complete-sidecars \
  --require-complete-assets \
  --bind 127.0.0.1 \
  --port 8235
```

## Working rules

- Treat a missing pinned bundle file as an export-bundle problem first, not as a
  browser regression.
- Run the sidecar audit before the broader asset audit every time.
- Keep the Google Safety Centre export first unless a narrower replay note says
  otherwise.
- Reuse the same pinned bundle paths through preflight, audits, manifest
  printing, and localhost launch so the signal stays honest.
