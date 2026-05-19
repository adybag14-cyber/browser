# Attached Pages Localhost Harness

This folder hosts the attached-page replay helpers used to stage saved `.html`
exports and optional sibling `*_files` directories behind a small localhost
catalog. The current preferred entrypoints are:

- `tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py`
- `scripts/windows/start_attached_pages_catalog.ps1`
- `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
- `scripts/windows/show_attached_pages_preflight_report.ps1`

Together they wrap fixture discovery, manifest printing, sidecar preflight
checks, broader asset audits, staged-route persistence, launch-readiness
summaries, and the lower-level server helper in one place.

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

Use the preflight report when you want one readiness summary before deciding
whether to restore missing bundles, restore missing assets, print the manifest,
or start the localhost catalog.

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_preflight_report.ps1
```

The preflight report prints:

- `ready_for_launch`
- the recommended next step
- the preferred Google-style routes when Google-style ranking is enabled
- direct sidecar and broader asset audit route URLs for the same pinned localhost catalog
- the selected fixture summary from the current attached-pages input set

Prefer the strongest Google-like fixture first in the same combined report:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --google-style
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_preflight_report.ps1 \
  -GoogleStyle
```

Keep going with a success exit code even when the current bundle is missing
sidecars or local assets:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --allow-missing-sidecars \
  --allow-missing-assets
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_preflight_report.ps1 \
  -AllowMissingSidecars \
  -AllowMissingAssets
```

Print the structured JSON form for automation:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --json
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_preflight_report.ps1 \
  -Json
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

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -RequireCompleteSidecars \
  -PrintManifest
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

Refuse to print a manifest or start the catalog when referenced local assets
are still missing:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --require-complete-assets \
  --print-manifest
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -RequireCompleteAssets \
  -PrintManifest
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

When both sidecars and referenced local assets must be complete before the
manifest or localhost server is trusted, keep both strict gates pinned on the
same launcher surface:

```bash
python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \
  --input /path/to/saved-pages-dir \
  --require-complete-sidecars \
  --require-complete-assets \
  --port 8235
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -RequireCompleteSidecars \
  -RequireCompleteAssets \
  -Port 8235
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
3. If incomplete bundles or local assets should stop the run, rerun the manifest or launch step with `--require-complete-sidecars`, `--require-complete-assets`, `-RequireCompleteSidecars`, or `-RequireCompleteAssets`.
4. Print the manifest or start the catalog launcher for the same pinned inputs.
5. Pin `--staging-root` or `-StagingRoot` when later replay steps need stable staged copies to survive source-file churn.
6. Open one of the printed localhost routes in headed mode.
7. Reuse the same pinned inputs while collecting screenshots, traces, or probe
   notes.

## Issue #3 Google-style follow-up

When the attached-pages harness is being used to narrow the headed Google input
issue, start with the same preflight surface but keep Google-style ranking
enabled so the strongest Google-like export stays first while the bundle is
checked.

```bash
python tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py \
  --google-style
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_pages_preflight_report.ps1 \
  -GoogleStyle
```

Then keep these companion surfaces nearby before widening back into the broader
attached-page ladders:

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/WINDOWS_FULL_USE.md`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1`

Use the preflight report first to confirm the selected bundle is intact, reuse
the same pinned inputs for sidecar and asset audits, and only then hand off to
the narrower issue-specific Google replay helper.

If you want the same launcher-backed sidecar-first ladder, strict asset gates,
and pinned proof follow-up reprinted from one guarded Windows surface before
dropping into the narrower Google helper, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath "C:\path\to\saved-pages-dir"
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot "C:\path\to\browser" -InputPath "C:\path\to\saved-pages-dir"
```

Use the guard first when the launcher companion itself or its note pointers may
have drifted. The companion helper keeps the wrapper-side sidecar audit, the
broader asset audit, the strict sidecar gate, the strict asset gate, the strict
bundle gate, the Google-style launcher variants, and the pinned proof checker
plus proof entrypoint together on one smaller surface while the replay is still
being narrowed.

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
- Use the launcher-level strict flags when a manifest or localhost run should
  fail fast on incomplete sidecar bundles or missing local assets instead of
  serving a known-bad export.
