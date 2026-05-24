from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_storage_common_launch_audit import EXPECTATIONS, audit


class HeadedStorageCommonLaunchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in EXPECTATIONS:
                self.write_repo_file(repo_root, expectation["path"], expectation["snippet"])

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(repo_root, EXPECTATIONS[0]["path"], "# missing headed launch")
            self.write_repo_file(repo_root, EXPECTATIONS[1]["path"], EXPECTATIONS[1]["snippet"])

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])
            self.assertTrue(result["checks"][1]["present"])

    def test_audit_reports_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            for check in result["checks"]:
                self.assertFalse(check["exists"])
                self.assertFalse(check["present"])

    def test_audit_keeps_both_shared_storage_helpers_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {"indexeddb_headed_launch", "sessionstorage_headed_launch"},
            covered_labels,
        )


if __name__ == "__main__":
    unittest.main()