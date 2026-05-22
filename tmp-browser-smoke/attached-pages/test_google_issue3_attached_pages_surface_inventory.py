import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_attached_pages_surface_inventory as helper


class GoogleIssue3AttachedPagesSurfaceInventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name)
        self.attached_pages_dir = self.repo_root / "tmp-browser-smoke" / "attached-pages"
        self.attached_pages_dir.mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_file(self, relative_path: str) -> None:
        path = self.repo_root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("# fixture\n", encoding="utf-8")

    def test_inventory_pairs_helpers_with_matching_tests(self) -> None:
        self.write_file(
            "tmp-browser-smoke/attached-pages/google_issue3_windows_replay_attached_html_quickstart_audit.py"
        )
        self.write_file(
            "tmp-browser-smoke/attached-pages/test_google_issue3_windows_replay_attached_html_quickstart_audit.py"
        )

        inventory = helper.build_attached_pages_surface_inventory(self.repo_root)

        self.assertEqual(1, inventory["surface_count"])
        self.assertEqual(1, inventory["paired_surface_count"])
        self.assertEqual(0, inventory["missing_pair_count"])
        self.assertEqual([], inventory["create_only_safe_candidates"])
        self.assertEqual("paired", inventory["surfaces"][0]["status"])

    def test_inventory_recommends_missing_test_path_for_helper_only_surface(self) -> None:
        self.write_file(
            "tmp-browser-smoke/attached-pages/google_issue3_attached_pages_launcher_companion_audit.py"
        )

        inventory = helper.build_attached_pages_surface_inventory(self.repo_root)

        self.assertEqual(1, inventory["surface_count"])
        self.assertEqual(0, inventory["paired_surface_count"])
        self.assertEqual(1, inventory["missing_pair_count"])
        self.assertEqual(
            [
                "tmp-browser-smoke/attached-pages/"
                "test_google_issue3_attached_pages_launcher_companion_audit.py"
            ],
            inventory["create_only_safe_candidates"],
        )
        self.assertEqual("missing_test", inventory["surfaces"][0]["status"])

    def test_render_text_report_includes_create_only_candidates(self) -> None:
        self.write_file(
            "tmp-browser-smoke/attached-pages/test_google_issue3_windows_replay_attached_html_quickstart_audit.py"
        )

        inventory = helper.build_attached_pages_surface_inventory(self.repo_root)
        report = helper.render_text_report(inventory)

        self.assertIn("Create-only safe candidates:", report)
        self.assertIn(
            "tmp-browser-smoke/attached-pages/"
            "google_issue3_windows_replay_attached_html_quickstart_audit.py",
            report,
        )

    def test_main_reports_missing_repo_root_in_json(self) -> None:
        missing_root = self.repo_root / "missing"
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        self.assertIn('"error_type": "repo_root_not_found"', output.getvalue())
        self.assertIn(str(missing_root), output.getvalue())


if __name__ == "__main__":
    unittest.main()