import http.client
import json
import threading
import tempfile
import unittest
from pathlib import Path

import attached_pages_server as server_module


class AttachedPagesManifestOrderTests(unittest.TestCase):
    def request(self, port: int, path: str) -> tuple[int, bytes]:
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        try:
            connection.request("GET", path)
            response = connection.getresponse()
            return response.status, response.read()
        finally:
            connection.close()

    def test_explicit_file_list_preserves_selected_order_even_with_duplicate_leaf_names(self):
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            preferred_dir = root / "preferred"
            secondary_dir = root / "secondary"
            preferred_dir.mkdir()
            secondary_dir.mkdir()

            preferred = preferred_dir / "page.html"
            secondary = secondary_dir / "page.html"
            preferred.write_text(
                """<!doctype html>
<html>
  <head>
    <title>Preferred Google Page</title>
  </head>
  <body>preferred</body>
</html>
""",
                encoding="utf-8",
            )
            secondary.write_text(
                """<!doctype html>
<html>
  <head>
    <title>Secondary Page</title>
  </head>
  <body>secondary</body>
</html>
""",
                encoding="utf-8",
            )

            selected_files = [preferred, secondary, preferred]
            manifest = server_module.build_manifest(selected_files=selected_files)
            self.assertEqual(
                ["preferred/page.html", "secondary/page.html"],
                [entry["file"] for entry in manifest],
            )
            self.assertEqual("/pages/1", manifest[0]["route"])
            self.assertEqual("/pages/2", manifest[1]["route"])

            server, manifest = server_module.create_server(selected_files=selected_files, bind="127.0.0.1", port=0)
            port = server.server_address[1]
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                status, body = self.request(port, "/manifest.json")
                self.assertEqual(200, status)
                payload = json.loads(body.decode("utf-8"))
                self.assertEqual(
                    ["preferred/page.html", "secondary/page.html"],
                    [entry["file"] for entry in payload],
                )
                self.assertEqual("/pages/1", payload[0]["route"])
                self.assertEqual("/pages/2", payload[1]["route"])
            finally:
                server.shutdown()
                server.server_close()
                thread.join(timeout=5)


if __name__ == "__main__":
    unittest.main()
