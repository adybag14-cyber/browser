import http.server
import os
import pathlib
import socketserver
import sys
import urllib.parse


REPO_MARKER = "build.zig"
FIXTURE_RELATIVE_PATH = pathlib.Path("src/browser/tests/page/google_home_title_probe.html")


def resolve_repo_root(start_path: pathlib.Path) -> pathlib.Path:
    if "LIGHTPANDA_REPO_ROOT" in os.environ and os.environ["LIGHTPANDA_REPO_ROOT"].strip():
        return pathlib.Path(os.environ["LIGHTPANDA_REPO_ROOT"]).resolve()

    cursor = start_path.resolve()
    for candidate in (cursor, *cursor.parents):
        if (candidate / REPO_MARKER).exists():
            return candidate
    raise RuntimeError(f"Could not resolve the Lightpanda repo root from {start_path}")

class GoogleHomeHandler(http.server.BaseHTTPRequestHandler):
    fixture_html = b""

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/ping":
            self.send_bytes(200, b"ok", "text/plain; charset=utf-8")
            return

        if path in {"/", "/google-home.html"}:
            self.send_bytes(200, self.fixture_html, "text/html; charset=utf-8")
            return

        if path == "/search":
            query = urllib.parse.parse_qs(parsed.query)
            value = query.get("q", [""])[0]
            sys.stderr.write(f"SEARCH {self.path}\n")
            sys.stderr.flush()
            title = f"Search Submitted {value}".encode("utf-8")
            body = (
                b'<!doctype html><html><head><meta charset="utf-8"><title>'
                + title
                + b"</title></head><body><h1>Submitted</h1></body></html>"
            )
            self.send_bytes(200, body, "text/html; charset=utf-8")
            return

        if path.startswith("/xjs/_/js/"):
            self.send_bytes(200, b"", "application/javascript; charset=utf-8")
            return

        if path.startswith("/xjs/_/ss/"):
            self.send_bytes(200, b"", "text/css; charset=utf-8")
            return

        if path.startswith("/images/") or path in {"/favicon.ico", "/client_204", "/gen_204"}:
            self.send_response(204)
            self.end_headers()
            return

        self.send_error(404)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))
        sys.stderr.flush()

    def send_bytes(self, status: int, body: bytes, content_type: str):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def main():
    port = int(sys.argv[1])
    server_root = pathlib.Path(__file__).resolve().parent
    repo_root = resolve_repo_root(server_root)
    fixture_path = repo_root / FIXTURE_RELATIVE_PATH
    GoogleHomeHandler.fixture_html = fixture_path.read_bytes()

    with ReusableTCPServer(("127.0.0.1", port), GoogleHomeHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
