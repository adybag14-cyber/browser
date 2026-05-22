import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import attached_pages_sidecar_audit as audit_module


class AttachedPagesSidecarAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def write_html(self, relative_path: str, content: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def test_present_and_missing_sidecars_are_reported(self):
        page = self.write_html(
            "bundle/google-search.html",
            """<!doctype html>
<html>
  <head>
    <title>Google Search</title>
    <link rel="stylesheet" href="./google-search_files/theme.css">
  </head>
  <body><img src="./missing-export_files/logo.png"></body>
</html>
""",
        )
        (page.parent / "google-search_files").mkdir()

        audit = audit_module.build_sidecar_audit(page.parent)
        self.assertEqual(1, audit["fixture_count"])
        self.assertEqual(1, audit["fixtures_with_missing_sidecars"])
        self.assertEqual(1, audit["missing_sidecar_path_count"])

        fixture = audit["fixtures"][0]
        self.assertEqual("google-search.html", fixture["display_path"])
        self.assertEqual(2, fixture["sidecar_directory_count"])

        present_entry = next(entry for entry in fixture["sidecar_directories"] if entry["sidecar_dir"] == "google-search_files")
        self.assertTrue(present_entry["exists"])
        self.assertEqual(["theme.css"], present_entry["sample_assets"])

        missing_entry = next(entry for entry in fixture["sidecar_directories"] if entry["sidecar_dir"] == "missing-export_files")
        self.assertFalse(missing_entry["exists"])
        self.assertEqual(["logo.png"], missing_entry["sample_assets"])

        summary = audit["missing_sidecar_paths"][0]
        self.assertEqual("missing-export_files", summary["sidecar_dir"])
        self.assertEqual(1, summary["missing_fixture_count"])
        self.assertEqual("google-search.html", summary["first_missing_fixture"])
        self.assertEqual(["logo.png"], summary["sample_assets"])

    def test_srcset_and_css_urls_expand_into_individual_assets(self):
        page = self.write_html(
            "bundle/export.html",
            """<!doctype html>
<html>
  <head>
    <title>Export</title>
    <style>
      body { background-image: url('./export_files/bg.png'); }
      @import "./export_files/theme.css";
    </style>
  </head>
  <body>
    <img srcset="./export_files/one.png 1x, ./export_files/two.png 2x">
  </body>
</html>
""",
        )
        (page.parent / "export_files").mkdir()

        audit = audit_module.build_sidecar_audit(page.parent)
        fixture = audit["fixtures"][0]
        entry = fixture["sidecar_directories"][0]
        self.assertTrue(entry["exists"])
        self.assertEqual(4, entry["referenced_asset_count"])
        self.assertEqual(
            ["bg.png", "one.png", "theme.css", "two.png"],
            entry["sample_assets"],
        )

    def test_root_relative_sidecar_paths_resolve_from_bundle_root(self):
        page = self.write_html(
            "bundle/nested/export.html",
            """<!doctype html>
<html>
  <head>
    <title>Nested Export</title>
    <link rel="stylesheet" href="/shared/export_files/theme.css">
  </head>
  <body>nested</body>
</html>
""",
        )
        (self.root / "bundle" / "shared" / "export_files").mkdir(parents=True)

        audit = audit_module.build_sidecar_audit(self.root / "bundle")
        fixture = audit["fixtures"][0]
        entry = fixture["sidecar_directories"][0]
        self.assertTrue(entry["exists"])
        self.assertEqual("shared/export_files", entry["reference_dir"])

    def test_explicit_selected_files_keep_single_fixture_scope(self):
        first = self.write_html(
            "bundle/first.html",
            """<!doctype html><html><body>first</body></html>""",
        )
        self.write_html(
            "bundle/second.html",
            """<!doctype html><html><body><img src="./second_files/a.png"></body></html>""",
        )

        audit = audit_module.build_sidecar_audit(selected_files=[first])
        self.assertEqual(1, audit["fixture_count"])
        self.assertEqual("first.html", audit["fixtures"][0]["display_path"])

    def test_missing_sidecar_summary_groups_shared_root_relative_path(self):
        self.write_html(
            "bundle/nested/first.html",
            """<!doctype html>
<html>
  <head><link rel="stylesheet" href="/shared/export_files/alpha.css"></head>
  <body>first</body>
</html>
""",
        )
        self.write_html(
            "bundle/deeper/second.html",
            """<!doctype html>
<html>
  <body><img src="/shared/export_files/beta.png"></body>
</html>
""",
        )

        audit = audit_module.build_sidecar_audit(self.root / "bundle")
        self.assertEqual(2, audit["fixtures_with_missing_sidecars"])
        self.assertEqual(1, audit["missing_sidecar_path_count"])

        summary = audit["missing_sidecar_paths"][0]
        self.assertTrue(summary["expected_path"].endswith("/bundle/shared/export_files"))
        self.assertEqual(2, summary["missing_fixture_count"])
        self.assertEqual("deeper/second.html", summary["first_missing_fixture"])
        self.assertEqual(["alpha.css", "beta.png"], summary["sample_assets"])

    def test_selected_files_group_shared_missing_root_relative_path(self):
        first = self.write_html(
            "bundle/nested/first.html",
            """<!doctype html>
<html>
  <head><link rel="stylesheet" href="/shared/export_files/alpha.css"></head>
  <body>first</body>
</html>
""",
        )
        second = self.write_html(
            "bundle/deeper/second.html",
            """<!doctype html>
<html>
  <body><img src="/shared/export_files/beta.png"></body>
</html>
""",
        )

        audit = audit_module.build_sidecar_audit(selected_files=[first, second])
        self.assertEqual(2, audit["fixture_count"])
        self.assertEqual(2, audit["fixtures_with_missing_sidecars"])
        self.assertEqual(1, audit["missing_sidecar_path_count"])
        self.assertTrue(audit["bundle_root"].endswith("/bundle"))

        summary = audit["missing_sidecar_paths"][0]
        self.assertTrue(summary["expected_path"].endswith("/bundle/shared/export_files"))
        self.assertEqual(2, summary["missing_fixture_count"])
        self.assertEqual("deeper/second.html", summary["first_missing_fixture"])
        self.assertEqual(["alpha.css", "beta.png"], summary["sample_assets"])

    def test_selected_files_deduplicate_duplicate_inputs(self):
        page = self.write_html(
            "bundle/first.html",
            """<!doctype html><html><body><img src="./first_files/logo.png"></body></html>""",
        )

        audit = audit_module.build_sidecar_audit(selected_files=[page, page])
        self.assertEqual(1, audit["fixture_count"])
        self.assertEqual("first.html", audit["fixtures"][0]["display_path"])
        self.assertEqual(1, audit["fixtures_with_missing_sidecars"])
        self.assertEqual(1, audit["missing_sidecar_path_count"])

    def test_cli_json_and_allow_missing_sidecars(self):
        self.write_html(
            "bundle/export.html",
            """<!doctype html>
<html>
  <body><img src="./export_files/logo.png"></body>
</html>
""",
        )

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--root",
                str(self.root / "bundle"),
                "--json",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(1, payload["fixtures_with_missing_sidecars"])
        self.assertEqual(1, payload["missing_sidecar_path_count"])
        self.assertEqual("export.html", payload["missing_sidecar_paths"][0]["first_missing_fixture"])
        self.assertEqual(["logo.png"], payload["missing_sidecar_paths"][0]["sample_assets"])

        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--root",
                str(self.root / "bundle"),
                "--allow-missing-sidecars",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertIn("Fixtures with missing sidecars: 1", stdout.getvalue())
        self.assertIn("Missing sidecar paths:", stdout.getvalue())

    def test_cli_json_reports_missing_repo_root_cleanly(self):
        missing_root = self.root / "missing-bundle"

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--root",
                str(missing_root),
                "--json",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(0, payload["fixture_count"])
        self.assertEqual(0, payload["missing_sidecar_path_count"])
        self.assertTrue(payload["bundle_root"].endswith("missing-bundle"))
        self.assertIn("bundle root does not exist", payload["error"])

    def test_cli_text_reports_missing_repo_root_cleanly(self):
        missing_root = self.root / "missing-bundle"

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--root",
                str(missing_root),
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Attached Pages Sidecar Audit", report)
        self.assertIn("Error: repo_root_not_found", report)
        self.assertIn("bundle root does not exist", report)

    def test_cli_json_reports_invalid_selected_input_cleanly(self):
        invalid_input = self.root / "bundle" / "notes.txt"
        invalid_input.parent.mkdir(parents=True, exist_ok=True)
        invalid_input.write_text("not html", encoding="utf-8")

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--input",
                str(invalid_input),
                "--json",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("invalid_input", payload["error_type"])
        self.assertEqual(0, payload["fixture_count"])
        self.assertTrue(payload["bundle_root"].endswith("notes.txt"))
        self.assertIn("selected file is not an attached HTML export", payload["error"])

    def test_cli_text_reports_invalid_selected_input_cleanly(self):
        invalid_input = self.root / "bundle" / "notes.txt"
        invalid_input.parent.mkdir(parents=True, exist_ok=True)
        invalid_input.write_text("not html", encoding="utf-8")

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--input",
                str(invalid_input),
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Attached Pages Sidecar Audit", report)
        self.assertIn("Error: invalid_input", report)
        self.assertIn("selected file is not an attached HTML export", report)

    def test_cli_json_reports_missing_selected_input_cleanly(self):
        missing_input = self.root / "bundle" / "missing.html"

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--input",
                str(missing_input),
                "--json",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(0, payload["fixture_count"])
        self.assertTrue(payload["bundle_root"].endswith("missing.html"))
        self.assertIn("selected HTML file does not exist", payload["error"])

    def test_cli_text_reports_missing_selected_input_cleanly(self):
        missing_input = self.root / "bundle" / "missing.html"

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(audit_module.__file__)),
                "--input",
                str(missing_input),
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = audit_module.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Attached Pages Sidecar Audit", report)
        self.assertIn("Error: repo_root_not_found", report)
        self.assertIn("selected HTML file does not exist", report)


if __name__ == "__main__":
    unittest.main()
