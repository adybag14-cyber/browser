import contextlib
import http.client
import io
import json
import sys
import threading
import tempfile
import unittest
from pathlib import Path

import attached_pages_server as server_module


class AttachedPagesServerTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

        (self.root / "alpha.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Alpha Landing</title>
    <link rel="stylesheet" href="alpha.css">
  </head>
  <body>alpha</body>
</html>
""",
            encoding="utf-8",
        )
        (self.root / "alpha.css").write_text("body { color: red; }\n", encoding="utf-8")
        (self.root / "nested").mkdir()
        (self.root / "nested" / "beta.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Alpha Landing</title>
    <script src="beta.js"></script>
  </head>
  <body>beta</body>
</html>
""",
            encoding="utf-8",
        )
        (self.root / "nested" / "beta.js").write_text("window.betaLoaded = true;\n", encoding="utf-8")

        self.server, self.manifest = server_module.create_server(self.root, bind="127.0.0.1", port=0)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)
        self.tempdir.cleanup()

    def request(self, method: str, path: str) -> tuple[int, list[tuple[str, str]], bytes]:
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        try:
            connection.request(method, path)
            response = connection.getresponse()
            status = response.status
            headers = response.getheaders()
            body = response.read()
            return status, headers, body
        finally:
            connection.close()

    def test_manifest_uses_short_routes_unique_aliases_and_named_routes(self):
        self.assertEqual(2, len(self.manifest))
        self.assertEqual("/pages/1", self.manifest[0]["route"])
        self.assertTrue(self.manifest[0]["alias_route"].startswith("/pages/1-alpha-landing"))
        self.assertTrue(self.manifest[1]["alias_route"].startswith("/pages/2-alpha-landing"))
        self.assertEqual("/named/alpha-landing", self.manifest[0]["slug_route"])
        self.assertEqual("/named/alpha-landing-beta", self.manifest[1]["slug_route"])
        self.assertNotEqual(self.manifest[0]["alias_route"], self.manifest[1]["alias_route"])
        self.assertEqual("/raw/nested/beta.html", self.manifest[1]["raw_path"])

    def test_catalog_and_manifest_routes_respond(self):
        status, _, body = self.request("GET", "/")
        self.assertEqual(200, status)
        text = body.decode("utf-8")
        self.assertIn("Attached Pages Catalog", text)
        self.assertIn("/pages/1", text)
        self.assertIn("/pages/2-alpha-landing", text)
        self.assertIn("/named/alpha-landing-beta", text)

        status, headers, body = self.request("GET", "/manifest.json")
        self.assertEqual(200, status)
        header_map = dict(headers)
        self.assertEqual("no-store", header_map.get("Cache-Control"))
        manifest = json.loads(body.decode("utf-8"))
        self.assertEqual(self.manifest, manifest)

    def test_short_and_named_routes_redirect_and_serve_assets(self):
        status, headers, body = self.request("GET", "/pages/1")
        self.assertEqual(302, status)
        self.assertEqual(b"", body)
        self.assertEqual("/pages/1/", dict(headers).get("Location"))

        status, _, body = self.request("GET", "/pages/1/")
        self.assertEqual(200, status)
        self.assertIn("Alpha Landing", body.decode("utf-8"))

        status, _, body = self.request("GET", "/pages/1/alpha.css")
        self.assertEqual(200, status)
        self.assertEqual("body { color: red; }\n", body.decode("utf-8"))

        status, headers, body = self.request("GET", "/named/alpha-landing-beta")
        self.assertEqual(302, status)
        self.assertEqual("/named/alpha-landing-beta/", dict(headers).get("Location"))
        self.assertEqual(b"", body)

        status, _, body = self.request("GET", "/named/alpha-landing-beta/")
        self.assertEqual(200, status)
        self.assertIn("beta", body.decode("utf-8"))

        status, _, body = self.request("GET", "/named/alpha-landing-beta/beta.js")
        self.assertEqual(200, status)
        self.assertIn("betaLoaded", body.decode("utf-8"))

    def test_head_and_raw_routes_work(self):
        status, headers, body = self.request("HEAD", "/manifest.json")
        self.assertEqual(200, status)
        self.assertEqual(b"", body)
        self.assertEqual("no-store", dict(headers).get("Cache-Control"))

        status, _, body = self.request("GET", "/raw/nested/beta.html")
        self.assertEqual(200, status)
        self.assertIn("beta", body.decode("utf-8"))

    def test_print_manifest_outputs_json(self):
        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--root",
                str(self.root),
                "--print-manifest",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        manifest = json.loads(buffer.getvalue())
        self.assertEqual(self.manifest, manifest)


if __name__ == "__main__":
    unittest.main()