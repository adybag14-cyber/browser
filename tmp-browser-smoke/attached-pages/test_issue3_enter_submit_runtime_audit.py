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

    def render_file(self, relative_path: str, *, missing_label: str | None = None) -> str:
        parts = [f"// synthetic {relative_path} fixture"]
        for expectation in EXPECTATIONS:
            if expectation["path"] != relative_path:
                continue
            if expectation["label"] == missing_label:
                continue
            parts.append(expectation["snippet"])
        return "\n".join(parts) + "\n"

    def render_repo(self, repo_root: Path, *, missing_label: str | None = None) -> None:
        grouped_paths = sorted({expectation["path"] for expectation in EXPECTATIONS})
        for relative_path in grouped_paths:
            self.write_repo_file(
                repo_root,
                relative_path,
                self.render_file(relative_path, missing_label=missing_label),
            )

    def test_audit_passes_when_all_expected_contracts_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_page_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label="page_apply_deferred_submit_helper_present")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_apply_deferred_submit_helper_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_page_pending_submit_branch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label="page_enter_submit_queues_pending_input")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_enter_submit_queues_pending_input", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_page_keyboard_suppression_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label="page_printable_input_respects_suppression_depth")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_printable_input_respects_suppression_depth", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_win32_queue_regression(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label="win32_out_of_order_stale_text_regression_present")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_out_of_order_stale_text_regression_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_both_runtime_files_in_scope(self) -> None:
        covered_paths = {expectation["path"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {"src/browser/Page.zig", "src/display/win32_backend.zig"},
            covered_paths,
        )

    def test_audit_keeps_page_deferred_submit_bracket_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("page_end_deferred_submit_helper_present", covered_labels)
        self.assertIn("page_enter_submit_queues_pending_input", covered_labels)

    def test_audit_keeps_page_keyboard_suppression_contract_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("page_keyboard_text_suppression_depth_present", covered_labels)
        self.assertIn("page_printable_input_respects_suppression_depth", covered_labels)

    def test_audit_keeps_win32_enter_deferral_bracket_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_enter_deferral_begins_before_keypress", covered_labels)
        self.assertIn("win32_enter_deferral_ends_after_dispatch", covered_labels)

    def test_audit_keeps_post_keypress_submit_apply_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_enter_deferral_applies_after_keypress", covered_labels)


if __name__ == "__main__":
    unittest.main()