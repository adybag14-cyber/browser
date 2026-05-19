import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import attached_pages_preflight_report as preflight_module


class AttachedPagesPreflightReportTests(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parents[2]
        self.tempdir = tempfile.TemporaryDirectory()
        self.bundle_root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def write_file(self, relative_path: str, content: str) -> Path:
        path = self.bundle_root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def test_google_style_preflight_surfaces_full_localhost_urls(self):
        self.write_file(
            "google-search.html",
            """<!doctype html>
<html>
  <head>
    <title>Google Search Home</title>
  </head>
  <body>
    <form action="/search">
      <input name="q" aria-label="Search">
    </form>
  </body>
</html>
""",
        )
        self.write_file(
            "notes.html",
            """<!doctype html>
<html>
  <head><title>Fixture Notes</title></head>
  <body>fixture notes</body>
</html>
""",
        )

        report = preflight_module.build_preflight_report(
            self.repo_root,
            explicit_inputs=[str(self.bundle_root)],
            google_style=True,
            bind="127.0.0.1",
            port=9123,
        )

        self.assertTrue(report["ready_for_launch"])
        self.assertEqual("print-manifest-or-start-server", report["recommended_next_step"])
        self.assertEqual("google-search.html", report["preferred_display_path"])
        self.assertEqual("http://127.0.0.1:9123/", report["catalog_url"])
        self.assertEqual("http://127.0.0.1:9123/manifest.json", report["manifest_url"])
        self.assertEqual("http://127.0.0.1:9123/audit.json", report["audit_json_url"])
        self.assertEqual("http://127.0.0.1:9123/audit.txt", report["audit_text_url"])
        self.assertEqual("http://127.0.0.1:9123/pages/1/", report["preferred_url"])
        self.assertTrue(report["preferred_alias_url"].startswith("http://127.0.0.1:9123/pages/1-google-search-home"))
        self.assertEqual("http://127.0.0.1:9123/named/google-search-home/", report["preferred_named_url"])

        rendered = preflight_module.render_text_report(report)
        self.assertIn("Catalog URL: http://127.0.0.1:9123/", rendered)
        self.assertIn("Preferred URL: http://127.0.0.1:9123/pages/1/", rendered)
        self.assertIn("Preferred named URL: http://127.0.0.1:9123/named/google-search-home/", rendered)

    def test_preflight_recommends_restoring_missing_local_assets_before_launch(self):
        self.write_file(
            "google-search.html",
            """<!doctype html>
<html>
  <head>
    <title>Google Search Home</title>
    <link rel="stylesheet" href="./google-search_files/theme.css">
  </head>
  <body>
    <form action="/search">
      <input name="q" aria-label="Search">
    </form>
  </body>
</html>
""",
        )
        self.write_file(
            "google-search_files/theme.css",
            "body { background: url('./missing-bg.png'); }\n",
        )

        report = preflight_module.build_preflight_report(
            self.repo_root,
            explicit_inputs=[str(self.bundle_root)],
            google_style=True,
            bind="0.0.0.0",
            port=8235,
        )

        self.assertFalse(report["ready_for_launch"])
        self.assertEqual(0, report["missing_sidecar_fixture_count"])
        self.assertEqual(1, report["missing_asset_fixture_count"])
        self.assertEqual("restore-missing-local-assets", report["recommended_next_step"])
        self.assertEqual(1, preflight_module.exit_code_for_report(report))
        self.assertEqual(0, preflight_module.exit_code_for_report(report, allow_missing_assets=True))

        rendered = preflight_module.render_text_report(report)
        self.assertIn("Recommended next step: restore-missing-local-assets", rendered)
        self.assertIn("Catalog URL: http://0.0.0.0:8235/", rendered)

    def test_main_json_output_includes_route_urls(self):
        page_path = self.write_file(
            "google-search.html",
            """<!doctype html>
<html>
  <head>
    <title>Google Search Home</title>
  </head>
  <body>
    <form action="/search">
      <input name="q" aria-label="Search">
    </form>
  </body>
</html>
""",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = preflight_module.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--input",
                    str(page_path),
                    "--google-style",
                    "--bind",
                    "127.0.0.1",
                    "--port",
                    "9001",
                    "--json",
                ]
            )

        self.assertEqual(0, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("http://127.0.0.1:9001/", payload["catalog_url"])
        self.assertEqual("http://127.0.0.1:9001/pages/1/", payload["preferred_url"])
        self.assertEqual("http://127.0.0.1:9001/named/google-search-home/", payload["preferred_named_url"])


if __name__ == "__main__":
    unittest.main()
