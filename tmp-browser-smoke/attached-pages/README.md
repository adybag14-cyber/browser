# Attached Pages Smoke Harness

Use this helper when headed-mode work needs a stable localhost bundle for saved
HTML exports that do not already live inside the repository.

## Goal

Expose a directory of saved `.html` files through short localhost routes so the
headed browser can open them without depending on long exported filenames.

## Usage

From the repo root:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root C:\path\to\saved-html --port 8235
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

## Manifest fields

Each manifest entry now includes:

- `route`: the shortest stable route for the current bundle order
- `alias_route`: a readable companion route that keeps the same numeric slot
- `slug_route`: a descriptive route chosen from the page title and file path so replay notes can survive bundle reordering
- `raw_path`: the original relative file path under the selected root

Use `route` in scripts when you want the smallest possible URL, `alias_route`
when you want a still-short path that is easy to recognize in manual notes, and
`slug_route` when you want a descriptive path that remains useful even if the
bundle grows and page indexes shift.

## Self-check

Run the focused harness regression locally with:

```powershell
python .\tmp-browser-smoke\attached-pages\test_attached_pages_server.py
```

The test covers the generated catalog, manifest route, short-route redirect,
named-route redirect and asset loading, `HEAD` handling, `/raw/...`
passthrough, and the manifest-print CLI path against a temporary two-page
bundle.

## Current compatibility target

For the current headed-mode validation loop, point `--root` at the directory
that contains the three attached HTML pages provided with the task. The catalog
page will surface compact short routes for each saved export so local Windows
and localhost testing can reuse the same bundle repeatedly.