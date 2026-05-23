from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_runtime_activation_log_audit import EXPECTATIONS, audit


class HeadedRuntimeActivationLogAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n\n".join(expectation["snippet"] for expectation in EXPECTATIONS)
            self.write_repo_file(repo_root, "src/main.zig", content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n\n".join(
                "# missing headed runtime binding" if index == 1 else expectation["snippet"]
                for index, expectation in enumerate(EXPECTATIONS)
            )
            self.write_repo_file(repo_root, "src/main.zig", content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][1]["present"])
            self.assertTrue(result["checks"][1]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_runtime_and_fallback_command_surfaces_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "headed_runtime_helper",
                "headed_runtime_binding",
                "serve_headed_runtime_log",
                "serve_headed_fallback_log",
                "browse_headed_runtime_log",
                "browse_headed_fallback_log",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()