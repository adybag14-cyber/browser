import http.server
import socketserver
import sys
import urllib.parse


class GoogleInputHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path == "/google-home-enter.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Google Probe Home</title>"
                b"</head><body style=\"margin:0;background:#ffffff;color:#202124;font:20px Arial,sans-serif;\">"
                b"<main style=\"width:760px;margin:64px auto 0 auto;text-align:center;\">"
                b"<h1 style=\"margin:0 0 20px 0;font-size:44px;font-weight:600;color:#4285f4;\">Google Probe</h1>"
                b"<form id=\"search-form\" name=\"f\" action=\"/search\" method=\"get\" style=\"margin:0 auto;width:560px;\">"
                b"<input type=\"hidden\" id=\"trace\" name=\"trace\" value=\"\" />"
                b"<input type=\"hidden\" id=\"submit_value\" name=\"submit_value\" value=\"\" />"
                b"<input id=\"search-box\" name=\"q\" type=\"text\" autocomplete=\"off\" autofocus"
                b" style=\"display:block;width:100%;height:56px;padding:0 18px;border:1px solid #dfe1e5;border-radius:28px;font-size:24px;box-sizing:border-box;\" />"
                b"</form>"
                b"<p style=\"margin:18px 0 0 0;font-size:16px;color:#5f6368;\">Type one character, then press Enter.</p>"
                b"<script>"
                b"const form = document.f || document.getElementById('search-form');"
                b"const searchBox = form.q || document.getElementById('search-box');"
                b"const traceField = document.getElementById('trace');"
                b"const submitValueField = document.getElementById('submit_value');"
                b"const events = [];"
                b"function pushEvent(label){events.push(label);traceField.value=events.join('|');}"
                b"searchBox.addEventListener('focus', function(){pushEvent('focus');document.title='Google Probe Focused';});"
                b"searchBox.addEventListener('keydown', function(event){"
                b" if(event.key==='Enter'){pushEvent('keydown-enter:'+searchBox.value);document.title='Google Probe EnterDown '+searchBox.value;return;}"
                b" if(event.key.length===1){pushEvent('keydown-char:'+event.key+':'+searchBox.value);}"
                b"});"
                b"searchBox.addEventListener('keypress', function(event){"
                b" if(event.key==='Enter'){pushEvent('keypress-enter:'+searchBox.value);document.title='Google Probe EnterPress '+searchBox.value;return;}"
                b" if(event.key.length===1){pushEvent('keypress-char:'+event.key+':'+searchBox.value);}"
                b"});"
                b"searchBox.addEventListener('input', function(){pushEvent('input:'+searchBox.value);document.title='Google Probe Typed '+searchBox.value;});"
                b"form.addEventListener('submit', function(){pushEvent('submit:'+searchBox.value);submitValueField.value=searchBox.value;});"
                b"</script>"
                b"</main></body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.startswith("/search"):
            parsed = urllib.parse.urlparse(self.path)
            params = urllib.parse.parse_qs(parsed.query)
            query = params.get("q", [""])[0]
            trace = params.get("trace", [""])[0]
            submit_value = params.get("submit_value", [""])[0]
            sys.stderr.write(
                f"TRACE q={query} submit_value={submit_value} trace={trace}\n"
            )
            sys.stderr.flush()
            title = f"Google Probe Results {query}".encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body style=\"font:20px Arial,sans-serif;\">"
                + b"<h1>Google Probe Results</h1>"
                + f"<p id=\"query\">{query}</p><pre id=\"trace\">{trace}</pre>".encode("utf-8")
                + b"</body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_error(404)

    def log_message(self, fmt, *args):
        sys.stderr.write(
            "%s - - [%s] %s\n"
            % (self.client_address[0], self.log_date_time_string(), fmt % args)
        )
        sys.stderr.flush()


def main():
    port = int(sys.argv[1])
    with socketserver.TCPServer(("127.0.0.1", port), GoogleInputHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
