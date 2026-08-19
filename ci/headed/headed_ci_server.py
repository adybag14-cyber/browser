from __future__ import annotations

import argparse
import base64
import pathlib
import signal
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PARENT = b"""<!doctype html><html><head><meta charset='utf-8'><title>Headed Frame CI</title>
<style>body{font-family:Arial,sans-serif;background:#f4f6f8;color:#14213d;margin:20px}h1{font-size:26px}.card{background:white;border:2px solid #4666ff;border-radius:12px;padding:14px;width:800px}iframe{display:block;width:760px;height:430px;border:4px solid #2437a5;border-radius:10px;background:#fff}</style></head>
<body><h1>Lightpanda headed iframe verification</h1><div class='card'><p id='root-marker'>ROOT FRAME VISIBLE</p><iframe id='challenge-frame' width='760' height='430' src='http://127.0.0.1:18774/challenge.html' title='Verification challenge'></iframe></div></body></html>"""

CHILD = b"""<!doctype html><html><head><meta charset='utf-8'><title>Challenge Frame</title>
<style>body{font-family:Arial,sans-serif;background:#fff6dc;color:#222;margin:18px}h2{font-size:23px}.box{border:3px solid #d97706;border-radius:10px;padding:12px}iframe{display:block;width:650px;height:245px;border:4px solid #b91c1c;border-radius:8px;background:white}</style></head>
<body><div class='box'><h2>Human verification</h2><p>CROSS-ORIGIN CHILD FRAME VISIBLE</p><iframe id='nested' width='650' height='245' src='http://127.0.0.1:18775/nested.html' title='Nested verification'></iframe></div></body></html>"""

NESTED_CSS = b"""body{font-family:Arial,sans-serif;background:#e8fff0;color:#123;margin:18px}label{font-weight:700}input{display:block;width:360px;height:38px;font-size:18px;margin:10px 0;border:2px solid #087f5b}button{font-size:20px;font-weight:700;padding:10px 24px;border:2px solid #14532d;background:#dcfce7}#status{font-size:18px;font-weight:700;margin-top:10px;background:url('/nested-dot.png');background-repeat:no-repeat;padding-left:24px}"""

NESTED = b"""<!doctype html><html><head><meta charset='utf-8'><title>Nested Challenge</title>
<link rel='stylesheet' href='/nested.css'></head>
<body><p>NESTED CROSS-ORIGIN FRAME VISIBLE</p><label for='answer'>Type the human phrase</label><input id='answer' value='' placeholder='type the phrase here'><button id='verify' onclick=\"var a=document.getElementById('answer');var s=document.getElementById('status');if(a.value==='brown fox'){this.textContent='VERIFIED';s.textContent='HUMAN VERIFICATION PASSED';document.title='Nested Verified';fetch('/verified',{method:'POST'}).catch(function(){})}else{s.textContent='TRY AGAIN: '+a.value}\">I AM HUMAN</button><div id='status'>WAITING FOR HUMAN INPUT</div>
<script>addEventListener('load',function(){var a=document.getElementById('answer');var b=document.getElementById('verify');var ac=getComputedStyle(a);var bc=getComputedStyle(b);var sc=getComputedStyle(document.getElementById('status'));var ar=a.getBoundingClientRect();if(ac.getPropertyValue('width')==='360px'&&ac.getPropertyValue('height')==='38px'&&ar.width===360&&ar.height===38&&a.offsetWidth===360&&a.offsetHeight===38&&bc.getPropertyValue('background-color')==='#dcfce7'&&bc.getPropertyValue('border-width')==='2px'&&bc.getPropertyValue('border-style')==='solid'&&bc.getPropertyValue('border-color')==='#14532d'&&sc.getPropertyValue('background-image').indexOf('nested-dot.png')!==-1){fetch('/styled',{method:'POST'}).catch(function(){})}});</script></body></html>"""

