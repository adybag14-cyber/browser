import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import attached_pages_missing_sidecar_summary as summary_helper


class AttachedPagesMissingSidecarSummaryTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_summarizes_only_fixtures_with_missing_sidecars(self):
        missing_page = self.root / "missing.html"
        missing_page.write_text(
            """<!doctype html>
<html>
  <head>
    <script src="./missing_files/app.js"></script>
    <link rel="stylesheet" href="./missing_files/app.css">
  </head>
</html>
""",
            encoding="utf-8",
        )
        present_page = self.root / "present.html"
        present_sidecar = self.root / "present_files"
        present_sidecar.mkdir()
        (present_sidecar / "ok.css").write_text("body{}\n", encoding="utf-8")
        present_page.write_text(
            """<!doctype html>
<html>
  <head><link rel="stylesheet" href="./present_files/ok.css"></head>
</html>
""",
            encoding="utf-8",
        )

        summary = summary_helper.build_missing_sidecar_summary(self.root)
        self.assertEqual(2, summary["fixture_count"])
        self.assertEqual(1, summary["fixtures_with_missing_sidecars"])
        self.assertEqual(1, len(summary["missing_fixtures"]))
        fixture = summary["missing_fixtures"][0]
        self.assertEqual("missing.html", fixture["display_path"])
        self.assertEqual(["missing_files"], fixture["missing_sidecar_dirs"])
        self.assertEqual(2, fixture["referenced_asset_count"])

    def test_text_report_says_when_everything_is_present(self):
        html_path = self.root / "bundle.html"
        sidecar_dir = self.root / "bundle_files"
        sidecar_dir.mkdir()
        (sidecar_dir / "shared.css").write_text("body{}\n", encoding="utf-8")
        html_path.write_text(
            """<!doctype html>
<html>
  <head><link rel="stylesheet" href="./bundle_files/shared.css"></head>
</html>
""",
            encoding="utf-8",
        )

        summary = summary_helper.build_missing_sidecar_summary(self.root)
        report = summary_helper.render_text_report(summary)
        self.assertIn("Fixtures with missing sidecars: 0", report)
        self.assertIn("All inspected fixtures still have their referenced sidecar directories.", report)

    def test_selected_input_list_keeps_summary_scoped(self):
        missing_page = self.root / "missing.html"
        missing_page.write_text(
            """<!doctype html>
<html><head><script src="./missing_files/app.js"></script></head></html>
""",
            encoding="utf-8",
        )
        ignored_page = self.root / "ignored.html"
        ignored_page.write_text(
            """<!doctype html>
<html><head><script src="./ignored_files/app.js"></script></head></html>
""",
            encoding="utf-8",
        )

        summary = summary_helper.build_missing_sidecar_summary(selected_files=[missing_page])
        self.assertEqual(1, summary["fixture_count"])
        self.assertEqual(1, len(summary["missing_fixtures"]))
        self.assertEqual("missing.html", summary["missing_fixtures"][0]["display_path"])

    def test_cli_json_output_and_exit_codes(self):
        html_path = self.root / "bundle.html"
        html_path.write_text(
            """<!doctype html>
<html><head><script src="./bundle_files/app.js"></script></head></html>
""",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        try:
            buffer = io.StringIO()
            sys.argv = [str(Path(summary_helper.__file__)), "--root", str(self.root), "--json"]
            with contextlib.redirect_stdout(buffer):
                exit_code = summary_helper.main()
            self.assertEqual(1, exit_code)
            payload = json.loads(buffer.getvalue())
            self.assertEqual(1, payload["fixtures_with_missing_sidecars"])

            buffer = io.StringIO()
            sys.argv = [
                str(Path(summary_helper.__file__)),
                "--root",
                str(self.root),
                "--allow-missing-sidecars",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = summary_helper.main()
            self.assertEqual(0, exit_code)
        finally:
            sys.argv = original_argv


if __name__ == "__main__":
    unittest.main()