from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_top_level_attached_html_surface_audit import (
    HELPER_EXPECTATIONS,
    NOTE_EXPECTATIONS,
    audit_helper_text,
    audit_note_text,
    audit_repo,
)


class Issue3TopLevelAttachedHtmlSurfaceAuditTests(unittest.TestCase):
    def test_note_audit_accepts_expected_surface(self) -> None:
        self.assertEqual([], audit_note_text("\n".join(NOTE_EXPECTATIONS)))

    def test_note_audit_reports_missing_surface(self) -> None:
        missing = audit_note_text(
            "\n".join(
                snippet
                for snippet in NOTE_EXPECTATIONS
                if "check_google_attached_html_validation_surface.ps1" not in snippet
            )
        )
        self.assertIn(
            "check_google_attached_html_validation_surface.ps1",
            "\n".join(missing),
        )

    def test_helper_audit_accepts_expected_surface(self) -> None:
        self.assertEqual([], audit_helper_text("\n".join(HELPER_EXPECTATIONS)))

    def test_helper_audit_reports_missing_surface(self) -> None:
        missing = audit_helper_text(
            "\n".join(
                snippet
                for snippet in HELPER_EXPECTATIONS
                if "google_issue3_attached_html_surface_check" not in snippet
            )
        )
        self.assertIn(
            "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
            missing,
        )

    def test_repo_audit_reads_note_and_helper_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            note_path = repo_root / "docs" / "ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md"
            helper_path = (
                repo_root
                / "scripts"
                / "windows"
                / "show_google_issue3_top_level_attached_html_quickstart.ps1"
            )
            note_path.parent.mkdir(parents=True, exist_ok=True)
            helper_path.parent.mkdir(parents=True, exist_ok=True)
            note_path.write_text("\n".join(NOTE_EXPECTATIONS), encoding="utf-8")
            helper_path.write_text("\n".join(HELPER_EXPECTATIONS), encoding="utf-8")

            self.assertEqual([], audit_repo(repo_root))


if __name__ == "__main__":
    unittest.main()
