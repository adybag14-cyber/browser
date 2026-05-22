from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from issue3_enter_submit_runtime_audit import EXPECTATIONS, audit, render_file, render_repo, run_self_test


class Issue3EnterSubmitRuntimeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_file(self, relative_path: str, *, missing_label: str | None = None) -> str:
        return render_file(relative_path, missing_label=missing_label)

    def render_repo(self, repo_root: Path, *, missing_label: str | None = None) -> None:
        render_repo(repo_root, missing_label=missing_label)

    def assert_missing_label_is_reported(self, missing_label: str) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label=missing_label)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual(missing_label, failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_passes_when_all_expected_contracts_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_page_helper(self) -> None:
        self.assert_missing_label_is_reported("page_apply_deferred_submit_helper_present")

    def test_audit_reports_missing_page_focus_recheck(self) -> None:
        self.assert_missing_label_is_reported("page_apply_deferred_submit_rechecks_focus")

    def test_audit_reports_missing_page_pending_submit_branch(self) -> None:
        self.assert_missing_label_is_reported("page_enter_submit_queues_pending_input")

    def test_audit_reports_missing_page_keyboard_suppression_contract(self) -> None:
        self.assert_missing_label_is_reported("page_printable_input_respects_suppression_depth")

    def test_audit_reports_missing_win32_queue_cleanup(self) -> None:
        self.assert_missing_label_is_reported("win32_suppression_queue_deinit_present")

    def test_audit_reports_missing_win32_queue_wiring(self) -> None:
        self.assert_missing_label_is_reported("win32_queue_helper_wiring_present")

    def test_audit_reports_missing_win32_byte_match_dispatch(self) -> None:
        self.assert_missing_label_is_reported("win32_text_input_suppression_uses_byte_match")

    def test_audit_reports_missing_win32_queue_reset(self) -> None:
        self.assert_missing_label_is_reported("win32_suppression_queue_reset_present")

    def test_audit_reports_missing_win32_queue_regression(self) -> None:
        self.assert_missing_label_is_reported("win32_out_of_order_stale_text_regression_present")

    def test_audit_reports_every_page_contract_label_in_isolation(self) -> None:
        labels = [
            "page_deferred_enter_fields_present",
            "page_pending_enter_pointer_present",
            "page_keyboard_text_suppression_depth_present",
            "page_begin_deferred_submit_helper_present",
            "page_end_deferred_submit_helper_present",
            "page_apply_deferred_submit_helper_present",
            "page_apply_deferred_submit_rechecks_focus",
            "page_enter_submit_queues_pending_input",
            "page_printable_input_respects_suppression_depth",
            "page_enter_keypress_regression_present",
        ]
        for label in labels:
            with self.subTest(label=label):
                self.assert_missing_label_is_reported(label)

    def test_audit_reports_every_win32_contract_label_in_isolation(self) -> None:
        labels = [
            "win32_suppression_queue_present",
            "win32_suppression_queue_deinit_present",
            "win32_queue_helper_present",
            "win32_matching_suppression_helper_present",
            "win32_queue_helper_wiring_present",
            "win32_text_input_suppression_uses_byte_match",
            "win32_suppression_queue_reset_present",
            "win32_enter_deferral_begins_before_keypress",
            "win32_enter_deferral_ends_after_dispatch",
            "win32_enter_deferral_applies_after_keypress",
            "win32_mismatched_stale_text_regression_present",
            "win32_out_of_order_stale_text_regression_present",
        ]
        for label in labels:
            with self.subTest(label=label):
                self.assert_missing_label_is_reported(label)

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

    def test_audit_keeps_page_focus_recheck_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("page_apply_deferred_submit_rechecks_focus", covered_labels)

    def test_audit_keeps_page_keyboard_suppression_contract_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("page_keyboard_text_suppression_depth_present", covered_labels)
        self.assertIn("page_printable_input_respects_suppression_depth", covered_labels)

    def test_audit_keeps_win32_suppression_queue_lifecycle_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_suppression_queue_deinit_present", covered_labels)
        self.assertIn("win32_suppression_queue_reset_present", covered_labels)

    def test_audit_keeps_win32_suppression_queue_wiring_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_queue_helper_wiring_present", covered_labels)
        self.assertIn("win32_text_input_suppression_uses_byte_match", covered_labels)

    def test_audit_keeps_win32_enter_deferral_bracket_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_enter_deferral_begins_before_keypress", covered_labels)
        self.assertIn("win32_enter_deferral_ends_after_dispatch", covered_labels)

    def test_audit_keeps_post_keypress_submit_apply_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_enter_deferral_applies_after_keypress", covered_labels)

    def test_render_file_can_drop_one_targeted_label(self) -> None:
        rendered = self.render_file(
            "src/display/win32_backend.zig",
            missing_label="win32_enter_deferral_applies_after_keypress",
        )
        self.assertNotIn("try page.applyDeferredNativeTextInputEnterSubmit();", rendered)
        self.assertIn("page.beginDeferredNativeTextInputEnterSubmit();", rendered)

    def test_self_test_passes(self) -> None:
        stream = io.StringIO()
        with redirect_stdout(stream):
            ok, details = run_self_test()
        self.assertTrue(ok)
        self.assertEqual([], details)


if __name__ == "__main__":
    unittest.main()
