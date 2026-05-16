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
- `http://127.0.0.1:8235/pages/<generated-slug>` for a stable short route

The server also exposes each original file under `/raw/...`, which is useful if
the exported page references sibling assets with relative paths.

## Current compatibility target

For the current headed-mode validation loop, point `--root` at the directory
that contains the three attached HTML pages provided with the task. The catalog
page will surface short routes for each saved export so local Windows and
localhost testing can reuse the same bundle repeatedly.
