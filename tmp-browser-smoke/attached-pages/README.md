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

The server also exposes each original file under `/raw/...`, which is useful if
the exported page references sibling assets with relative paths.

## Manifest fields

Each manifest entry now includes:

- `route`: the shortest stable route for the current bundle order
- `alias_route`: a readable companion route that keeps the same numeric slot
- `raw_path`: the original relative file path under the selected root

Use `route` in scripts when you want the smallest possible URL and
`alias_route` when you want a still-short path that is easier to recognize in
manual notes.

## Current compatibility target

For the current headed-mode validation loop, point `--root` at the directory
that contains the three attached HTML pages provided with the task. The catalog
page will surface compact short routes for each saved export so local Windows
and localhost testing can reuse the same bundle repeatedly.