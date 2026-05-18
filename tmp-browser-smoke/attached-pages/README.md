# Attached Pages Localhost Harness

This folder hosts the attached-page replay helpers used to stage saved `.html`
exports and optional sibling `*_files` directories behind a small localhost
catalog. The current preferred entrypoints are:

- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/windows/start_attached_pages_catalog.ps1`

Together they wrap fixture discovery, manifest printing, sidecar preflight
checks, broader asset audits, staged-route persistence, and the lower-level
server helper in one place.

## Preferred launchers

Use the catalog launchers when you want one command surface for both preflight
checks and localhost server startup.

Auto-discover saved pages from repo or workspace `agent_files` / `user_files`:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
```

On Windows, the matching wrapper keeps the same flow available from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1
```

Pin the catalog to explicit files or folders:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/page-one.html \
  --input /path/to/saved-pages-dir
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\page-one.html","C:\path\to\saved-pages-dir"
```

Prefer the strongest Google-like fixture first and print the generated manifest
instead of starting the server:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --google-style \
  --print-manifest
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -GoogleStyle \
  -PrintManifest
```

If the repo is not the default checkout, preserve that context directly:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --repo-root /path/to/browser \
  --input /path/to/saved-pages-dir
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -RepoRoot "C:\path\to\browser" \
  -InputPath "C:\path\to\saved-pages-dir"
```

When you want staged route copies to persist in a known directory while the
catalog is running, pass the staging root through the same launcher surface:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --staging-root /path/to/staged-route-copies
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -StagingRoot "C:\path\to\staged-route-copies"
```

Use this when later probes or manual headed replay need the staged route copies
to stay stable even if the original exported HTML or sibling `*_files` bundle
changes underneath the running localhost server.

## Sidecar-first preflight

Before treating a replay failure as a browser regression, first rule out the
simpler case where the saved export is missing its whole sibling `*_files`
bundle. The intended order is sidecars first, broader asset audit second,
manifest or server startup last.

Text report:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditSidecars
```

JSON report for automation:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars \
  --audit-sidecars-json
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditSidecars \
  -AuditSidecarsJson
```

Keep going even when sidecars are missing:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-sidecars \
  --allow-missing-sidecars
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditSidecars \
  -AllowMissingSidecars
```

Refuse to print a manifest or start the catalog when sidecars are missing:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --require-complete-sidecars \
  --print-manifest
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

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditAssets
```

JSON output is also available:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --audit-assets \
  --audit-assets-json
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditAssets \
  -AuditAssetsJson
```

## Start the localhost catalog

Once the sidecar or asset preflight looks good, start the replay catalog:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/page-one.html \
  --input /path/to/page-two.html \
  --input /path/to/page-three.html
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\page-one.html","C:\path\to\page-two.html","C:\path\to\page-three.html"
```

For an issue `#3` style replay where you want the strongest Google-like page
first, keep the same sidecar-first order:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py --google-style --audit-sidecars
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py --google-style --audit-assets
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py --google-style --print-manifest
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py --google-style --port 8235
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditAssets
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -PrintManifest
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -Port 8235
```

The launchers print:

- selected fixture paths
- the bound catalog URL
- warning text when sidecars or local assets are missing
- the requested staging root and the active staged-route copy directory when one is pinned
- the available routes: `/`, `/manifest.json`, `/audit.json`, `/audit.txt`,
  `/pages/<n>`, `/named/<slug>`, and `/raw/...`

## Typical headed workflow

1. Run the sidecar audit first for the current saved-page set.
2. Run the broader asset audit only after the sidecar bundle exists.
3. Print the manifest or start the catalog launcher for the same pinned inputs.
4. Pin `--staging-root` or `-StagingRoot` when later replay steps need stable staged copies to survive source-file churn.
5. Open one of the printed localhost routes in headed mode.
6. Reuse the same pinned inputs while collecting screenshots, traces, or probe
   notes.

## Lower-level helpers

Use these when you intentionally want the narrower building blocks instead of
`start_attached_pages_catalog.py` or `start_attached_pages_catalog.ps1`.

Run the sidecar audit directly:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py \
  --root /path/to/saved-pages-dir
```

Run the server directly:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  --input /path/to/page-one.html \
  --input /path/to/page-two.html
```

The direct server helper still supports directory input:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  --root /path/to/saved-pages-dir
```

Keep the same sidecar-first order when you bypass the wrappers:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py \
  --root /path/to/saved-pages-dir
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  --root /path/to/saved-pages-dir \
  --audit-assets
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  --root /path/to/saved-pages-dir \
  --print-manifest
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  --root /path/to/saved-pages-dir \
  --port 8235
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
