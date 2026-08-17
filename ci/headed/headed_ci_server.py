from __future__ import annotations

import argparse
import base64
import pathlib
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PARENT = b"""<!doctype html><html><head><meta charset='utf-8'><title>Headed Frame CI</title>
<style>body{font-family:Arial,sans-serif;background:#f4f6f8;color:#14213d;margin:20px}h1{font-size:26px}.card{background:white;border:2px solid #4666ff;border-radius:12px;padding:14px;width:800px}iframe{display:block;width:760px;height:430px;border:4px solid #2437a5;border-radius:10px;background:#fff}</style></head>
<body><h1>Lightpanda headed iframe verification</h1><div class='card'><p id='root-marker'>ROOT FRAME VISIBLE</p><iframe id='challenge-frame' width='760' height='430' src='http://127.0.0.1:18774/challenge.html' title='Verification challenge'></iframe></div></body></html>"""

CHILD = b"""<!doctype html><html><head><meta charset='utf-8'><title>Challenge Frame</title>
<style>body{font-family:Arial,sans-serif;background:#fff6dc;color:#222;margin:18px}h2{font-size:23px}.box{border:3px solid #d97706;border-radius:10px;padding:12px}iframe{display:block;width:650px;height:245px;border:4px solid #b91c1c;border-radius:8px;background:white}</style></head>
<body><div class='box'><h2>Human verification</h2><p>CROSS-ORIGIN CHILD FRAME VISIBLE</p><iframe id='nested' width='650' height='245' src='http://127.0.0.1:18775/nested.html' title='Nested verification'></iframe></div></body></html>"""

NESTED = b"""<!doctype html><html><head><meta charset='utf-8'><title>Nested Challenge</title>
<style>body{font-family:Arial,sans-serif;background:#e8fff0;color:#123;margin:18px}label{font-weight:700}input{display:block;width:360px;height:38px;font-size:18px;margin:10px 0;border:2px solid #087f5b}button{font-size:20px;font-weight:700;padding:10px 24px;border:2px solid #14532d;background:#dcfce7}#status{font-size:18px;font-weight:700;margin-top:10px}</style></head>
<body><p>NESTED CROSS-ORIGIN FRAME VISIBLE</p><label for='answer'>Type the human phrase</label><input id='answer' value='' placeholder='brown fox'><button id='verify' onclick=\"var a=document.getElementById('answer');var s=document.getElementById('status');if(a.value==='brown fox'){this.textContent='VERIFIED';s.textContent='HUMAN VERIFICATION PASSED';document.title='Nested Verified';fetch('/verified',{method:'POST'}).catch(function(){})}else{s.textContent='TRY AGAIN: '+a.value}\">I AM HUMAN</button><div id='status'>WAITING FOR HUMAN INPUT</div></body></html>"""

TRIVIAL = b"""<!doctype html><html><head><meta charset='utf-8'><title>RSS Baseline</title></head><body><h1>RSS baseline</h1><p>The quick brown fox jumps over the lazy dog.</p></body></html>"""

# A deterministic page deliberately shaped more like a search/results site:
# many href resolutions plus foreground/background image request contexts. It
# catches native-paint scratch accidentally escaping into Frame.call/local arenas.
def _rich_page() -> bytes:
    links = "".join(
        f"<a class='result' href='/result/{i}?q=brown+fox&src=headed-ci'>Result {i}: brown fox link</a>"
        for i in range(240)
    )
    images = "".join(
        f"<img src='/asset.png?i={i}' alt='asset {i}' width='24' height='24'>"
        for i in range(48)
    )
    html = f"""<!doctype html><html><head><meta charset='utf-8'><title>Rich RSS Fixture</title>
<style>
body{{font-family:Arial,sans-serif;margin:16px;background:#f6f7f8;color:#172033}}
.hero{{height:80px;background-image:url('/asset.png?background=1');background-repeat:repeat;border:2px solid #445}}
.result{{display:block;padding:2px 4px}}
.assets{{display:flex;flex-wrap:wrap;gap:2px;width:760px}}
</style></head><body><h1>Rich repaint memory fixture</h1><div class='hero'>IMAGE BACKGROUND</div>
<section id='results'>{links}</section><div class='assets'>{images}</div></body></html>"""
    return html.encode("utf-8")

RICH = _rich_page()
# Opaque 8x8 PNG; query strings make request URLs distinct while bytes remain tiny.
ASSET_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGP8z4AdMOAEMCpFJQAAOwAB/6WgWQAAAABJRU5ErkJggg=="
)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    verified_file: str | None = None

    def _body(self, status: int, body: bytes, content_type: str = "text/plain") -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        port = self.server.server_port
        if self.path == "/healthz":
            return self._body(200, b"ok")
        if port == 18773 and self.path in ("/", "/parent.html"):
            return self._body(200, PARENT, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/trivial.html":
            return self._body(200, TRIVIAL, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/rich.html":
            return self._body(200, RICH, "text/html; charset=utf-8")
        if port == 18773 and self.path.startswith("/asset.png"):
            return self._body(200, ASSET_PNG, "image/png")
        if port == 18773 and self.path.startswith("/result/"):
            return self._body(200, b"result", "text/plain; charset=utf-8")
        if port == 18774 and self.path == "/challenge.html":
            return self._body(200, CHILD, "text/html; charset=utf-8")
        if port == 18775 and self.path == "/nested.html":
            return self._body(200, NESTED, "text/html; charset=utf-8")
        self.send_error(404)

    def do_POST(self):
        if self.server.server_port == 18775 and self.path == "/verified":
            if self.verified_file:
                path = pathlib.Path(self.verified_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("verified\n", encoding="utf-8")
            return self._body(204, b"")
        self.send_error(404)

    def log_message(self, fmt, *args):
        return


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ready-file")
    parser.add_argument("--verified-file")
    args = parser.parse_args()
    Handler.verified_file = args.verified_file
    servers = [ThreadingHTTPServer(("127.0.0.1", p), Handler) for p in (18773, 18774, 18775)]
    threads = [threading.Thread(target=s.serve_forever, daemon=True) for s in servers]
    for t in threads:
        t.start()
    if args.ready_file:
        path = pathlib.Path(args.ready_file)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("ready\n", encoding="utf-8")
    stop = threading.Event()

    def shutdown(*_):
        stop.set()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)
    try:
        while not stop.wait(0.25):
            pass
    finally:
        for s in servers:
            s.shutdown()
            s.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
