import http.server
import socketserver
import sys


GOOGLE_FIXTURE_HTML = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Google Fixture</title>
  <style>
    :root {
      color-scheme: light;
      font-family: Arial, sans-serif;
    }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #ffffff;
      color: #202124;
    }
    main {
      width: min(640px, calc(100vw - 48px));
      text-align: center;
    }
    h1 {
      margin: 0 0 28px;
      font-size: 84px;
      font-weight: 700;
      letter-spacing: 0;
      color: #1f1f1f;
    }
    form {
      display: grid;
      gap: 18px;
      justify-items: center;
    }
    .shell {
      width: 100%;
      border: 1px solid #dfe1e5;
      border-radius: 24px;
      padding: 12px 18px;
      box-sizing: border-box;
      background: #fff;
      box-shadow: 0 1px 6px rgba(32, 33, 36, 0.14);
    }
    input[type="text"] {
      width: 100%;
      border: 0;
      outline: none;
      font: 20px/1.4 Arial, sans-serif;
      color: #202124;
      background: transparent;
      padding: 0;
      margin: 0;
    }
    button {
      border: 1px solid #f8f9fa;
      border-radius: 4px;
      background: #f8f9fa;
      color: #3c4043;
      font: 16px/1.2 Arial, sans-serif;
      padding: 10px 18px;
      cursor: default;
    }
    #status {
      margin-top: 18px;
      min-height: 40px;
      font: 14px/1.4 Consolas, "Courier New", monospace;
      color: #5f6368;
      word-break: break-word;
    }
  </style>
</head>
<body>
  <main>
    <h1>Google</h1>
    <form name="f" action="/search" method="get">
      <div class="shell">
        <input id="fixture-q" name="q" type="text" autocomplete="off" autofocus>
      </div>
      <button type="submit" name="btnG" value="Google Search">Google Search</button>
    </form>
    <div id="status">Booting fixture...</div>
  </main>
  <script>
    window.__lpEarlyEvents = [];

    document.addEventListener('keydown', function (e) {
      window.__lpEarlyEvents.push('KD:' + [
        e.key || '',
        e.code || '',
        e.keyCode || 0,
        e.which || 0,
        e.defaultPrevented ? 1 : 0
      ].join('|'));
    }, true);

    document.addEventListener('keypress', function (e) {
      window.__lpEarlyEvents.push('KP:' + [
        e.key || '',
        e.code || '',
        e.keyCode || 0,
        e.which || 0,
        e.charCode || 0,
        e.defaultPrevented ? 1 : 0
      ].join('|'));
    }, true);

    document.addEventListener('beforeinput', function (e) {
      window.__lpEarlyEvents.push('BI:' + [
        e.data || '',
        e.defaultPrevented ? 1 : 0
      ].join('|'));
    }, true);

    document.addEventListener('input', function (e) {
      var target = e.target;
      window.__lpEarlyEvents.push('IN:' + [
        target && typeof target.value === 'string' ? target.value : '',
        e.defaultPrevented ? 1 : 0
      ].join('|'));
    }, true);

    (function () {
      var badge = document.getElementById('status');
      var currentQ = null;
      var lastMark = 'BOOT';

      function describeElement(el) {
        if (!el) return 'NONE';
        return [
          el.tagName || '',
          (el.getAttribute && (el.getAttribute('name') || '')) || '',
          el.id || '',
          el.isConnected ? '1' : '0'
        ].join(':');
      }

      function renderStatus() {
        var early = window.__lpEarlyEvents.length
          ? window.__lpEarlyEvents[window.__lpEarlyEvents.length - 1]
          : 'NONE';
        var value = currentQ ? (currentQ.value || '') : '';
        var selection = currentQ ? [currentQ.selectionStart, currentQ.selectionEnd].join(':') : 'NONE';
        var summary = lastMark +
          '|A=' + describeElement(document.activeElement) +
          '|Q=' + describeElement(currentQ) +
          '|V=' + value +
          '|S=' + selection +
          '|E=' + early;
        document.title = summary;
        badge.textContent = summary;
      }

      function mark(value) {
        lastMark = value;
        renderStatus();
      }

      function bindQueryInput(q) {
        if (!q || q.__lpProbeBound) {
          return;
        }
        q.__lpProbeBound = true;
        q.addEventListener('focus', function () { mark('FOCUSED'); });
        q.addEventListener('input', function () { mark('TYPED:' + q.value); });
        q.addEventListener('beforeinput', function (e) {
          mark('BEFOREINPUT:' + (e.data || '') + ':' + q.value);
        });
        q.addEventListener('keypress', function (e) {
          mark('KEYPRESS:' + (e.key || '') + ':' + q.value);
        });
        q.addEventListener('keydown', function (e) {
          if (e.key === 'Enter' || e.keyCode === 13 || e.which === 13) {
            mark('KEYDOWN:' + q.value + ':' + e.keyCode + ':' + e.which);
          } else if ((e.key || '').length === 1) {
            mark('KEYDOWN:' + e.key + ':' + q.value);
          }
        });
        if (q.form && !q.form.__lpProbeBound) {
          q.form.__lpProbeBound = true;
          q.form.addEventListener('submit', function (e) {
            e.preventDefault();
            mark('SUBMIT:' + q.value);
          });
        }
      }

      document.addEventListener('focusin', function (e) {
        mark('FOCUSIN:' + describeElement(e.target));
      }, true);

      document.addEventListener('selectionchange', function () {
        mark('SEL:' + describeElement(document.activeElement));
      }, true);

      function syncQueryInput() {
        var next = (document.forms.f && document.forms.f.q) || document.querySelector('[name="q"]');
        if (next !== currentQ) {
          currentQ = next;
          bindQueryInput(currentQ);
          mark(currentQ ? 'BOUND' : 'NOQ');
          return;
        }
        renderStatus();
      }

      syncQueryInput();
      if (!currentQ) {
        return;
      }

      window.setTimeout(function () {
        currentQ.focus();
        currentQ.setSelectionRange(currentQ.value.length, currentQ.value.length);
        mark('READY');
      }, 0);
      window.setInterval(syncQueryInput, 250);
    })();
  </script>
</body>
</html>
"""


class GoogleFixtureHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path == "/" or self.path.startswith("/google-home.html"):
            body = GOOGLE_FIXTURE_HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.startswith("/search"):
            sys.stderr.write("SEARCH_REQUEST " + self.path + "\n")
            sys.stderr.flush()
            body = b"<!doctype html><html><head><meta charset=\"utf-8\"><title>Search Request</title></head><body>Search Request</body></html>"
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
    with socketserver.TCPServer(("127.0.0.1", port), GoogleFixtureHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
