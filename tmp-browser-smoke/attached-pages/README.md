Attached pages localhost harness

This helper stages saved `.html` snapshots and optional sibling `*_files`
directories behind a small localhost server so headed validation can exercise
real attached pages without hand-copying files into ad hoc probe folders.

Usage:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py \
  /path/to/page-one.html \
  /path/to/page-two.html \
  /path/to/page-three.html
```

The server prints a JSON manifest with:
- `staging_root`: the temporary directory holding the staged page copies
- `pages[*].route`: the localhost route for each staged page
- `pages[*].sidecar_directory`: the original sibling asset folder when one was found

The manifest is also exposed at `http://127.0.0.1:8176/__pages.json`.

Directory input is supported:

```bash
python tmp-browser-smoke/attached-pages/attached_pages_server.py /path/to/saved-pages-dir
```

That mode stages every top-level `.html` or `.htm` file in the directory.

Typical Windows headed workflow:

1. Start the helper with the saved attached pages.
2. Copy one `pages[*].route` value from the manifest.
3. Launch `lightpanda.exe browse http://127.0.0.1:8176/<route>` in headed mode.
4. Repeat against the other routes while collecting screenshots, traces, or probe notes.

Notes:
- Each page is staged under its own route directory as `index.html`.
- If a saved page has a sibling asset folder named like `<page>_files`, that folder is copied beside the staged `index.html` so relative asset references keep working.
- Use `--staging-root` when you want the staged output to persist after the server stops.
