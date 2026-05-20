import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_pages_launcher_companion_audit as helper


class GoogleIssue3AttachedPagesLauncherCompanionMissingRootTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_cli_json_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])
        self.assertIsNone(payload["missing_count"])
        self.assertIn("repo root does not exist:", payload["error"])

    def test_cli_text_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Google Issue #3 Attached-Pages Launcher Companion Audit", report)
        self.assertIn(f"Repo root: {missing_root}", report)
        self.assertIn("Error: repo root does not exist:", report)


if __name__ == "__main__":
    unittest.main()