NATIVE_KEYBOARD = b"""<!doctype html><html><head><meta charset='utf-8'><title>Native keyboard input</title></head><body>
<label for='native-key'>Native key</label><input id='native-key' style='display:block;width:360px;height:38px;margin:20px' value='abc'>
<script>var k=document.getElementById('native-key');addEventListener('load',function(){k.focus();k.setSelectionRange(1,1)});k.addEventListener('input',function(){fetch('/keyboard-value?value='+encodeURIComponent(k.value),{method:'POST'}).catch(function(){})});</script>
</body></html>"""
NATIVE_CARET = b"""<!doctype html><html><head><meta charset='utf-8'><title>Native click caret</title>
<style>body{font-family:Arial,sans-serif;margin:18px}input{display:block;width:360px;height:38px;margin:20px;border:3px solid #7a1f9a;background:#f8e9ff;font-size:18px}</style></head><body>
<label for='caret-key'>Click caret target</label><input id='caret-key' value='abcdef'><button id='caret-sink'>FOCUS SINK</button>
<script>var k=document.getElementById('caret-key');addEventListener('load',function(){k.focus();k.setSelectionRange(k.value.length,k.value.length)});k.addEventListener('input',function(){fetch('/caret-value?value='+encodeURIComponent(k.value)+'&start='+k.selectionStart,{method:'POST'}).catch(function(){})});</script>
</body></html>"""

NATIVE_NAVIGATION = b"""<!doctype html><html><head><meta charset='utf-8'><title>Native text navigation</title>
<style>body{font-family:Arial,sans-serif;margin:18px}input,textarea{display:block;width:360px;margin:18px;border:2px solid #1d4ed8;font-size:18px}input{height:38px}textarea{height:80px}</style></head><body>
<input id='nav-input' value='abcde'><textarea id='nav-area'>abcde</textarea>
<script>
var target=(location.hash==='#textarea')?document.getElementById('nav-area'):document.getElementById('nav-input');
function report(){fetch('/navigation-state?target='+target.id+'&value='+encodeURIComponent(target.value)+'&start='+target.selectionStart+'&end='+target.selectionEnd+'&direction='+encodeURIComponent(target.selectionDirection),{method:'POST'}).catch(function(){})}
addEventListener('load',function(){target.value=target.value;target.focus();target.setSelectionRange(target.value.length,target.value.length);report()});
target.addEventListener('keyup',report);target.addEventListener('input',report);
</script></body></html>"""

TRIVIAL = b"""<!doctype html><html><head><meta charset='utf-8'><title>RSS Baseline</title></head><body><h1>RSS baseline</h1><p>The quick brown fox jumps over the lazy dog.</p></body></html>"""

GOOGLE_BOOTSTRAP = b"""<!doctype html><html><head><meta charset='utf-8'><title>Google-style JS bootstrap</title></head><body>
<div id='fallback' style='display:none'>JAVASCRIPT TROUBLESHOOTING FALLBACK</div>
<script>
window.knitsail={a:function(payload,callback){setTimeout(function(){callback(function(done,bindings){Promise.resolve().then(function(){done('synthetic-ok')})})},25)}};
Promise.resolve(false).then(function(done){
  if(done)return;
  window.knitsail.a('payload',function(run){
    run(function(token){
      document.cookie='SG_SS='+token+'; Path=/; SameSite=Lax';
      location.replace('/google-bootstrap-result.html');
    },[{}]);
  },false,undefined,undefined,undefined,undefined,true);
});
setTimeout(function(){
  var fallback=document.getElementById('fallback');
  fallback.setAttribute('style','');
  fetch('/bootstrap-fallback-visible',{method:'POST'}).catch(function(){});
},2000);
</script></body></html>"""

