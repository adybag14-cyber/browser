import http.server
import socketserver
import sys
import urllib.parse


class GoogleHomeInputHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path == "/" or self.path == "/google-home.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Google Home Base</title>"
                b"</head><body style=\"margin:0;background:#ffffff;color:#202124;font:20px Arial,sans-serif;\">"
                b"<main style=\"padding:40px 32px;\">"
                b"<h1 style=\"margin:0 0 18px 0;font-size:32px;font-weight:600;\">Google Home Input Smoke</h1>"
                b"<p style=\"margin:0 0 18px 0;max-width:700px;line-height:1.4;\">"
                b"This probe exercises click focus, legacy named form access, typed text, and Enter submit ordering."
                b"</p>"
                b"<form id=\"search-form\" name=\"f\" action=\"/results.html\" method=\"get\" style=\"margin:0;\">"
                b"<label for=\"search-box\" style=\"display:block;margin:0 0 10px 0;font-size:18px;\">Search</label>"
                b"<input id=\"search-box\" name=\"q\" type=\"text\" autocomplete=\"off\""
                b" style=\"display:block;width:520px;max-width:100%;height:48px;padding:0 14px;border:1px solid #c4c7c5;border-radius:24px;font-size:22px;\" />"
                b"<input type=\"hidden\" name=\"submit_keydown\" id=\"submit-keydown\" value=\"\" />"
                b"<input type=\"hidden\" name=\"submit_value\" id=\"submit-value\" value=\"\" />"
                b"<input type=\"hidden\" name=\"submit_keypress\" id=\"submit-keypress\" value=\"false\" />"
                b"<input type=\"hidden\" name=\"submit_input\" id=\"submit-input\" value=\"false\" />"
                b"</form>"
                b"<script>"
                b"const form = document.f;"
                b"const input = form.q;"
                b"let lastEnterKeydownValue = '';"
                b"let sawEnterKeypress = false;"
                b"let sawInput = false;"
                b"input.addEventListener('focus', () => {"
                b" document.title = 'Google Home Focus ' + (document.activeElement === input);"
                b"});"
                b"input.addEventListener('input', () => {"
                b" sawInput = true;"
                b" document.title = 'Google Home Input ' + input.value;"
                b"});"
                b"input.addEventListener('keydown', (event) => {"
                b" if (event.key === 'Enter') {"
                b"   lastEnterKeydownValue = input.value;"
                b"   document.title = 'Google Home Enter Keydown ' + input.value;"
                b" }"
                b"});"
                b"input.addEventListener('keypress', (event) => {"
                b" if (event.key === 'Enter') {"
                b"   sawEnterKeypress = true;"
                b"   document.title = 'Google Home Enter Keypress ' + input.value;"
                b" }"
                b"});"
                b"form.addEventListener('submit', () => {"
                b" document.getElementById('submit-keydown').value = lastEnterKeydownValue;"
                b" document.getElementById('submit-value').value = input.value;"
                b" document.getElementById('submit-keypress').value = String(sawEnterKeypress);"
                b" document.getElementById('submit-input').value = String(sawInput);"
                b"});"
                b"</script>"
                b"</main></body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.startswith("/results.html"):
            parsed = urllib.parse.urlparse(self.path)
            params = urllib.parse.parse_qs(parsed.query)
            q = params.get("q", [""])[0]
            submit_keydown = params.get("submit_keydown", [""])[0]
            submit_value = params.get("submit_value", [""])[0]
            submit_keypress = params.get("submit_keypress", ["false"])[0]
            submit_input = params.get("submit_input", ["false"])[0]
            sys.stderr.write(
                "GOOGLE_HOME_SUBMIT "
                f"q={q!r} "
                f"submit_keydown={submit_keydown!r} "
                f"submit_value={submit_value!r} "
                f"submit_keypress={submit_keypress!r} "
                f"submit_input={submit_input!r}\n"
            )
            sys.stderr.flush()
            title = f"Google Results {q}".encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body style=\"font:20px Arial,sans-serif;\">"
                b"<main style=\"padding:32px;\">"
                b"<h1>Google Results Probe</h1>"
                b"<p id=\"summary\">Query: "
                + q.encode("utf-8")
                + b"</p>"
                b"</main></body></html>"
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
    with socketserver.TCPServer(("127.0.0.1", port), GoogleHomeInputHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
