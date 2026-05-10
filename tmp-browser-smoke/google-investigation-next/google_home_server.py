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

        if path == "/google-home-enter-submit.html":
            self.send_bytes(200, self.enter_submit_fixture_html(), "text/html; charset=utf-8")
            return

        if path == "/google-home-result.html":
            sys.stderr.write("GOOGLE_HOME_SUBMIT " + self.path + "\n")
            sys.stderr.flush()
            params = urllib.parse.parse_qs(parsed.query)
            query = params.get("q", [""])[0]
            submit_stage = params.get("submit_stage", ["none"])[0]
            keypress_seen = params.get("keypress_seen", ["0"])[0]
            title = f"Google Home Result {submit_stage} {query}".encode("utf-8")
            body = (
                b'<!doctype html><html><head><meta charset="utf-8"><title>'
                + title
                + b'</title></head><body style="font:20px Arial,sans-serif;">'
                + b"<h1>Google Home Result</h1>"
                + f"<p>query={query}</p><p>submit_stage={submit_stage}</p><p>keypress_seen={keypress_seen}</p>".encode("utf-8")
                + b"</body></html>"
            )
            self.send_bytes(200, body, "text/html; charset=utf-8")
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

    @staticmethod
    def enter_submit_fixture_html() -> bytes:
        return (
            b'<!doctype html><html><head><meta charset="utf-8">'
            b"<title>Google Home Input Ready</title>"
            b'</head><body style="margin:0;background:#ffffff;color:#202124;font:20px Arial,sans-serif;">'
            b'<main style="display:flex;min-height:100vh;align-items:center;justify-content:center;">'
            b'<table role="presentation" style="border-collapse:collapse;">'
            b'<tr><td style="padding:24px 32px;text-align:center;">'
            b'<div style="font-size:34px;margin-bottom:18px;color:#4285f4;">Google Home Probe</div>'
            b'<form name="f" action="/google-home-result.html" method="get" style="display:block;">'
            b'<input id="q" name="q" type="text" autofocus'
            b' style="display:block;width:420px;height:48px;padding:0 16px;border:1px solid #dadce0;border-radius:24px;font-size:22px;" />'
            b'<input id="keydown_seen" name="keydown_seen" type="hidden" value="0" />'
            b'<input id="keypress_seen" name="keypress_seen" type="hidden" value="0" />'
            b'<input id="submit_stage" name="submit_stage" type="hidden" value="none" />'
            b"</form>"
            b"</td></tr></table></main>"
            b"<script>"
            b"const form = document.f;"
            b"const input = form.q;"
            b"const keydownSeen = document.getElementById('keydown_seen');"
            b"const keypressSeen = document.getElementById('keypress_seen');"
            b"const submitStage = document.getElementById('submit_stage');"
            b"input.addEventListener('input', function() {"
            b" document.title = 'Google Home Input ' + input.value;"
            b"});"
            b"input.addEventListener('keydown', function(event) {"
            b" if (event.key === 'Enter') {"
            b"  keydownSeen.value = '1';"
            b"  submitStage.value = 'keydown';"
            b"  document.title = 'Google Home Keydown ' + input.value;"
            b" }"
            b"});"
            b"input.addEventListener('keypress', function(event) {"
            b" if (event.key === 'Enter') {"
            b"  keypressSeen.value = '1';"
            b"  submitStage.value = 'keypress';"
            b"  document.title = 'Google Home Keypress ' + input.value;"
            b" }"
            b"});"
            b"form.addEventListener('submit', function() {"
            b" document.title = 'Google Home Submit ' + submitStage.value + ' ' + input.value;"
            b"});"
            b"</script></body></html>"
        )


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit("usage: google_home_server.py <port> [host]")

    port = int(sys.argv[1])
    host = sys.argv[2] if len(sys.argv) == 3 else "127.0.0.1"
    server_root = pathlib.Path(__file__).resolve().parent
    repo_root = resolve_repo_root(server_root)
    fixture_path = repo_root / FIXTURE_RELATIVE_PATH
    GoogleHomeHandler.fixture_html = fixture_path.read_bytes()

    with ReusableTCPServer((host, port), GoogleHomeHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