GOOGLE_BOOTSTRAP_RESULT = b"""<!doctype html><html><head><meta charset='utf-8'><title>Google-style JS bootstrap complete</title></head><body>
<h1 id='bootstrap-result'>JAVASCRIPT BOOTSTRAP COMPLETE</h1>
<script>
addEventListener('load',function(){
  var ok=document.cookie.indexOf('SG_SS=synthetic-ok')!==-1;
  fetch(ok?'/bootstrap-ok':'/bootstrap-cookie-missing',{method:'POST'}).catch(function(){});
});
</script></body></html>"""

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
    styled_file: str | None = None
    bootstrap_ok_file: str | None = None
    bootstrap_fallback_file: str | None = None
    bootstrap_cookie_missing_file: str | None = None
    keyboard_value_file: str | None = None
    caret_value_file: str | None = None
    navigation_state_file: str | None = None

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
        if port == 18773 and self.path == "/native-keyboard.html":
            return self._body(200, NATIVE_KEYBOARD, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/native-caret.html":
            return self._body(200, NATIVE_CARET, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/native-navigation.html":
            return self._body(200, NATIVE_NAVIGATION, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/google-bootstrap.html":
            return self._body(200, GOOGLE_BOOTSTRAP, "text/html; charset=utf-8")
        if port == 18773 and self.path == "/google-bootstrap-result.html":
            return self._body(200, GOOGLE_BOOTSTRAP_RESULT, "text/html; charset=utf-8")
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
        if port == 18775 and self.path == "/nested.css":
            return self._body(200, NESTED_CSS, "text/css; charset=utf-8")
        if port == 18775 and self.path == "/nested-dot.png":
            return self._body(200, ASSET_PNG, "image/png")
        self.send_error(404)

    def do_POST(self):
        parsed = urllib.parse.urlsplit(self.path)
        if self.server.server_port == 18773 and parsed.path == "/keyboard-value":
            if self.keyboard_value_file:
                value = urllib.parse.parse_qs(parsed.query, keep_blank_values=True).get("value", [""])[0]
                path = pathlib.Path(self.keyboard_value_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(value, encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18773 and parsed.path == "/caret-value":
            if self.caret_value_file:
                params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
                value = params.get("value", [""])[0]
                start = params.get("start", [""])[0]
                path = pathlib.Path(self.caret_value_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(value + "\n" + start + "\n", encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18773 and parsed.path == "/navigation-state":
            if self.navigation_state_file:
                params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
                fields = [params.get(name, [""])[0] for name in ("target", "value", "start", "end", "direction")]
                path = pathlib.Path(self.navigation_state_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("\n".join(fields) + "\n", encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18773 and self.path == "/bootstrap-ok":
            if self.bootstrap_ok_file:
                path = pathlib.Path(self.bootstrap_ok_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("bootstrap-ok\n", encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18773 and self.path == "/bootstrap-fallback-visible":
            if self.bootstrap_fallback_file:
                path = pathlib.Path(self.bootstrap_fallback_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fallback-visible\n", encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18773 and self.path == "/bootstrap-cookie-missing":
            if self.bootstrap_cookie_missing_file:
                path = pathlib.Path(self.bootstrap_cookie_missing_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("cookie-missing\n", encoding="utf-8")
            return self._body(204, b"")
        if self.server.server_port == 18775 and self.path == "/styled":
            if self.styled_file:
                path = pathlib.Path(self.styled_file)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("styled\n", encoding="utf-8")
            return self._body(204, b"")
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
    parser.add_argument("--styled-file")
    parser.add_argument("--bootstrap-ok-file")
    parser.add_argument("--bootstrap-fallback-file")
    parser.add_argument("--bootstrap-cookie-missing-file")
    parser.add_argument("--keyboard-value-file")
    parser.add_argument("--caret-value-file")
    parser.add_argument("--navigation-state-file")
    args = parser.parse_args()
    Handler.verified_file = args.verified_file
    Handler.styled_file = args.styled_file
    Handler.bootstrap_ok_file = args.bootstrap_ok_file
    Handler.bootstrap_fallback_file = args.bootstrap_fallback_file
    Handler.bootstrap_cookie_missing_file = args.bootstrap_cookie_missing_file
    Handler.keyboard_value_file = args.keyboard_value_file
    Handler.caret_value_file = args.caret_value_file
    Handler.navigation_state_file = args.navigation_state_file
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
