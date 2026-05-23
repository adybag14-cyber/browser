from __future__ import annotations

import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CHECKER_DIR = SCRIPT_DIR.parent / "google-investigation-next"
if str(CHECKER_DIR) not in sys.path:
    sys.path.insert(0, str(CHECKER_DIR))

import check_issue3_enter_submit_runtime_contract as checker


class GoogleIssue3RuntimeContractCheckerSurfaceTests(unittest.TestCase):
    def test_checker_keeps_page_and_win32_contract_markers(self) -> None:
        self.assertIn(
            "_defer_native_text_input_enter_submit: bool = false",
            checker.PAGE_REQUIRED_MARKERS,
        )
        self.assertIn(
            "pub fn applyDeferredNativeTextInputEnterSubmit(self: *Page) !void {",
            checker.PAGE_REQUIRED_MARKERS,
        )
        self.assertIn(
            "pending_text_input_suppressions: std.ArrayListUnmanaged(TextInputEvent) = .{},",
            checker.WIN32_REQUIRED_MARKERS,
        )
        self.assertIn(
            "fn shouldSuppressPendingTextInput(self: *Win32Backend, bytes: []const u8) bool {",
            checker.WIN32_REQUIRED_MARKERS,
        )

    def test_checker_keeps_regression_markers(self) -> None:
        self.assertIn(
            'test "Page reduced Google fixture defers native Enter submit until keypress" {',
            checker.PAGE_TEST_MARKERS,
        )
        self.assertIn(
            'test "win32 dispatchInput allows later real text when stale suppression bytes do not match" {',
            checker.WIN32_TEST_MARKERS,
        )
        self.assertIn(
            'test "win32 dispatchInput suppresses matching text after stale entries drop out of order" {',
            checker.WIN32_TEST_MARKERS,
        )

    def test_checker_rejects_vulnerable_samples_and_accepts_guarded_samples(self) -> None:
        bad_ok, bad_details = checker.evaluate_sources(
            checker.VULNERABLE_PAGE,
            checker.VULNERABLE_WIN32,
        )
        good_ok, good_details = checker.evaluate_sources(
            checker.GUARDED_PAGE,
            checker.GUARDED_WIN32,
        )

        self.assertFalse(bad_ok)
        self.assertIn("PAGE_RUNTIME_CONTRACT=fail", bad_details)
        self.assertIn("WIN32_RUNTIME_CONTRACT=fail", bad_details)
        self.assertTrue(good_ok)
        self.assertIn("PAGE_RUNTIME_CONTRACT=pass", good_details)
        self.assertIn("WIN32_RUNTIME_CONTRACT=pass", good_details)

    def test_self_test_reports_pass_and_contract_details(self) -> None:
        stream = io.StringIO()
        with redirect_stdout(stream):
            result = checker.run_self_test()

        output = stream.getvalue()
        self.assertEqual(0, result)
        self.assertIn("SELF_TEST=pass", output)
        self.assertIn("VULNERABLE_PAGE_RUNTIME_CONTRACT=fail", output)
        self.assertIn("VULNERABLE_WIN32_RUNTIME_CONTRACT=fail", output)
        self.assertIn("GUARDED_PAGE_RUNTIME_CONTRACT=pass", output)
        self.assertIn("GUARDED_WIN32_RUNTIME_CONTRACT=pass", output)

    def test_checker_source_keeps_cli_surface(self) -> None:
        source = Path(checker.__file__).read_text(encoding="utf-8")
        for fragment in (
            "--self-test",
            "ISSUE3_ENTER_SUBMIT_RUNTIME_CONTRACT=",
            "PAGE_RUNTIME_CONTRACT=",
            "WIN32_RUNTIME_CONTRACT=",
            "either --self-test or both --page and --win32 are required",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, source)


if __name__ == "__main__":
    unittest.main()
