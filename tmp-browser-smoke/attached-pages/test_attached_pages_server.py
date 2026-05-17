import contextlib
import http.client
import io
import json
import sys
import tempfile
import threading
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

    def test_single_file_root_preserves_assets_and_manifest(self):
        single_root = self.root / "nested" / "beta.html"
        manifest = server_module.build_manifest(single_root)
        self.assertEqual(1, len(manifest))
        self.assertEqual("beta.html", manifest[0]["file"])
        self.assertEqual("/raw/beta.html", manifest[0]["raw_path"])

        server, _ = server_module.create_server(single_root, bind="127.0.0.1", port=0)
        port = server.server_address[1]
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            connection = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
            try:
                connection.request("GET", "/pages/1/beta.js")
                response = connection.getresponse()
                self.assertEqual(200, response.status)
                self.assertIn("betaLoaded", response.read().decode("utf-8"))
            finally:
                connection.close()
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)

    def test_explicit_file_list_pins_manifest_to_selected_inputs(self):
        selected_files = [self.root / "nested" / "beta.html"]
        manifest = server_module.build_manifest(selected_files=selected_files)
        self.assertEqual(1, len(manifest))
        self.assertEqual("beta.html", manifest[0]["file"])
        self.assertEqual("/named/alpha-landing", manifest[0]["slug_route"])

        server, manifest = server_module.create_server(selected_files=selected_files, bind="127.0.0.1", port=0)
        self.assertEqual(1, len(manifest))
        port = server.server_address[1]
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            connection = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
            try:
                connection.request("GET", "/manifest.json")
                response = connection.getresponse()
                self.assertEqual(200, response.status)
                payload = json.loads(response.read().decode("utf-8"))
                self.assertEqual(1, len(payload))
                self.assertEqual("beta.html", payload[0]["file"])
            finally:
                connection.close()
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)

    def test_print_manifest_with_explicit_file_list_outputs_only_selected_files(self):
        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--input",
                str(self.root / "nested" / "beta.html"),
                "--print-manifest",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        manifest = json.loads(buffer.getvalue())
        self.assertEqual(1, len(manifest))
        self.assertEqual("beta.html", manifest[0]["file"])

    def test_asset_audit_detects_missing_assets_and_follows_nested_references(self):
        (self.root / "nested" / "beta.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Alpha Landing</title>
    <script type="module" src="beta.js"></script>
    <link rel="stylesheet" href="beta.css">
  </head>
  <body><img src="missing.png"></body>
</html>
""",
            encoding="utf-8",
        )
        (self.root / "nested" / "beta.js").write_text("import './module.mjs';\n", encoding="utf-8")
        (self.root / "nested" / "module.mjs").write_text("import './missing-module.js';\n", encoding="utf-8")
        (self.root / "nested" / "beta.css").write_text("@import './theme.css';\n", encoding="utf-8")
        (self.root / "nested" / "theme.css").write_text("body { background: url('./missing-bg.png'); }\n", encoding="utf-8")

        audit = server_module.build_asset_audit(self.root)
        self.assertEqual(2, audit["fixture_count"])
        self.assertEqual(1, audit["fixtures_with_missing_assets"])

        beta_entry = next(entry for entry in audit["fixtures"] if entry["display_path"] == "nested/beta.html")
        self.assertIn("nested/missing.png", beta_entry["missing_assets"])
        self.assertIn("nested/missing-module.js", beta_entry["missing_assets"])
        self.assertIn("nested/missing-bg.png", beta_entry["missing_assets"])
        self.assertIn("nested/theme.css", beta_entry["inspected_css_files"])
        self.assertIn("nested/module.mjs", beta_entry["inspected_module_script_files"])

    def test_asset_audit_cli_exit_codes_and_allow_missing_flag(self):
        (self.root / "alpha.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Alpha Landing</title>
    <link rel="stylesheet" href="missing.css">
  </head>
  <body>alpha</body>
</html>
""",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--root",
                str(self.root),
                "--audit-assets",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        self.assertIn("Fixtures with missing assets: 1", buffer.getvalue())

        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--root",
                str(self.root),
                "--audit-assets",
                "--allow-missing-assets",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)

    def test_asset_audit_cli_json_output(self):
        (self.root / "alpha.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Alpha Landing</title>
    <link rel="stylesheet" href="missing.css">
  </head>
  <body>alpha</body>
</html>
""",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--root",
                str(self.root),
                "--audit-assets",
                "--audit-assets-json",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        audit = json.loads(buffer.getvalue())
        self.assertEqual(2, audit["fixture_count"])
        self.assertEqual(1, audit["fixtures_with_missing_assets"])
        alpha_entry = next(entry for entry in audit["fixtures"] if entry["display_path"] == "alpha.html")
        self.assertIn("missing.css", alpha_entry["missing_assets"])

    def test_audit_assets_json_requires_audit_assets(self):
        original_argv = sys.argv[:]
        stderr = io.StringIO()
        try:
            sys.argv = [
                str(Path(server_module.__file__)),
                "--root",
                str(self.root),
                "--audit-assets-json",
            ]
            with contextlib.redirect_stderr(stderr):
                with self.assertRaises(SystemExit) as raised:
                    server_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(2, raised.exception.code)
        self.assertIn("--audit-assets-json requires --audit-assets", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()