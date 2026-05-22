from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from linux_build_readiness_helper_audit import EXPECTATIONS, SOURCE_PATH, audit


class LinuxBuildReadinessHelperAuditTests(unittest.TestCase):
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

    def test_audit_keeps_dependency_and_cli_surfaces_covered(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "minimum_zig_parser",
                "v8_dependency_markers",
                "boringssl_dependency_markers",
                "skip_zig_check_flag",
                "self_test_flag",
                "branch_line_mismatch_message",
                "missing_sibling_dependency_message",
                "url_backed_dependency_reminder",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()