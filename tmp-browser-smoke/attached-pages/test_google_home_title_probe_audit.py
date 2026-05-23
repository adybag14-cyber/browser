from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from google_home_title_probe_audit import EXPECTATIONS, audit


class GoogleHomeTitleProbeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n\n".join(expectation["snippet"] for expectation in EXPECTATIONS)
            self.write_repo_file(repo_root, "src/browser/tests/page/google_home_title_probe.html", content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_probe_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n\n".join(
                "# missing document diagnostics"
                if expectation["label"] == "document_capture_diagnostics"
                else expectation["snippet"]
                for expectation in EXPECTATIONS
            )
            self.write_repo_file(repo_root, "src/browser/tests/page/google_home_title_probe.html", content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            missing = {check["label"] for check in result["checks"] if not check["present"]}
            self.assertEqual({"document_capture_diagnostics"}, missing)

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])

    def test_expectations_cover_focus_input_and_sync_surfaces(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "title_summary_fields",
                "query_input_focus_and_submit_markers",
                "query_input_keydown_and_submit",
                "document_capture_diagnostics",
                "focus_selection_and_rebind_loop",
                "steady_sync_interval",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()