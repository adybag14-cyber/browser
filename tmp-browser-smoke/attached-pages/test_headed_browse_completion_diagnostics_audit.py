from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_browse_completion_diagnostics_audit import EXPECTATIONS, SOURCE_PATH, audit


class HeadedBrowseCompletionDiagnosticsAuditTests(unittest.TestCase):
    def write_source(self, repo_root: Path, content: str) -> None:
        target = repo_root / SOURCE_PATH
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(expectation["snippet"] for expectation in EXPECTATIONS)
            self.write_source(repo_root, content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(
                expectation["snippet"] for expectation in EXPECTATIONS[1:]
            )
            self.write_source(repo_root, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_source_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_runtime_fallback_and_completion_surface_covered(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "browse_headed_runtime_log",
                "browse_headed_fallback_log",
                "browse_error_log",
                "browse_finished_log",
                "completion_navigation_state_field",
                "completion_navigation_seen_field",
                "completion_loading_field",
                "screenshot_bmp_status_field",
                "screenshot_png_status_field",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
