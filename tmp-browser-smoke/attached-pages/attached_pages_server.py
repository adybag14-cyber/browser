#!/usr/bin/env python3

import argparse
import atexit
import json
import re
import shutil
import sys
import tempfile
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Iterable


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "page"


def extract_title(html_path: Path) -> str:
    try:
        content = html_path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return html_path.name
    match = re.search(r"<title[^>]*>(.*?)</title>", content, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        return html_path.name
    title = re.sub(r"\s+", " ", match.group(1)).strip()
    return title or html_path.name


def collect_html_inputs(inputs: Iterable[str]) -> list[Path]:
    pages: list[Path] = []
    for raw in inputs:
        path = Path(raw).expanduser().resolve()
        if path.is_dir():
            pages.extend(sorted(candidate for candidate in path.iterdir() if candidate.suffix.lower() in {".html", ".htm"}))
            continue
        if path.suffix.lower() not in {".html", ".htm"}:
            raise ValueError(f"unsupported input (expected .html/.htm file or directory): {path}")
        pages.append(path)
    if not pages:
        raise ValueError("no html inputs found")
    return pages


def stage_pages(html_paths: list[Path], staging_root: Path) -> list[dict[str, str]]:
    manifest: list[dict[str, str]] = []
    used_routes: set[str] = set()
    for index, html_path in enumerate(html_paths, start=1):
        base_slug = slugify(html_path.stem)
        route_slug = f"{index:02d}-{base_slug}"
        while route_slug in used_routes:
            route_slug = f"{route_slug}-copy"
        used_routes.add(route_slug)

        route_dir = staging_root / route_slug
        route_dir.mkdir(parents=True, exist_ok=True)
        staged_html = route_dir / "index.html"
        shutil.copy2(html_path, staged_html)

        sidecar_dir = html_path.with_name(f"{html_path.stem}_files")
        staged_sidecar = None
        if sidecar_dir.is_dir():
            staged_sidecar = route_dir / sidecar_dir.name
            shutil.copytree(sidecar_dir, staged_sidecar, dirs_exist_ok=True)

        manifest.append(
            {
                "title": extract_title(html_path),
                "source_path": str(html_path),
                "route": f"/{route_slug}/",
                "staged_html": str(staged_html),
                "sidecar_directory": str(sidecar_dir) if sidecar_dir.is_dir() else "",
                "staged_sidecar_directory": str(staged_sidecar) if staged_sidecar else "",
            }
        )
    return manifest


class AttachedPagesHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, directory: str, manifest: list[dict[str, str]], **kwargs):
        self._manifest = manifest
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self) -> None:
        if self.path == "/__pages.json":
            payload = json.dumps({"pages": self._manifest}, indent=2).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        return super().do_GET()

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage saved HTML pages and optional sibling *_files assets for localhost headed-browser validation."
    )
    parser.add_argument("inputs", nargs="+", help="One or more .html/.htm files, or directories containing them.")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host for the local validation server.")
    parser.add_argument("--port", type=int, default=8176, help="Bind port for the local validation server.")
    parser.add_argument(
        "--staging-root",
        help="Optional directory to reuse for staged content. Defaults to a temporary directory.",
    )
    args = parser.parse_args()

    try:
        html_paths = collect_html_inputs(args.inputs)
    except ValueError as err:
        parser.error(str(err))

    if args.staging_root:
        staging_root = Path(args.staging_root).expanduser().resolve()
        staging_root.mkdir(parents=True, exist_ok=True)
    else:
        staging_root = Path(tempfile.mkdtemp(prefix="lightpanda-attached-pages-"))
        atexit.register(shutil.rmtree, staging_root, ignore_errors=True)

    manifest = stage_pages(html_paths, staging_root)
    handler = partial(AttachedPagesHandler, directory=str(staging_root), manifest=manifest)
    server = ThreadingHTTPServer((args.host, args.port), handler)

    print(json.dumps({"staging_root": str(staging_root), "pages": manifest}, indent=2), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
