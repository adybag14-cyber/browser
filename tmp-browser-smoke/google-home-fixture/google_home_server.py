import http.server
import socketserver
import sys
import urllib.parse


HOME_HTML = """<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Google Home Fixture</title>
  <style>
    body {
      margin: 0;
      background: #ffffff;
      color: #1f1f1f;
      font: 16px/1.4 Arial, sans-serif;
    }
    main {
      display: block;
      padding-top: 56px;
      text-align: center;
    }
    .logo {
      width: 272px;
      height: 92px;
      margin: 0 auto 18px auto;
      background: #4d88ff;
      color: #ffffff;
      font-size: 42px;
      font-weight: bold;
      line-height: 92px;
      text-align: center;
    }
    .search-shell {
      display: inline-block;
      width: 496px;
      height: 38px;
      margin: 4px 0;
      background: #8de7c7;
      border: 2px solid #1f8f74;
      box-sizing: border-box;
    }
    .search-shell input {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0 10px;
      border: none;
      background: transparent;
      box-sizing: border-box;
      font: 18px Arial, sans-serif;
    }
    .ds {
      display: inline-block;
      margin: 10px 6px 0 6px;
    }
    .lsbb {
      display: block;
      background: #ececec;
      border: 1px solid #aaaaaa;
      height: 32px;
    }
    .lsb {
      height: 30px;
      border: none;
      background: transparent;
      font: 15px Arial, sans-serif;
      padding: 0 16px;
    }
  </style>
</head>
<body>
  <main>
    <div class="logo">G</div>
    <form name="f" action="/submitted.html" method="get">
      <div class="search-shell">
        <input id="search-box" name="q" type="text" value="">
      </div>
      <br>
      <span class="ds"><span class="lsbb"><input class="lsb" value="Google Search" type="submit"></span></span>
      <span class="ds"><span class="lsbb"><input class="lsb" value="I'm Feeling Lucky" type="submit"></span></span>
    </form>
  </main>
  <script>
    const input = document.forms.f.q;
    input.addEventListener('focus', function () {
      document.title = 'Google Home Focused';
    });
    input.addEventListener('input', function () {
      document.title = 'Google Home Typed ' + input.value;
    });
  </script>
</body>
</html>
"""


class GoogleHomeFixtureHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/ping":
            self._send_bytes(b"ok", "text/plain; charset=utf-8")
            return

        if parsed.path in ("/", "/google-home.html"):
            self._send_bytes(HOME_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return

        if parsed.path == "/submitted.html":
            sys.stderr.write("FORM_SUBMIT " + self.path + "\n")
            sys.stderr.flush()
            params = urllib.parse.parse_qs(parsed.query)
            query = params.get("q", [""])[0]
            title = f"Google Submit {query}"
            body = (
                "<!doctype html><html><head><meta charset=\"utf-8\">"
                f"<title>{title}</title></head>"
                "<body><h1>Submitted</h1></body></html>"
            )
            self._send_bytes(body.encode("utf-8"), "text/html; charset=utf-8")
            return

        self.send_error(404)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))
        sys.stderr.flush()

    def _send_bytes(self, body: bytes, content_type: str):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    port = int(sys.argv[1])
    with socketserver.TCPServer(("127.0.0.1", port), GoogleHomeFixtureHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
