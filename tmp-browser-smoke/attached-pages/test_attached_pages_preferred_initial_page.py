import tempfile
import unittest
from pathlib import Path

import attached_pages_preflight_report as preflight_module


class AttachedPagesPreferredInitialPageTests(unittest.TestCase):
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

    def test_preflight_respects_preferred_initial_page_override_under_google_style(self):
        self.write_file(
            "google-search-home.html",
            """<!doctype html>
<html>
  <head><title>Google Search Home</title></head>
  <body>
    <form action="/search">
      <input name="q" aria-label="Search">
    </form>
  </body>
</html>
""",
        )
        self.write_file(
            "preferred-lab.html",
            """<!doctype html>
<html>
  <head><title>Fixture Notes</title></head>
  <body>lab probe</body>
</html>
""",
        )

        report = preflight_module.build_preflight_report(
            self.repo_root,
            explicit_inputs=[str(self.bundle_root)],
            google_style=True,
            preferred_initial_page="preferred-lab.html",
            bind="127.0.0.1",
            port=9450,
        )

        self.assertTrue(report["ready_for_launch"])
        self.assertEqual("preferred-lab.html", report["preferred_display_path"])
        self.assertEqual(str(self.bundle_root / "preferred-lab.html"), report["selected_fixtures"][0])
        self.assertEqual("http://127.0.0.1:9450/pages/1/", report["preferred_url"])
        self.assertIn("--preferred-initial-page preferred-lab.html", report["command_hints"]["launch_command"])
        self.assertEqual(report["command_hints"]["launch_command"], report["recommended_command"])

    def test_exit_code_can_allow_missing_sidecar_bundles(self):
        self.write_file(
            "google-search-home.html",
            """<!doctype html>
<html>
  <head>
    <title>Google Search Home</title>
    <link rel="stylesheet" href="./google-search-home_files/theme.css">
  </head>
  <body>
    <form action="/search">
      <input name="q" aria-label="Search">
    </form>
  </body>
</html>
""",
        )

        report = preflight_module.build_preflight_report(
            self.repo_root,
            explicit_inputs=[str(self.bundle_root)],
            google_style=True,
        )

        self.assertEqual(1, report["missing_sidecar_fixture_count"])
        self.assertEqual("restore-missing-sidecar-bundles", report["recommended_next_step"])
        self.assertEqual(1, preflight_module.exit_code_for_report(report))
        self.assertEqual(0, preflight_module.exit_code_for_report(report, allow_missing_sidecars=True))


if __name__ == "__main__":
    unittest.main()
