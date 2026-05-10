#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import json
import re
from dataclasses import asdict, dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Dict


TITLE_RE = re.compile(r"<title[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)
SPACE_RE = re.compile(r"\s+")
SLUG_RE = re.compile(r"[^a-z0-9]+")


@dataclass
class SavedPage:
    slug: str
    source_name: str
    title: str
    url_path: str


def extract_title(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    match = TITLE_RE.search(text)
    if not match:
        return path.stem
    title = html.unescape(match.group(1))
    title = SPACE_RE.sub(" ", title).strip()
    return title or path.stem


def slugify(name: str) -> str:
    slug = SLUG_RE.sub("-", name.lower()).strip("-")
    return slug or "page"


def build_manifest(root: Path) -> Dict[str, SavedPage]:
    pages: Dict[str, SavedPage] = {}
    for path in sorted(root.glob("*.html")):
        slug_base = slugify(path.stem)
        slug = slug_base
        suffix = 2
        while slug in pages:
            slug = f"{slug_base}-{suffix}"
            suffix += 1
        pages[slug] = SavedPage(
            slug=slug,
            source_name=path.name,
            title=extract_title(path),
            url_path=f"/p/{slug}",
        )
    return pages


class SavedPagesHandler(BaseHTTPRequestHandler):
    pages_root: Path
    manifest: Dict[str, SavedPage]

    def _write_json(self, payload: object, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _write_text(self, text: str, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _write_html_file(self, path: Path) -> None:
        body = path.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _write_html_file_content(self, text: str) -> None:
        body = text.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/healthz":
            self._write_text("ok\n")
            return

        if self.path == "/manifest.json":
            payload = {
                "pages": [asdict(page) for page in self.manifest.values()],
                "pages_root": str(self.pages_root),
            }
            self._write_json(payload)
            return

        if self.path == "/":
            rows = [
                "<!doctype html><meta charset='utf-8'><title>Saved Pages</title>",
                "<h1>Saved Pages</h1>",
                "<ul>",
            ]
            for page in self.manifest.values():
                rows.append(
                    f"<li><a href='{page.url_path}'>{html.escape(page.title)}</a>"
                    f" <small>{html.escape(page.source_name)}</small></li>"
                )
            rows.append("</ul>")
            self._write_html_file_content("\n".join(rows))
            return

        if self.path.startswith("/p/"):
            slug = self.path[len("/p/") :]
            page = self.manifest.get(slug)
            if page is None:
                self._write_text("page not found\n", HTTPStatus.NOT_FOUND)
                return
            self._write_html_file(self.pages_root / page.source_name)
            return

        self._write_text("not found\n", HTTPStatus.NOT_FOUND)

    def log_message(self, format: str, *args: object) -> None:
        return


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve saved HTML pages with a stable manifest.")
    parser.add_argument("pages_root", help="Directory containing saved .html pages")
    parser.add_argument("port", type=int, help="Port to bind on 127.0.0.1")
    args = parser.parse_args()

    pages_root = Path(args.pages_root).resolve()
    if not pages_root.is_dir():
        raise SystemExit(f"pages root does not exist: {pages_root}")

    manifest = build_manifest(pages_root)
    if not manifest:
        raise SystemExit(f"no .html files found in {pages_root}")

    handler = type(
        "BoundSavedPagesHandler",
        (SavedPagesHandler,),
        {
            "pages_root": pages_root,
            "manifest": manifest,
        },
    )
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(f"serving {len(manifest)} saved pages from {pages_root} on 127.0.0.1:{args.port}", flush=True)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
