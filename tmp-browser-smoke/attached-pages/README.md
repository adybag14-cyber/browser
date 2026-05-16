# Attached Pages Smoke Harness

Use this helper when headed-mode work needs a stable localhost bundle for saved
HTML exports that do not already live inside the repository.

## Goal

Expose a directory of saved `.html` files, or one saved `.html` file with its
sibling assets, through short localhost routes so the headed browser can open
them without depending on long exported filenames.

## Usage

From the repo root:

```powershell
python .\tmp-browser-smoke\attached-pages\attached_pages_server.py --root C:\path\to\saved-html --port 8235
```

`--root` can point at either:

- a directory that contains one or more saved `.html` files
- a single saved `.html` file when you want to replay one export without
  first moving it into a dedicated folder

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

## Self-check

Run the focused harness regression locally with:

```powershell
python .\tmp-browser-smoke\attached-pages\test_attached_pages_server.py
```

The test covers the generated catalog, manifest route, short-route redirect,
named-route redirect and asset loading, `HEAD` handling, `/raw/...`
passthrough, the manifest-print CLI path, and the single-file root path against
a temporary two-page bundle.