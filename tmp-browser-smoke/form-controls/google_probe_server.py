import http.server
import socketserver
import sys


GOOGLE_PROBE_HTML = """<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Google Probe Ready</title>
</head>
<body style="margin:0;background:#ffffff;color:#202124;font:20px Arial,sans-serif;">
  <main style="display:flex;min-height:100vh;align-items:center;justify-content:center;">
    <section style="width:620px;text-align:center;">
      <div style="font-size:72px;font-weight:700;letter-spacing:0;color:#1a73e8;margin-bottom:20px;">Google</div>
      <form id="search-form" name="f" action="/google-submitted.html" method="get" style="margin:0;">
        <input
          id="q"
          name="q"
          type="text"
          autofocus
          autocomplete="off"
          spellcheck="false"
          style="display:block;width:100%;height:56px;border:1px solid #dfe1e5;border-radius:28px;padding:0 22px;font:24px Arial,sans-serif;box-sizing:border-box;"
        >
      </form>
      <p style="margin:16px 0 0 0;color:#5f6368;font-size:16px;">Probe expects typed text and Enter submit on the headed Win32 surface.</p>
    </section>
  </main>
  <script>
    const form = document.forms.f;
    const input = form.q;
    window.__lpEvents = [];

    function pushEvent(label) {
      window.__lpEvents.push(label);
    }

    document.addEventListener('keydown', function(e) {
      pushEvent('KD:' + [e.key || '', e.code || '', e.keyCode, e.which, e.defaultPrevented ? 1 : 0].join('|'));
    }, true);

    document.addEventListener('keypress', function(e) {
      pushEvent('KP:' + [e.key || '', e.code || '', e.keyCode, e.which, e.charCode, e.defaultPrevented ? 1 : 0].join('|'));
    }, true);

    document.addEventListener('beforeinput', function(e) {
      pushEvent('BI:' + [(e.data || ''), e.defaultPrevented ? 1 : 0].join('|'));
    }, true);

    document.addEventListener('input', function(e) {
      const target = e.target;
      pushEvent('IN:' + [target && target.value || '', e.defaultPrevented ? 1 : 0].join('|'));
      if (target === input) {
        document.title = 'TYPE:' + input.value + '|' + window.__lpEvents.join(',');
      }
    }, true);

    form.addEventListener('submit', function(e) {
      e.preventDefault();
      pushEvent('SU:' + input.value + '|1');
      document.title = 'SUBMIT:' + input.value + '|' + window.__lpEvents.join(',');
    }, true);

    window.addEventListener('load', function() {
      input.focus();
      document.title = 'Google Probe Ready';
    }, { once: true });
  </script>
</body>
</html>
"""


class GoogleProbeHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            self._send(200, b"ok", "text/plain; charset=utf-8")
            return

        if self.path == "/google-home.html":
            self._send(200, GOOGLE_PROBE_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return

        if self.path.startswith("/google-submitted.html"):
            self._send(
                200,
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>Google Probe Submitted</title></head><body><h1>submitted</h1></body></html>",
                "text/html; charset=utf-8",
            )
            return

        self.send_error(404)

    def _send(self, status, body, content_type):
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
    with socketserver.TCPServer(("127.0.0.1", port), GoogleProbeHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
