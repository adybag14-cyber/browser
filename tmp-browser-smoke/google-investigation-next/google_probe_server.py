import http.server
import socketserver
import sys
import urllib.parse
from pathlib import Path


ROOT = Path(__file__).resolve().parent
FIXTURE_PATH = ROOT.parents[2] / "src" / "browser" / "tests" / "page" / "google_home_title_probe.html"
INPUT_PHASE_PATH = ROOT / "google-home-input.html"


class GoogleProbeHandler(http.server.BaseHTTPRequestHandler):
    fixture_bytes = FIXTURE_PATH.read_bytes()
    input_phase_bytes = INPUT_PHASE_PATH.read_bytes()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path in ("/", "/google-home.html"):
            body = self.fixture_bytes
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/google-home-input.html":
            body = self.input_phase_bytes
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/search":
            params = urllib.parse.parse_qs(parsed.query)
            query = params.get("q", [""])[0]
            sys.stderr.write("SEARCH_SUBMIT " + self.path + "\n")
            sys.stderr.flush()

            title = f"SEARCH:{query}".encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body><h1>Search submit</h1></body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/submitted.html":
            params = urllib.parse.parse_qs(parsed.query)
            query = params.get("q", [""])[0]
            submit_phase = params.get("submit_phase", ["missing"])[0]
            sys.stderr.write("GOOGLE_HOME_INPUT_SUBMIT " + self.path + "\n")
            sys.stderr.flush()

            title = f"Google Home Result {submit_phase} {query}".strip().encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body><h1>Google Home Result</h1></body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_error(404)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))
        sys.stderr.flush()


def main():
    port = int(sys.argv[1])
    with socketserver.TCPServer(("127.0.0.1", port), GoogleProbeHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
