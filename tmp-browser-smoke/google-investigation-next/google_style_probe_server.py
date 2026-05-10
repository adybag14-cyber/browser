from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent
PAGE_ROOT = ROOT.parents[1] / "src" / "browser" / "tests" / "page"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(PAGE_ROOT), **kwargs)

    def do_GET(self):
        if self.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        return super().do_GET()


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: google_style_probe_server.py <port>", file=sys.stderr)
        return 2

    port = int(sys.argv[1])
    with ThreadingHTTPServer(("127.0.0.1", port), Handler) as server:
        server.serve_forever()


if __name__ == "__main__":
    raise SystemExit(main())
