from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from browse_runtime_lifecycle_diagnostics_audit import EXPECTATIONS, SOURCE_PATH, audit


class BrowseRuntimeLifecycleDiagnosticsAuditTests(unittest.TestCase):
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

    def test_audit_keeps_failure_and_finish_diagnostics_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "browse_error_log_present",
                "browse_finished_log_present",
                "browse_error_logs_navigation_state",
                "browse_finished_logs_navigation_state",
                "browse_error_logs_dynamic_screenshot_status",
                "browse_finished_logs_dynamic_png_status",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()