from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from main_bare_local_html_startup_diagnostics_audit import EXPECTATIONS, audit


class MainBareLocalHtmlStartupDiagnosticsAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_diagnostics_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(
                repo_root,
                "src/main.zig",
                "\n".join(expectation["snippet"] for expectation in EXPECTATIONS) + "\n",
            )

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            snippets = [expectation["snippet"] for expectation in EXPECTATIONS[1:]]
            self.write_repo_file(repo_root, "src/main.zig", "\n".join(snippets) + "\n")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_repo_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])

    def test_audit_keeps_dotted_html_regressions_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "main_bare_local_html_dotted_regression",
                "main_bare_local_xhtml_dotted_regression",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()