from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_startup_target_classification_audit import EXPECTATIONS, audit


class HeadedStartupTargetClassificationAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            combined = "\n".join(expectation["snippet"] for expectation in EXPECTATIONS)
            self.write_repo_file(repo_root, "src/main.zig", combined)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            combined = "\n".join(expectation["snippet"] for expectation in EXPECTATIONS[1:])
            self.write_repo_file(repo_root, "src/main.zig", combined)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_main_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_internal_local_and_loopback_coverage(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "browser_downloads_internal_test",
                "dotted_bare_local_html_test",
                "scheme_less_localhost_test",
                "scheme_less_remote_test",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()