import functools
import http.server
import socketserver
import sys


class LocalHtmlCompatHandler(http.server.SimpleHTTPRequestHandler):
    def _write_ping(self, include_body):
        body = b"ok"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if include_body:
            self.wfile.write(body)

    def do_GET(self):
        if self.path == "/ping":
            self._write_ping(True)
            return

        super().do_GET()

    def do_HEAD(self):
        if self.path == "/ping":
            self._write_ping(False)
            return

        super().do_HEAD()

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))
        sys.stderr.flush()


def main():
    port = int(sys.argv[1])
    host = sys.argv[2] if len(sys.argv) > 2 else "127.0.0.1"
    root = sys.argv[3] if len(sys.argv) > 3 else "."
    handler = functools.partial(LocalHtmlCompatHandler, directory=root)
    with socketserver.TCPServer((host, port), handler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
