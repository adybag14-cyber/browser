import tempfile
import unittest
from pathlib import Path

import attached_pages_server as server_module


class AttachedPagesServerWorkerAuditTests(unittest.TestCase):
    def test_asset_audit_follows_worker_service_worker_and_importscripts_references(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "index.html").write_text(
                """<!doctype html>
<html>
  <head>
    <title>Worker Probe</title>
    <script src="app.js"></script>
  </head>
  <body>worker assets</body>
</html>
""",
                encoding="utf-8",
            )
            (root / "app.js").write_text(
                """
const worker = new Worker('./worker.js');
const sharedWorker = new SharedWorker('./shared-worker.js');
navigator.serviceWorker.register('./sw.js');
""",
                encoding="utf-8",
            )
            (root / "worker.js").write_text(
                "importScripts('./worker-helper.js', './missing-worker-helper.js');\n",
                encoding="utf-8",
            )
            (root / "worker-helper.js").write_text(
                "self.workerHelperReady = true;\n",
                encoding="utf-8",
            )
            (root / "shared-worker.js").write_text(
                "importScripts('https://cdn.example.test/shared-worker-helper.js');\n",
                encoding="utf-8",
            )
            (root / "sw.js").write_text(
                "importScripts('./sw-helper.js');\n",
                encoding="utf-8",
            )
            (root / "sw-helper.js").write_text(
                "self.swHelperReady = true;\n",
                encoding="utf-8",
            )

            audit = server_module.build_asset_audit(root)

        self.assertEqual(1, audit["fixture_count"])
        self.assertEqual(1, audit["fixtures_with_missing_assets"])
        self.assertEqual(1, audit["fixtures_with_external_assets"])

        fixture = audit["fixtures"][0]
        self.assertIn("missing-worker-helper.js", "".join(fixture["missing_assets"]))
        self.assertIn("https://cdn.example.test/shared-worker-helper.js", fixture["external_assets"])
        for expected in [
            "app.js",
            "worker.js",
            "worker-helper.js",
            "shared-worker.js",
            "sw.js",
            "sw-helper.js",
        ]:
            self.assertIn(expected, fixture["inspected_module_script_files"])


if __name__ == "__main__":
    unittest.main()
