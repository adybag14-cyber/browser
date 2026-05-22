import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_pages_launcher_companion_audit as helper


class GoogleIssue3AttachedPagesLauncherCompanionAuditTextReportTests(unittest.TestCase):
    def test_render_text_report_includes_missing_path_summary(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            audit = helper.build_launcher_companion_audit(Path(tempdir))

        self.assertGreater(audit["missing_count"], 0)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Attached-Pages Launcher Companion Audit", report)
        self.assertIn("Missing path summary:", report)
        self.assertIn(
            "- docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md:",
            report,
        )
        self.assertIn(
            "check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
            report,
        )

    def test_render_text_report_surfaces_repo_root_error(self) -> None:
        audit = helper.build_repo_root_error_audit(
            "/tmp/does-not-exist",
            "repo root does not exist: /tmp/does-not-exist",
        )

        report = helper.render_text_report(audit)

        self.assertIn("Repo root: /tmp/does-not-exist", report)
        self.assertIn("Error: repo root does not exist: /tmp/does-not-exist", report)
        self.assertNotIn("Missing path summary:", report)

    def test_cli_text_output_returns_nonzero_for_missing_repo_root(self) -> None:
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", "/tmp/does-not-exist"])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Google Issue #3 Attached-Pages Launcher Companion Audit", report)
        self.assertIn("Repo root: /tmp/does-not-exist", report)
        self.assertIn("Error: repo root does not exist: /tmp/does-not-exist", report)


if __name__ == "__main__":
    unittest.main()
