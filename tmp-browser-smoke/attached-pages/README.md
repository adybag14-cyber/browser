# Attached Pages Localhost Harness

This folder hosts the attached-page replay helpers used to stage saved `.html`
exports and optional sibling `*_files` directories behind a small localhost
catalog. The current preferred entrypoint is `start_attached_pages_catalog.py`.
It wraps fixture discovery, manifest printing, sidecar preflight checks, asset
audits, and the lower-level server helper in one place.

## Preferred launcher

Use the catalog launcher when you want the helper to discover attached pages for
you or when you want one command surface for both preflight checks and server
startup.

Auto-discover saved pages from repo or workspace `agent_files` / `user_files`:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
```

Pin the catalog to explicit files or folders:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/page-one.html \
  --input /path/to/saved-pages-dir
```

Prefer the strongest Google-like fixture first and print the generated manifest
instead of starting the server:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --google-style \
  --print-manifest
```

If the repo is not the default checkout, preserve that context directly:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root /path/to/browser \
  --input /path/to/saved-pages-dir
```

## Sidecar-first preflight

Before treating a replay failure as a browser regression, first rule out the
simpler case where the saved export is missing its whole sibling `*_files`
bundle.

Text report:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars
```

JSON report for automation:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars \
  --audit-sidecars-json
```

Keep going even when sidecars are missing:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars \
  --allow-missing-sidecars
```

## Asset audit

After the sidecar bundle exists, use the broader asset audit when you need to
see which referenced local files are still missing inside an otherwise present
export.

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-assets
```

JSON output is also available:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-assets \
  --audit-assets-json
```

## Start the localhost catalog

Once the sidecar or asset preflight looks good, start the replay catalog:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/page-one.html \
  --input /path/to/page-two.html \
  --input /path/to/page-three.html
```

The launcher prints:
- selected fixture paths
- the bound catalog URL
- warning text when sidecars or local assets are missing
- the available routes: `/`, `/manifest.json`, `/audit.json`, `/audit.txt`,
  `/pages/<n>`, `/named/<slug>`, and `/raw/...`

## Typical headed workflow

1. Run `--audit-sidecars` first for the current saved-page set.
2. Run `--audit-assets` only after the sidecar bundle exists.
3. Start the catalog launcher for the same pinned inputs.
4. Open one of the printed localhost routes in headed mode.
5. Reuse the same pinned inputs while collecting screenshots, traces, or probe
   notes.

## Lower-level helpers

Use these when you intentionally want the narrower building blocks instead of
`start_attached_pages_catalog.py`.

Run the sidecar audit directly:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py \
  --root /path/to/saved-pages-dir
```

Run the server directly:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  /path/to/page-one.html \
  /path/to/page-two.html
```

The direct server helper still supports directory input:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  /path/to/saved-pages-dir
```

## Notes

- Each staged page is served from its own route directory as `index.html`.
- If a saved page has a sibling asset folder named like `<page>_files`, that
  folder is copied beside the staged `index.html` so relative asset references
  keep working.
- Use `attached_pages_sidecar_audit.py` when you only need the sibling-bundle
  answer.
- Use `attached_pages_server.py` when you already know the exact page list and
  do not need discovery, manifest ranking, or preflight helpers.
- Use `--staging-root` on `attached_pages_server.py` when you want staged output
  to persist after the server stops.
