import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import check_attached_pages_offline_readiness as checker_module


class AttachedPagesOfflineReadinessTests(unittest.TestCase):
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

    def tearDown(self):
        self.tempdir.cleanup()

    def run_checker(self, *args: str) -> tuple[int, str]:
        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [str(Path(checker_module.__file__)), *args]
            with contextlib.redirect_stdout(buffer):
                exit_code = checker_module.main()
        finally:
            sys.argv = original_argv
        return exit_code, buffer.getvalue()

    def test_offline_ready_bundle_returns_success(self):
        exit_code, output = self.run_checker("--root", str(self.root))
        self.assertEqual(0, exit_code)
        self.assertIn("Offline ready: yes", output)
        self.assertIn("Status: offline-ready", output)

    def test_external_assets_fail_offline_readiness(self):
        (self.root / "beta.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Beta Landing</title>
    <script src="https://cdn.example.test/app.js"></script>
  </head>
  <body>beta</body>
</html>
""",
            encoding="utf-8",
        )

        exit_code, output = self.run_checker("--root", str(self.root))
        self.assertEqual(1, exit_code)
        self.assertIn("Offline ready: no", output)
        self.assertIn("Fixtures with external assets: 1", output)
        self.assertIn("Status: needs-network", output)
        self.assertIn("https://cdn.example.test/app.js", output)

    def test_missing_local_assets_fail_offline_readiness(self):
        (self.root / "beta.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Beta Landing</title>
    <link rel="stylesheet" href="missing.css">
  </head>
  <body>beta</body>
</html>
""",
            encoding="utf-8",
        )

        exit_code, output = self.run_checker("--root", str(self.root))
        self.assertEqual(1, exit_code)
        self.assertIn("Fixtures with missing local assets: 1", output)
        self.assertIn("Status: missing-local-assets", output)
        self.assertIn("missing.css", output)

    def test_json_output_reports_combined_status(self):
        (self.root / "beta.html").write_text(
            """<!doctype html>
<html>
  <head>
    <title>Beta Landing</title>
    <link rel="stylesheet" href="missing.css">
    <script src="https://cdn.example.test/app.js"></script>
  </head>
  <body>beta</body>
</html>
""",
            encoding="utf-8",
        )

        exit_code, output = self.run_checker("--root", str(self.root), "--json")
        self.assertEqual(1, exit_code)
        payload = json.loads(output)
        self.assertFalse(payload["offline_ready"])
        beta_entry = next(entry for entry in payload["fixtures"] if entry["display_path"] == "beta.html")
        self.assertEqual("missing-local-assets-and-needs-network", beta_entry["status"])
        self.assertEqual(1, beta_entry["missing_asset_count"])
        self.assertEqual(1, beta_entry["external_asset_count"])


if __name__ == "__main__":
    unittest.main()
