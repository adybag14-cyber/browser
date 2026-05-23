#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


PAGE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Google Home Enter Submit Probe Ready</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      background: #f8f9fa;
      color: #202124;
    }

    .shell {
      width: 720px;
      margin: 48px auto;
      text-align: center;
    }

    .mark {
      font-size: 40px;
      font-weight: 700;
      letter-spacing: 0;
      margin-bottom: 28px;
    }

    form[name="f"] {
      display: inline-flex;
      flex-direction: column;
      gap: 16px;
      align-items: center;
    }

    .search-row {
      width: 520px;
      border: 1px solid #dfe1e5;
      border-radius: 24px;
      background: #fff;
      padding: 10px 18px;
      box-sizing: border-box;
    }

    input[name="q"] {
      width: 100%;
      border: 0;
      outline: none;
      font-size: 20px;
      line-height: 28px;
      color: #202124;
      background: transparent;
    }

    .actions {
      display: flex;
      gap: 12px;
    }

    button,
    input[type="submit"] {
      border: 1px solid #dadce0;
      background: #fff;
      border-radius: 6px;
      padding: 10px 16px;
      font-size: 14px;
      color: #202124;
      cursor: pointer;
    }

    #status {
      min-height: 24px;
      font-size: 14px;
      color: #5f6368;
    }
  </style>
</head>
<body>
  <main class="shell">
    <div class="mark">Google Probe</div>
    <form name="f" action="/search" method="get" autocomplete="off">
      <div class="search-row">
        <input
          name="q"
          title="Search"
          autocomplete="off"
          autofocus
          spellcheck="false"
        >
      </div>
      <div class="actions">
        <input type="submit" name="btnG" value="Google Search">
        <button type="button" id="clear">Clear</button>
      </div>
    </form>
    <p id="status">ready</p>
  </main>
  <script>
    (function () {
      const form = document.forms.f;
      const input = form.q;
      const status = document.getElementById("status");
      const clear = document.getElementById("clear");

      window.google = window.google || {};
      window.google.ac = {
        c(client) {
          status.textContent = "ac.c:" + (client || "none");
        }
      };

      function title(prefix) {
        const value = input.value.trim();
        document.title = prefix + (value ? " " + value : "");
      }

      function setStatus(prefix) {
        status.textContent = prefix + ":" + (input.value || "");
      }

      document.addEventListener("keydown", function (event) {
        if (event.target === input) {
          title("Keydown");
          Promise.resolve().then(function () {
            form.dataset.afterKeydown = input.value;
          });
        }
      }, true);

      document.addEventListener("beforeinput", function (event) {
        if (event.target === input) {
          setStatus("beforeinput");
        }
      }, true);

      document.addEventListener("input", function (event) {
        if (event.target === input) {
          title("Typed");
          setStatus("input");
        }
      }, true);

      form.addEventListener("submit", function () {
        title("Submitting");
        setStatus("submit");
      });

      clear.addEventListener("click", function () {
        input.value = "";
        input.focus();
        title("Cleared");
        setStatus("clear");
      });

      window.addEventListener("load", function () {
        title("Ready");
        input.focus();
        setStatus("load");
      });
    })();
  </script>
</body>
</html>
"""


def render_result(query: str) -> bytes:
    safe_query = html.escape(query)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Submitted {safe_query}</title>
</head>
<body>
  <main>
    <h1>Submitted {safe_query}</h1>
    <p id="query">{safe_query}</p>
  </main>
</body>
</html>
""".encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    def _send_bytes(self, status: HTTPStatus, payload: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/ping":
            self._send_bytes(HTTPStatus.OK, b"ok\n", "text/plain; charset=utf-8")
            return

        if parsed.path == "/google-home-enter-submit.html":
            self._send_bytes(
                HTTPStatus.OK,
                PAGE.encode("utf-8"),
                "text/html; charset=utf-8",
            )
            return

        if parsed.path == "/search":
            query = parse_qs(parsed.query).get("q", [""])[0]
            print(f"FORM_SUBMIT /search?q={query}", flush=True)
            self._send_bytes(HTTPStatus.OK, render_result(query), "text/html; charset=utf-8")
            return

        self._send_bytes(HTTPStatus.NOT_FOUND, b"not found\n", "text/plain; charset=utf-8")

    def log_message(self, format: str, *args: object) -> None:
        print(f"HTTP {self.address_string()} {format % args}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("port", type=int)
    args = parser.parse_args()

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
