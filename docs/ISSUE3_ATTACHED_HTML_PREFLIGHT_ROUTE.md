# Issue #3 Attached HTML Preflight Route

Use this note when the next issue `#3` replay should stay on the builder-attached
HTML compatibility bundle long enough to prove the export itself is sound before
Windows headed follow-up widens back out again.

This route exists because the current branch already has strong cross-platform
Python helpers for the attached-pages localhost harness, but many of the issue
`#3` attached-page surfaces around them are still Windows-first. Scheduled Linux
or WSL runs need one smaller route that can truthfully summarize the current
attached bundle, audit sidecars, audit broader local assets, and print the
strict manifest or localhost launch commands without relying on PowerShell.

Keep these nearby:

- `scripts/linux/check_issue3_attached_html_preflight_route_surface.sh`
- `scripts/linux/show_issue3_attached_html_preflight_route.sh`
- `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `tmp-browser-smoke/attached-pages/README.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/WINDOWS_FULL_USE.md`

## When To Use It

Use this route when all of these are true:

- the current run is still in the attached-page compatibility lane for issue `#3`
- the current environment is Linux, WSL, or another shell-first runtime where
  the Python helpers are easier to use directly than the Windows wrappers
- the next step should prove whether the selected attached bundle is complete
  enough to blame the browser honestly before headed replay continues

## What It Covers

This route keeps one compact Linux surface for:

- a fail-fast surface check for the branch-local docs and attached-pages helpers
- the cross-platform attached-pages preflight report
- the sibling `_files` sidecar audit
- the broader local asset-closure audit
- a normal manifest route and localhost catalog launch route
- strict manifest and launch routes that refuse incomplete bundles

## Practical Order

Use this order when the current replay should stay on the attached bundle first.

1. Fail fast on missing branch-local helper files:

```bash
bash ./scripts/linux/check_issue3_attached_html_preflight_route_surface.sh
```

2. Print the compact route surface:

```bash
bash ./scripts/linux/show_issue3_attached_html_preflight_route.sh
```

3. Run the cross-platform preflight report first:

```bash
python ./tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --repo-root . \
  --google-style \
  --bind 127.0.0.1 \
  --port 8235
```

4. Run the sidecar audit before the broader asset audit:

```bash
python ./tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --bind 127.0.0.1 \
  --port 8235 \
  --audit-sidecars
```

```bash
python ./tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --bind 127.0.0.1 \
  --port 8235 \
  --audit-assets
```

5. If the current replay should stop on incomplete bundles, run the strict
manifest before the localhost server is trusted:

```bash
python ./tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --bind 127.0.0.1 \
  --port 8235 \
  --require-complete-sidecars \
  --require-complete-assets \
  --print-manifest
```

6. Only after the preflight route is honest, start the localhost catalog:

```bash
python ./tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root . \
  --google-style \
  --bind 127.0.0.1 \
  --port 8235
```

## Pinned Compatibility Bundle

The current builder-attached compatibility bundle for this route is the same
three saved pages already present beside the workspace helper surface:

- `Control your online safety and privacy - Google Safety Centre (09_05_2026 21:23:40).html`
- `Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21:25:29).html`
- `Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html`

When the replay should keep one Google-shaped page first inside that bundle,
pass `--preferred-initial-page` to the Linux route helper or directly to the
Python preflight and catalog commands.

## Healthy Signals

Treat the attached bundle as ready for headed replay only when all of these are
true:

- the surface check passes
- the preflight report marks the bundle as ready for launch
- the sidecar audit finds no missing sibling `_files` directories
- the broader asset audit finds no missing local assets that would change the
  replay signal materially
- the strict manifest or strict localhost launch route succeeds for the same
  pinned inputs

## If The Route Fails

If the preflight or strict manifest route fails:

- treat that as an attached export or bundle-integrity problem first
- do not blame the headed browser yet
- keep the replay narrow on sidecar repair or asset restoration until the same
  pinned inputs pass again
- use `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` plus
  `docs/WINDOWS_FULL_USE.md` only after the Linux-side bundle signal is honest

## Working Rule

For issue `#3` attached-page replay from Linux or WSL, the first meaningful
question is not whether the headed browser launches. It is whether the current
attached bundle is complete enough to make that launch result trustworthy.

Run the Linux attached-html preflight surface first, then widen back into the
Windows-first helper family only after the bundle itself stops being the likely
source of drift.
