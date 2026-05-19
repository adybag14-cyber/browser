import http.server
import socketserver
import sys
import urllib.parse


class FormHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path == "/label.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Label Smoke Base</title>"
                b"</head><body style=\"margin:0;background:white;color:#222;font:22px sans-serif;\">"
                b"<main style=\"display:block;padding:24px;\">"
                b"<p style=\"display:block;margin:0 0 18px 0;\">Click the label to toggle the checkbox.</p>"
                b"<label id=\"agree-label\" for=\"agree\""
                b" style=\"display:block;width:220px;height:40px;padding:10px;background-color:#1a55d6;color:white;\">"
                b"Agree to smoke test</label>"
                b"<input id=\"agree\" type=\"checkbox\""
                b" style=\"display:block;width:24px;height:24px;margin-top:14px;\" />"
                b"<script>"
                b"const checkbox = document.getElementById('agree');"
                b"checkbox.addEventListener('change', function() {"
                b" document.title='Label Smoke '+checkbox.checked;"
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

        if self.path == "/submit.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Enter Submit Base</title>"
                b"</head><body style=\"margin:0;background:white;color:#222;font:22px sans-serif;\">"
                b"<main style=\"display:block;padding:24px;\">"
                b"<form action=\"/submitted.html\" method=\"get\" style=\"display:block;\">"
                b"<label for=\"name\" style=\"display:block;margin:0 0 10px 0;\">Name</label>"
                b"<input id=\"name\" name=\"name\" type=\"text\" autofocus"
                b" style=\"display:block;width:220px;height:40px;padding:8px;border:1px solid #666;\" />"
                b"</form>"
                b"<script>"
                b"const nameInput = document.getElementById('name');"
                b"nameInput.addEventListener('input', function() {"
                b" document.title='Enter Submit '+nameInput.value;"
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

        if self.path == "/deferred-submit.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Deferred Enter Base</title>"
                b"</head><body style=\"margin:0;background:white;color:#222;font:22px sans-serif;\">"
                b"<main style=\"display:block;padding:24px;\">"
                b"<form id=\"search-form\" name=\"f\" action=\"/submitted.html\" method=\"get\" style=\"display:block;\">"
                b"<label for=\"q\" style=\"display:block;margin:0 0 10px 0;\">Query</label>"
                b"<input id=\"q\" name=\"q\" type=\"text\" autofocus"
                b" style=\"display:block;width:220px;height:40px;padding:8px;border:1px solid #666;\" />"
                b"</form>"
                b"<script>"
                b"const form = document.forms.f;"
                b"const queryInput = form.elements.q;"
                b"queryInput.addEventListener('input', function() {"
                b" document.title='Deferred Enter Typed '+queryInput.value;"
                b"});"
                b"queryInput.addEventListener('keydown', function(event) {"
                b" if (event.key !== 'Enter') return;"
                b" event.preventDefault();"
                b" document.title='Deferred Enter Pending '+queryInput.value;"
                b" setTimeout(function() { form.requestSubmit(); }, 0);"
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

        if self.path == "/google-enter-order.html":
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\">"
                b"<title>Google Enter Ready</title>"
                b"</head><body style=\"margin:0;background:white;color:#202124;font:16px Arial,sans-serif;\">"
                b"<main style=\"padding:28px 24px;\">"
                b"<form action=\"/submitted.html\" method=\"get\" name=\"f\" style=\"display:block;\">"
                b"<input type=\"hidden\" name=\"submit_phase\" id=\"submit_phase\" value=\"idle\" />"
                b"<input type=\"hidden\" name=\"event_log\" id=\"event_log\" value=\"\" />"
                b"<input type=\"hidden\" name=\"active_name\" id=\"active_name\" value=\"\" />"
                b"<input type=\"hidden\" name=\"active_id\" id=\"active_id\" value=\"\" />"
                b"<input type=\"hidden\" name=\"selection_start\" id=\"selection_start\" value=\"\" />"
                b"<input type=\"hidden\" name=\"selection_end\" id=\"selection_end\" value=\"\" />"
                b"<label for=\"q\" style=\"display:block;margin:0 0 10px 0;font-size:14px;\">Search</label>"
                b"<textarea id=\"q\" name=\"q\" rows=\"1\" autocomplete=\"off\" autofocus"
                b" style=\"display:block;width:280px;min-height:40px;padding:8px 10px;border:1px solid #5f6368;resize:none;overflow:hidden;\">"
                b"</textarea>"
                b"</form>"
                b"<script>"
                b"const form=document.forms.f;"
                b"const input=form.q;"
                b"const submitPhase=document.getElementById('submit_phase');"
                b"const eventLog=document.getElementById('event_log');"
                b"const activeName=document.getElementById('active_name');"
                b"const activeId=document.getElementById('active_id');"
                b"const selectionStartField=document.getElementById('selection_start');"
                b"const selectionEndField=document.getElementById('selection_end');"
                b"const events=[];"
                b"function currentActiveName(){ const active=document.activeElement; if(!active)return '-'; return active.getAttribute('name')||active.name||'-'; }"
                b"function currentActiveId(){ const active=document.activeElement; if(!active)return '-'; return active.id||'-'; }"
                b"function currentSelection(which){ try{ if(document.activeElement===input&&typeof input[which]==='number'){ return String(input[which]); } }catch(_err){} return '-'; }"
                b"function captureState(){ activeName.value=currentActiveName(); activeId.value=currentActiveId(); selectionStartField.value=currentSelection('selectionStart'); selectionEndField.value=currentSelection('selectionEnd'); }"
                b"function pushEvent(label){ captureState(); events.push(label+':AN='+activeName.value+':AI='+activeId.value+':SEL='+selectionStartField.value+'-'+selectionEndField.value); eventLog.value=events.join(','); }"
                b"function submitSearch(){ captureState(); pushEvent('SUBMIT:'+input.value); document.title='Google Enter SUBMIT:'+input.value+'|'+submitPhase.value; form.submit(); }"
                b"input.addEventListener('focus',function(){ document.title='Google Enter Focused'; pushEvent('FOCUS'); },true);"
                b"input.addEventListener('keydown',function(e){ if(e.key==='Enter'){submitPhase.value='keydown';pushEvent('KD:Enter:'+input.value);} },true);"
                b"input.addEventListener('keypress',function(e){ if(e.key==='Enter'){ e.preventDefault(); submitPhase.value='keypress'; pushEvent('KP:Enter:'+input.value); submitSearch(); } },true);"
                b"input.addEventListener('keyup',function(e){ if(e.key==='Enter'){pushEvent('KU:Enter:'+input.value);} },true);"
                b"input.addEventListener('beforeinput',function(e){ if(typeof e.data==='string'){pushEvent('BI:'+e.data+':'+input.value);} },true);"
                b"input.addEventListener('input',function(){ document.title='Google Enter VALUE:'+input.value; pushEvent('IN:'+input.value); },true);"
                b"captureState();"
                b"</script>"
                b"</main></body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.startswith("/submitted.html"):
            sys.stderr.write("FORM_SUBMIT " + self.path + "\n")
            sys.stderr.flush()
            parsed = urllib.parse.urlparse(self.path)
            params = urllib.parse.parse_qs(parsed.query)
            name = params.get("name", [""])[0]
            query = params.get("q", [""])[0]
            submit_phase = params.get("submit_phase", [""])[0]
            event_log = params.get("event_log", [""])[0]
            active_name = params.get("active_name", [""])[0] or "-"
            active_id = params.get("active_id", [""])[0] or "-"
            selection_start = params.get("selection_start", [""])[0] or "-"
            selection_end = params.get("selection_end", [""])[0] or "-"
            if query or submit_phase or event_log:
                sys.stderr.write(
                    "GOOGLE_ENTER_SUBMIT q=%s phase=%s active_name=%s active_id=%s selection=%s-%s events=%s\n"
                    % (query, submit_phase, active_name, active_id, selection_start, selection_end, event_log)
                )
                sys.stderr.flush()
            value = name or query
            title = f"Submitted {value}".encode("utf-8")
            body = (
                b"<!doctype html><html><head><meta charset=\"utf-8\"><title>"
                + title
                + b"</title></head><body><h1>Submitted</h1></body></html>"
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
    host = sys.argv[2] if len(sys.argv) > 2 else "127.0.0.1"
    with socketserver.TCPServer((host, port), FormHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
