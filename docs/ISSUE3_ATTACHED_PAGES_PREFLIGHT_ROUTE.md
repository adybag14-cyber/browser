# Issue #3 Attached-Pages Preflight Route

Use this note when the next issue `#3` follow-up is already on the attached
localhost HTML lane and the run needs one compact Linux or scheduled-run route
to prove that the saved bundle is ready before reopening the Windows replay
helpers.

This route is intentionally smaller than the broader attached-page replay notes.
Its job is to answer one question first:

Is the current attached HTML bundle complete enough to trust for localhost
replay, or is the next failure still just missing sidecars or missing local
assets?

Companion files:

- `scripts/linux/check_issue3_attached_pages_preflight_route_surface.sh`
- `scripts/linux/show_issue3_attached_pages_preflight_route.sh`
- `tmp-browser-smoke/attached-pages/README.md`
- `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/windows/show_attached_pages_preflight_report.ps1`
- `scripts/windows/start_attached_pages_catalog.ps1`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/WINDOWS_FULL_USE.md`

## When To Use It

Use this route when any of these are true:

- a scheduled run is working from Linux or WSL and cannot yet reopen the
  Windows replay ladder
- the next step depends on the three attached HTML compatibility pages or a
  broader saved export bundle
- the run needs to classify missing sidecars or missing local assets before it
  treats the attached-page replay as a browser regression
- the broader attached-page helper chain is already known, and the run only
  needs the smallest preflight route back to a trustworthy manifest or strict
  localhost launch command

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_attached_pages_preflight_route_surface.sh
```

Run that first so missing route files, missing attached-pages helpers, or helper
surface drift fail before the preflight report is trusted.

## Compact Route

Print the route when the current run needs the commands back on one surface:

```bash
bash ./scripts/linux/show_issue3_attached_pages_preflight_route.sh
```

Use `--json` when another helper needs the route in structured form.

If the bundle is already pinned to explicit HTML files or folders:

```bash
bash ./scripts/linux/show_issue3_attached_pages_preflight_route.sh \
  --input /path/to/page-one.html \
  --input /path/to/saved-pages-dir
```

If the run wants the strongest Google-like page first:

```bash
bash ./scripts/linux/show_issue3_attached_pages_preflight_route.sh \
  --google-style \
  --preferred-initial-page "<Google Safety Centre export>"
```

## Preflight Order

Keep the route in this order:

1. surface check
2. preflight report
3. sidecar audit
4. broader asset audit
5. plain manifest print if the route still needs inspection
6. strict manifest or strict localhost launch once the bundle is complete

That keeps missing `_files` bundles visible before the run spends time on
broader asset drift, and it keeps missing local assets visible before the
Windows replay helper chain is blamed.

## Recommended Commands

Start with the compact readiness report:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --repo-root . \
  --google-style
```

When the route needs the stricter sidecar-first answer:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --audit-sidecars
```

After the sidecar bundle exists, widen to the broader asset audit:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --audit-assets
```

Once the bundle is clean enough to trust, keep the handoff back to Windows on a
strict manifest or strict launch:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --require-complete-sidecars \
  --require-complete-assets \
  --print-manifest
```

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --require-complete-sidecars \
  --require-complete-assets
```

## Handoff Back To Windows Replay

Once the strict manifest or strict launch command is clean, reopen the narrower
Windows helper chain:

- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_pages_preflight_report.ps1`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1`

Use this Linux route before those Windows helpers when the run still needs a
truthful answer about bundle completeness.

## Working Rules

- Do not blame the browser for attached-page replay until the preflight report
  has classified the current bundle.
- Run the sidecar audit before the broader asset audit when the export may be
  missing its sibling `_files` directory.
- Treat a clean strict manifest as the minimum handoff proof back to the
  narrower Windows replay route.
- Keep this note as the compact restore-free preflight route. Use the broader
  attached-page and Windows replay notes only after this route says the bundle
  is ready.
