from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_enter_submit_runtime_audit import EXPECTATIONS, audit


class Issue3EnterSubmitRuntimeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_fixture(self, *, missing_label: str | None = None, page_only: bool = False) -> tuple[str, str]:
        page_parts = ["// synthetic src/browser/Page.zig fixture"]
        win32_parts = ["// synthetic src/display/win32_backend.zig fixture"]
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                continue
            path = expectation["path"]
            if page_only and path != "src/browser/Page.zig":
                continue
            if path == "src/browser/Page.zig":
                page_parts.append(expectation["snippet"])
            elif path == "src/display/win32_backend.zig":
                win32_parts.append(expectation["snippet"])
        return "\n".join(page_parts) + "\n", "\n".join(win32_parts) + "\n"

    def test_audit_passes_when_all_expected_guardrails_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            page_text, win32_text = self.render_fixture()
            self.write_repo_file(repo_root, "src/browser/Page.zig", page_text)
            self.write_repo_file(repo_root, "src/display/win32_backend.zig", win32_text)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_page_deferral_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            page_text, win32_text = self.render_fixture(
                missing_label="page_enter_submit_defers_until_keypress"
            )
            self.write_repo_file(repo_root, "src/browser/Page.zig", page_text)
            self.write_repo_file(repo_root, "src/display/win32_backend.zig", win32_text)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_enter_submit_defers_until_keypress", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_win32_queue_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            page_text, win32_text = self.render_fixture(
                missing_label="win32_matching_text_suppression_helper_present"
            )
            self.write_repo_file(repo_root, "src/browser/Page.zig", page_text)
            self.write_repo_file(repo_root, "src/display/win32_backend.zig", win32_text)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_matching_text_suppression_helper_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_page_and_win32_regressions_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "page_google_fixture_deferred_submit_test_present",
                "win32_mismatched_stale_text_test_present",
                "win32_out_of_order_stale_text_test_present",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
