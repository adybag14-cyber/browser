# Attached Pages Smoke Harness

Use this helper when headed-mode work needs a stable localhost bundle for saved
HTML exports that do not already live inside the repository.

## Goal

Expose a directory of saved `.html` files, one saved `.html` file with its
sibling assets, or an explicit list of saved `.html` files through short
localhost routes so the headed browser can open them without depending on long
exported filenames.

## Usage

From the repo root:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root C:\path\to\saved-html --port 8235
```

`--root` can point at either:

- a directory that contains one or more saved `.html` files
- a single saved `.html` file when you want to replay one export without
  first moving it into a dedicated folder

If you want the manifest to stay pinned to a specific attached-page set even
when the surrounding directory contains extra HTML exports, pass the exact file
list instead:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --input C:\path\to\Google Safety Centre.html `
  --input C:\path\to\Anthropic Application.html `
  --input C:\path\to\UAP Encounters.html `
  --port 8235
```

Then open one of these URLs in the headed browser:

- `http://127.0.0.1:8235/` for the generated catalog
- `http://127.0.0.1:8235/manifest.json` for the route list
- `http://127.0.0.1:8235/pages/1` for the shortest stable route to the first page in the manifest
- `http://127.0.0.1:8235/pages/1-<short-title-slug>` for the readable alias route when you want a descriptive path in logs or manual replay notes
- `http://127.0.0.1:8235/named/<short-title-slug>` for a descriptive route that stays usable even if the bundle order changes

The short `pages/...` routes and the named `named/...` routes redirect into an
asset-safe directory form such as `/pages/1/` or `/named/google-search/`, so
relative CSS, images, scripts, and other sibling assets keep loading from the
exported bundle instead of resolving against the synthetic route root. The
server still exposes each original file under `/raw/...`, which is useful when
you want the exact original path layout during manual debugging.

If you only need the generated short routes before starting a browser session,
print the manifest JSON and exit without binding a port:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root C:\path\to\saved-html --print-manifest
```

That same manifest-print path also works with repeated `--input` arguments when
you want to prove the exact pinned file list before starting the localhost
catalog server.

## Issue #3 Pinned Bundle

For the current headed Google follow-up work, you can pin the known three-page
compatibility bundle directly from `agent_files/` so the generated short routes
stay locked to the same saved exports even if that folder later gains more HTML
files:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --input ".\agent_files\Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html" `
  --input ".\agent_files\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html" `
  --input ".\agent_files\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html" `
  --print-manifest
```

Once the manifest looks correct, start the localhost catalog on the same pinned
file list:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --input ".\agent_files\Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html" `
  --input ".\agent_files\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html" `
  --input ".\agent_files\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html" `
  --port 8235
```

That gives the current issue `#3` replay work one stable localhost catalog with
short routes such as:

- `http://127.0.0.1:8235/` for the generated three-page catalog
- `http://127.0.0.1:8235/pages/1` for the first pinned page
- `http://127.0.0.1:8235/pages/2` for the second pinned page
- `http://127.0.0.1:8235/pages/3` for the third pinned page

Use this pinned-file form when you want the quick manual replay surface before
running the heavier attached-page PowerShell helpers or when you want the exact
same three pages available through short routes while you debug a headed-mode
compatibility regression.

## Asset Audit

Before treating a localhost replay failure as a headed-runtime bug, you can ask
the helper to recursively inspect local asset references across the selected
bundle.

From a bundle root:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --root C:\path\to\saved-html `
  --audit-assets
```

Against the pinned issue `#3` file list:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --input ".\agent_files\Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html" `
  --input ".\agent_files\Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html" `
  --input ".\agent_files\Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html" `
  --audit-assets
```

The audit walks each selected HTML file, follows local CSS `@import` chains,
module-script imports, and common local asset references, then reports missing
sidecars per fixture. It exits with a nonzero status when anything is missing,
which makes it a good first gate for repeatable localhost validation.

If you still want a best-effort replay after seeing the missing-asset report,
add `--allow-missing-assets` so the helper prints the audit summary but exits
successfully:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py `
  --root C:\path\to\saved-html `
  --audit-assets `
  --allow-missing-assets
```

Use this path when the bundle is already known to be incomplete and you want to
keep that fact visible in logs without blocking the rest of the replay flow.

## Self-check

Run the focused harness regression locally with:

```powershell
python .\tmp-browser-smoke\attached-pages\test_attached_pages_server.py
```

The test covers the generated catalog, manifest route, short-route redirect,
named-route redirect and asset loading, `HEAD` handling, `/raw/...`
passthrough, the manifest-print CLI path, the single-file root path, the
explicit file-list path that pins the manifest to selected saved exports, and
the asset-audit CLI behavior.