import argparse
import html
import http.server
import json
import mimetypes
import socketserver
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote


@dataclass(frozen=True)
class CaptureSpec:
    slug: str
    html_name: str
    title: str
    focus: str


CAPTURES = (
    CaptureSpec(
        slug="google-safety-centre",
        html_name="Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
        title="Google Safety Centre",
        focus="Large single-file marketing page with heavy inline assets and long-scroll rendering.",
    ),
    CaptureSpec(
        slug="anthropic-job-application",
        html_name="Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
        title="Anthropic Job Application",
        focus="Form-heavy page with combobox-style text inputs, keyboard focus, and submission-style controls.",
    ),
    CaptureSpec(
        slug="uap-war-department",
        html_name="Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
        title="Department of War UAP Page",
        focus="Large scripted page with button grids, modal-style controls, table-like records, and optional sidecar assets.",
    ),
)


def _safe_relative_path(raw_path: str) -> Path | None:
    candidate = Path(unquote(raw_path.lstrip("/")))
    if any(part in ("", ".", "..") for part in candidate.parts):
        return None
    return candidate


class AttachedPagesServer(http.server.BaseHTTPRequestHandler):
    source_dir: Path
    captures_by_slug: dict[str, CaptureSpec]

    def do_GET(self) -> None:
        self._handle_request(send_body=True)

    def do_HEAD(self) -> None:
        self._handle_request(send_body=False)

    def _handle_request(self, send_body: bool) -> None:
        if self.path == "/ping":
            self._send_bytes(200, b"ok", "text/plain; charset=utf-8", send_body=send_body)
            return

        if self.path == "/manifest.json":
            body = json.dumps(self._build_manifest(), indent=2).encode("utf-8")
            self._send_bytes(200, body, "application/json; charset=utf-8", send_body=send_body)
            return

        if self.path == "/" or self.path == "/index.html":
            self._send_bytes(200, self._build_index_html(), "text/html; charset=utf-8", send_body=send_body)
            return

        prefix = "/pages/"
        if not self.path.startswith(prefix):
            self.send_error(404, "Unknown route")
            return

        tail = self.path[len(prefix):]
        slug, sep, remainder = tail.partition("/")
        capture = self.captures_by_slug.get(slug)
        if capture is None:
            self.send_error(404, "Unknown page slug")
            return

        if not sep or remainder in ("", "index.html"):
            self._serve_file(self.source_dir / capture.html_name, send_body=send_body)
            return

        rel = _safe_relative_path(remainder)
        if rel is None:
            self.send_error(400, "Invalid relative path")
            return

        self._serve_file(self.source_dir / rel, send_body=send_body)

    def _build_manifest(self) -> dict:
        entries = []
        for capture in CAPTURES:
            html_path = self.source_dir / capture.html_name
            sidecar_dir = self.source_dir / f"{Path(capture.html_name).stem}_files"
            entries.append(
                {
                    "slug": capture.slug,
                    "title": capture.title,
                    "route": f"/pages/{capture.slug}/index.html",
                    "html_name": capture.html_name,
                    "html_exists": html_path.exists(),
                    "sidecar_dir": sidecar_dir.name,
                    "sidecar_exists": sidecar_dir.is_dir(),
                    "focus": capture.focus,
                }
            )
        return {
            "source_dir": str(self.source_dir),
            "captures": entries,
        }

    def _build_index_html(self) -> bytes:
        rows = []
        for capture in self._build_manifest()["captures"]:
            status = "ready" if capture["html_exists"] else "missing"
            assets = "present" if capture["sidecar_exists"] else "missing"
            rows.append(
                "<li>"
                f"<a href=\"{html.escape(capture['route'])}\">{html.escape(capture['title'])}</a>"
                f" <strong>[html:{status} assets:{assets}]</strong>"
                f"<div>{html.escape(capture['focus'])}</div>"
                "</li>"
            )
        body = (
            "<!doctype html><html><head><meta charset=\"utf-8\">"
            "<title>Attached Page Validation Index</title>"
            "</head><body style=\"font:16px sans-serif;padding:24px;line-height:1.5;\">"
            "<h1>Attached Page Validation Index</h1>"
            "<p>Serve the saved attached HTML pages through stable localhost routes for headed-mode validation.</p>"
            f"<p>Source directory: <code>{html.escape(str(self.source_dir))}</code></p>"
            "<ul>"
            + "".join(rows)
            + "</ul>"
            "<p><a href=\"/manifest.json\">manifest.json</a></p>"
            "</body></html>"
        )
        return body.encode("utf-8")

    def _serve_file(self, path: Path, send_body: bool) -> None:
        if not path.exists() or not path.is_file():
            self.send_error(404, f"Missing file: {path.name}")
            return
        content_type, _ = mimetypes.guess_type(path.name)
        if content_type is None:
            content_type = "application/octet-stream"
        self._send_bytes(200, path.read_bytes(), content_type, send_body=send_body)

    def _send_bytes(self, code: int, body: bytes, content_type: str, send_body: bool) -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if send_body:
            self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        return


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve saved attached HTML captures through stable localhost routes.")
    parser.add_argument("--source-dir", required=True, help="Directory containing the saved attached HTML files.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8124)
    args = parser.parse_args()

    source_dir = Path(args.source_dir).resolve()
    if not source_dir.is_dir():
        raise SystemExit(f"source directory does not exist: {source_dir}")

    handler = type(
        "ConfiguredAttachedPagesServer",
        (AttachedPagesServer,),
        {
            "source_dir": source_dir,
            "captures_by_slug": {capture.slug: capture for capture in CAPTURES},
        },
    )

    with ReusableTCPServer((args.host, args.port), handler) as server:
        print(f"Serving attached pages from {source_dir} on http://{args.host}:{args.port}")
        server.serve_forever()


if __name__ == "__main__":
    main()
