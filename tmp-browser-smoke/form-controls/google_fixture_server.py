from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys


REPO_ROOT = Path(__file__).resolve().parents[2]
GOOGLE_FIXTURE = REPO_ROOT / "src" / "browser" / "tests" / "page" / "google_home_title_probe.html"

FOCUS_PATCH = """
<script>
(function () {
  function focusQuery() {
    var q = (document.forms.f && document.forms.f.q) || document.querySelector('[name="q"]');
    if (!q) return false;
    try {
      q.focus();
      if (q.setSelectionRange) {
        q.setSelectionRange(q.value.length, q.value.length);
      }
    } catch (_e) {}
    return true;
  }
  if (!focusQuery()) {
    window.addEventListener('load', function () {
      focusQuery();
      window.setTimeout(focusQuery, 150);
      window.setTimeout(focusQuery, 400);
    }, { once: true });
  }
})();
</script>
</body></html>
""".strip()


def build_fixture() -> bytes:
    html = GOOGLE_FIXTURE.read_text(encoding="utf-8")
    html = html.replace('<base href="https://www.google.com/">', "", 1)
    if "</body></html>" in html:
        html = html.replace("</body></html>", FOCUS_PATCH, 1)
    return html.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            self._send_bytes(200, b"ok", "text/plain; charset=utf-8")
            return

        if self.path.startswith("/google.html"):
            self._send_bytes(200, build_fixture(), "text/html; charset=utf-8")
            return

        if self.path.startswith("/search"):
            sys.stderr.write("GOOGLE_SEARCH " + self.path + "\n")
            sys.stderr.flush()
            body = b"<!doctype html><html><head><meta charset=\"utf-8\"><title>Search Navigation</title></head><body></body></html>"
            self._send_bytes(200, body, "text/html; charset=utf-8")
            return

        if self.path.startswith("/xjs/") or self.path.startswith("/images/") or self.path.startswith("/gen_204") or self.path.startswith("/client_204"):
            self.send_response(204)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        self.send_error(404)

    def _send_bytes(self, status: int, body: bytes, content_type: str):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))
        sys.stderr.flush()


def main():
    port = int(sys.argv[1])
    with ThreadingHTTPServer(("127.0.0.1", port), Handler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
