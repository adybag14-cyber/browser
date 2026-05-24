from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from issue3_text_input_suppression_runtime_audit import (
    EXPECTATIONS,
    audit,
    render_file,
    render_repo,
    run_self_test,
)


class Issue3TextInputSuppressionRuntimeAuditTests(unittest.TestCase):
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

    def test_audit_reports_missing_queue_helper_append(self) -> None:
        self.assert_missing_label_is_reported("win32_queue_helper_appends_specific_bytes")

    def test_audit_reports_missing_match_helper_remove_logic(self) -> None:
        self.assert_missing_label_is_reported("win32_match_helper_removes_only_matching_entry")

    def test_audit_reports_missing_mismatch_queue_flush(self) -> None:
        self.assert_missing_label_is_reported("win32_match_helper_clears_queue_on_mismatch")

    def test_audit_reports_missing_queue_reset(self) -> None:
        self.assert_missing_label_is_reported("win32_queue_reset_clears_retained_bytes")

    def test_audit_reports_missing_mismatched_text_regression(self) -> None:
        self.assert_missing_label_is_reported("win32_mismatched_text_regression_present")

    def test_audit_reports_missing_out_of_order_text_regression(self) -> None:
        self.assert_missing_label_is_reported("win32_out_of_order_text_regression_present")

    def test_audit_reports_every_label_in_isolation(self) -> None:
        for expectation in EXPECTATIONS:
            with self.subTest(label=expectation["label"]):
                self.assert_missing_label_is_reported(expectation["label"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_render_file_can_drop_targeted_match_logic(self) -> None:
        rendered = render_file(
            "src/display/win32_backend.zig",
            missing_label="win32_match_helper_removes_only_matching_entry",
        )
        self.assertNotIn(
            "        if (textInputEventMatches(expected, bytes)) {\n"
            "            const remaining = items[(idx + 1)..];\n"
            "            std.mem.copyForwards(Win32Backend.TextInputEvent, items[0..remaining.len], remaining);\n"
            "            self.pending_text_input_suppressions.items.len = remaining.len;\n"
            "            return true;\n"
            "        }\n",
            rendered,
        )
        self.assertIn(
            "fn textInputEventMatches(expected: Win32Backend.TextInputEvent, actual: []const u8) bool {",
            rendered,
        )

    def test_self_test_passes(self) -> None:
        stream = io.StringIO()
        with redirect_stdout(stream):
            ok, details = run_self_test()
        self.assertTrue(ok)
        self.assertEqual([], details)


if __name__ == "__main__":
    unittest.main()
