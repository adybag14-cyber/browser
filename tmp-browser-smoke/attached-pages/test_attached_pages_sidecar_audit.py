import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import attached_pages_sidecar_audit as sidecar_audit


class AttachedPagesSidecarAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_detects_missing_sidecar_directory_and_counts_referenced_assets(self):
        page_name = "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War"
        html_path = self.root / f"{page_name}.html"
        html_path.write_text(
            f"""<!doctype html>
<html>
  <head>
    <link rel=\"stylesheet\" href=\"./{page_name}_files/ufo2.css\">
    <script src=\"./{page_name}_files/jquery.dataTables.min.js.download\"></script>
  </head>
  <body>
    <img src=\"./{page_name}_files/hero.jpg\">
  </body>
</html>
""",
            encoding="utf-8",
        )

        audit = sidecar_audit.build_sidecar_audit(self.root)
        self.assertEqual(1, audit["fixture_count"])
        self.assertEqual(1, audit["fixtures_with_missing_sidecars"])
        fixture = audit["fixtures"][0]
        self.assertEqual(1, fixture["sidecar_directory_count"])
        self.assertEqual(1, fixture["missing_sidecar_directory_count"])
        sidecar = fixture["missing_sidecar_directories"][0]
        self.assertEqual(f"{page_name}_files", sidecar["sidecar_dir"])
        self.assertFalse(sidecar["exists"])
        self.assertEqual(3, sidecar["referenced_asset_count"])

    def test_present_sidecar_directory_reports_success(self):
        html_path = self.root / "bundle.html"
        sidecar_dir = self.root / "bundle_files"
        sidecar_dir.mkdir()
        (sidecar_dir / "shared.css").write_text("body { color: blue; }\n", encoding="utf-8")
        html_path.write_text(
            """<!doctype html>
<html>
  <head>
    <link rel=\"stylesheet\" href=\"./bundle_files/shared.css\">
  </head>
  <body>ok</body>
</html>
""",
            encoding="utf-8",
        )

        audit = sidecar_audit.build_sidecar_audit(self.root)
        self.assertEqual(0, audit["fixtures_with_missing_sidecars"])
        fixture = audit["fixtures"][0]
        self.assertEqual(1, fixture["sidecar_directory_count"])
        self.assertEqual([], fixture["missing_sidecar_directories"])
        self.assertEqual("bundle_files", fixture["sidecar_directories"][0]["sidecar_dir"])

    def test_text_report_surfaces_missing_sidecar_summary(self):
        html_path = self.root / "bundle.html"
        html_path.write_text(
            """<!doctype html>
<html>
  <head>
    <link rel=\"stylesheet\" href=\"./bundle_files/shared.css\">
  </head>
</html>
""",
            encoding="utf-8",
        )

        audit = sidecar_audit.build_sidecar_audit(self.root)
        report = sidecar_audit.render_text_report(audit)
        self.assertIn("Attached Pages Sidecar Audit", report)
        self.assertIn("Fixtures with missing sidecars: 1", report)
        self.assertIn("bundle_files (missing, referenced assets: 1)", report)

    def test_cli_json_output_and_exit_codes(self):
        html_path = self.root / "bundle.html"
        html_path.write_text(
            """<!doctype html>
<html>
  <head>
    <script src=\"./bundle_files/app.js\"></script>
  </head>
</html>
""",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [str(Path(sidecar_audit.__file__)), "--root", str(self.root), "--json"]
            with contextlib.redirect_stdout(buffer):
                exit_code = sidecar_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(buffer.getvalue())
        self.assertEqual(1, payload["fixtures_with_missing_sidecars"])

        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(sidecar_audit.__file__)),
                "--root",
                str(self.root),
                "--allow-missing-sidecars",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = sidecar_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)


if __name__ == "__main__":
    unittest.main()