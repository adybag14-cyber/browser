import argparse
import html
import json
import re
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote


def slugify(name: str) -> str:
    lowered = name.lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return normalized or "page"


def extract_title(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return path.name
    match = re.search(r"<title[^>]*>(.*?)</title>", text, re.IGNORECASE | re.DOTALL)
    if not match:
        return path.name
    title = re.sub(r"\s+", " ", match.group(1)).strip()
    return title or path.name


def build_manifest(root: Path) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    used_routes: set[str] = set()
    html_files = sorted(path for path in root.rglob("*.html") if path.is_file())
    for index, path in enumerate(html_files, start=1):
        rel_path = path.relative_to(root).as_posix()
        route_slug = slugify(path.stem)
        route = f"/pages/{route_slug}"
        suffix = 2
        while route in used_routes:
            route = f"/pages/{route_slug}-{suffix}"
            suffix += 1
        used_routes.add(route)
        entries.append({
            "index": str(index),
            "route": route,
            "raw_path": f"/raw/{quote(rel_path)}",
            "file": rel_path,
            "title": extract_title(path),
        })
    return entries


def render_index(manifest: list[dict[str, str]]) -> bytes:
    rows = []
    for entry in manifest:
        rows.append(
            "<li>"
            f"<a href=\"{html.escape(entry['route'])}\">{html.escape(entry['title'])}</a>"
            f"<div><code>{html.escape(entry['file'])}</code></div>"
            f"<div><a href=\"{html.escape(entry['raw_path'])}\">raw file</a></div>"
            "</li>"
        )
    body = "\n".join(rows) if rows else "<li>No HTML files were found in the selected bundle.</li>"
    page = f"""<!doctype html>
<html lang=\"en\">
  <head>
    <meta charset=\"utf-8\">
    <title>Attached Pages Catalog</title>
    <style>
      body {{
        font-family: sans-serif;
        margin: 2rem auto;
        max-width: 56rem;
        line-height: 1.5;
        color: #202124;
      }}
      h1 {{
        margin-bottom: 0.5rem;
      }}
      p {{
        margin-top: 0;
      }}
      ul {{
        padding-left: 1.25rem;
      }}
      li {{
        margin: 0 0 1rem;
      }}
      code {{
        background: #f1f3f4;
        padding: 0.1rem 0.3rem;
      }}
    </style>
  </head>
  <body>
    <h1>Attached Pages Catalog</h1>
    <p>
      This server exposes stable short routes for a directory of saved HTML pages so
      headed-mode validation can target them without depending on long exported filenames.
    </p>
    <ul>
      {body}
    </ul>
  </body>
</html>
"""
    return page.encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve an attached HTML bundle for headed-mode smoke validation.")
    parser.add_argument("--root", required=True, help="Directory that contains the saved HTML files.")
    parser.add_argument("--bind", default="127.0.0.1", help="Address to bind. Defaults to 127.0.0.1.")
    parser.add_argument("--port", type=int, default=8235, help="TCP port to listen on. Defaults to 8235.")
    args = parser.parse_args()

    root = Path(args.root).expanduser().resolve()
    if not root.is_dir():
        raise SystemExit(f"bundle root does not exist: {root}")

    manifest = build_manifest(root)
    manifest_lookup = {entry["route"]: entry for entry in manifest}
    index_bytes = render_index(manifest)
    manifest_bytes = json.dumps(manifest, indent=2).encode("utf-8")

    class AttachedPagesHandler(SimpleHTTPRequestHandler):
        def __init__(self, *handler_args, **handler_kwargs):
            super().__init__(*handler_args, directory=str(root), **handler_kwargs)

        def end_headers(self):
            self.send_header("Cache-Control", "no-store")
            super().end_headers()

        def do_GET(self):
            if self.path == "/" or self.path == "/index.html":
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(index_bytes)))
                self.end_headers()
                self.wfile.write(index_bytes)
                return
            if self.path == "/manifest.json":
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(manifest_bytes)))
                self.end_headers()
                self.wfile.write(manifest_bytes)
                return
            if self.path in manifest_lookup:
                target = root / manifest_lookup[self.path]["file"]
                content = target.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
                return
            if self.path.startswith("/raw/"):
                self.path = self.path[len("/raw") :]
            return super().do_GET()

    class ReuseServer(ThreadingHTTPServer):
        allow_reuse_address = True

    server = ReuseServer((args.bind, args.port), partial(AttachedPagesHandler))
    print(f"Serving {len(manifest)} attached pages from {root} at http://{args.bind}:{args.port}/")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
