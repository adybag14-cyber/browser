from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from issue3_enter_submit_runtime_audit import EXPECTATIONS, audit, render_file, render_repo, run_self_test


class Issue3EnterSubmitRuntimeAuditTests(unittest.TestCase):
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

    def test_audit_reports_missing_page_begin_cleanup(self) -> None:
        self.assert_missing_label_is_reported("page_begin_deferred_submit_clears_pending_input")

    def test_audit_reports_missing_page_submit_call(self) -> None:
        self.assert_missing_label_is_reported("page_apply_deferred_submit_calls_submit_form")

    def test_audit_reports_missing_win32_text_builder(self) -> None:
        self.assert_missing_label_is_reported("win32_text_input_event_builder_present")

    def test_audit_reports_missing_win32_text_match_helper(self) -> None:
        self.assert_missing_label_is_reported("win32_text_input_match_helper_present")

    def test_audit_reports_missing_win32_defer_guard(self) -> None:
        self.assert_missing_label_is_reported("win32_enter_deferral_end_is_deferred_guard")

    def test_audit_reports_every_page_contract_label_in_isolation(self) -> None:
        labels = [
            "page_deferred_enter_fields_present",
            "page_pending_enter_pointer_present",
            "page_keyboard_text_suppression_depth_present",
            "page_begin_deferred_submit_clears_pending_input",
            "page_end_deferred_submit_clears_pending_input",
            "page_apply_deferred_submit_clears_pending_input_before_focus_recheck",
            "page_apply_deferred_submit_rechecks_focus",
            "page_apply_deferred_submit_calls_submit_form",
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
            "win32_text_input_event_builder_present",
            "win32_text_input_match_helper_present",
            "win32_queue_helper_present",
            "win32_matching_suppression_helper_present",
            "win32_queue_helper_wiring_present",
            "win32_text_input_suppression_uses_byte_match",
            "win32_suppression_queue_reset_present",
            "win32_enter_deferral_begins_before_keypress",
            "win32_enter_deferral_end_is_deferred_guard",
            "win32_enter_deferral_applies_after_keypress",
            "win32_mismatched_stale_text_regression_present",
            "win32_out_of_order_stale_text_regression_present",
        ]
        for label in labels:
            with self.subTest(label=label):
                self.assert_missing_label_is_reported(label)

    def test_audit_keeps_new_page_cleanup_and_submit_markers_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("page_begin_deferred_submit_clears_pending_input", covered_labels)
        self.assertIn("page_apply_deferred_submit_calls_submit_form", covered_labels)

    def test_audit_keeps_new_win32_helper_markers_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_text_input_event_builder_present", covered_labels)
        self.assertIn("win32_text_input_match_helper_present", covered_labels)
        self.assertIn("win32_enter_deferral_end_is_deferred_guard", covered_labels)

    def test_render_file_can_drop_new_targeted_label(self) -> None:
        rendered = render_file(
            "src/display/win32_backend.zig",
            missing_label="win32_text_input_match_helper_present",
        )
        self.assertNotIn(
            "fn textInputEventMatches(expected: Win32Backend.TextInputEvent, actual: []const u8) bool {",
            rendered,
        )
        self.assertIn("fn makeTextInputEvent(bytes: []const u8) ?Win32Backend.TextInputEvent {", rendered)

    def test_self_test_passes(self) -> None:
        stream = io.StringIO()
        with redirect_stdout(stream):
            ok, details = run_self_test()
        self.assertTrue(ok)
        self.assertEqual([], details)


if __name__ == "__main__":
    unittest.main()