import http.server
import socketserver
import sys
import urllib.parse


class GoogleHomeFixtureHandler(http.server.BaseHTTPRequestHandler):
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

        if parsed.path == "/probe.js":
            body = (
                b"(function(){"
                b"const form=document.f;"
                b"const input=form&&form.q;"
                b"if(!form||!input){document.title='Google Fixture Missing Controls';return;}"
                b"window.__lpGoogleFixtureEvents=[];"
                b"function logEvent(label){"
                b" const value=input.value||'';"
                b" window.__lpGoogleFixtureEvents.push(label+':'+value);"
                b" document.title='Google Fixture '+label+' '+value;"
                b"}"
                b"['focus','keydown','beforeinput','input','keypress','keyup','change'].forEach(function(type){"
                b" input.addEventListener(type,function(){logEvent(type);},true);"
                b"});"
                b"form.addEventListener('submit',function(){logEvent('submit');},true);"
                b"setTimeout(function(){"
                b" input.focus();"
                b" logEvent('ready');"
                b"},0);"
                b"})();"
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/google-home.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Google Fixture Base</title>"
                b"<style>"
                b"body{margin:0;background:#fff;color:#202124;font:16px Arial,sans-serif;}"
                b"main{width:100%;padding:72px 0 0;text-align:center;}"
                b".logo{font-size:44px;font-weight:700;letter-spacing:0;color:#1a73e8;margin:0 0 28px;}"
                b".search-shell{display:inline-block;padding:18px 22px 26px;border:1px solid #dadce0;border-radius:24px;}"
                b"input[name=q]{display:block;width:320px;height:36px;padding:0 14px;border:1px solid #dadce0;border-radius:18px;font-size:18px;}"
                b".actions{margin-top:18px;display:flex;gap:12px;justify-content:center;}"
                b"button,input[type=submit]{height:36px;padding:0 16px;border:1px solid #dadce0;border-radius:6px;background:#f8f9fa;color:#202124;font-size:14px;}"
                b".hint{margin-top:18px;color:#5f6368;font-size:13px;}"
                b"</style>"
                b"<script>"
                b"window.__lpGoogleFixtureEarly=[];"
                b"document.addEventListener('keydown',function(e){window.__lpGoogleFixtureEarly.push('KD:'+e.key);},true);"
                b"document.addEventListener('beforeinput',function(e){window.__lpGoogleFixtureEarly.push('BI:'+(e.data||''));},true);"
                b"document.addEventListener('input',function(e){var t=e.target;window.__lpGoogleFixtureEarly.push('IN:'+((t&&t.value)||''));},true);"
                b"</script>"
                b"<script defer src=\"/probe.js\"></script>"
                b"</head><body>"
                b"<main>"
                b"<div class=\"logo\">Google Fixture</div>"
                b"<form name=\"f\" action=\"/search\" method=\"get\">"
                b"<div class=\"search-shell\">"
                b"<input id=\"search-box\" name=\"q\" type=\"text\" title=\"Search\" autocomplete=\"off\" autofocus>"
                b"<div class=\"actions\">"
                b"<input type=\"submit\" name=\"btnG\" value=\"Google Search\">"
                b"<button type=\"submit\" name=\"btnI\" value=\"1\">I'm Feeling Lucky</button>"
                b"</div>"
                b"</div>"
                b"</form>"
                b"<p class=\"hint\">Legacy named form access and deferred script wiring stay enabled on this fixture.</p>"
                b"</main></body></html>"
            )
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
            title = f"Google Fixture Submitted {query}".encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body style=\"font:18px Arial,sans-serif;padding:32px;\">"
                b"<h1>Submitted</h1><p>"
                + query.encode("utf-8")
                + b"</p></body></html>"
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
    with socketserver.TCPServer(("127.0.0.1", port), GoogleHomeFixtureHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
