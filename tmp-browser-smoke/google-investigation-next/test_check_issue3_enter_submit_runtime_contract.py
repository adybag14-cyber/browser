from __future__ import annotations

import unittest

from check_issue3_enter_submit_runtime_contract import (
    GUARDED_PAGE,
    GUARDED_WIN32,
    PAGE_REQUIRED_MARKERS,
    PAGE_TEST_MARKERS,
    WIN32_REQUIRED_MARKERS,
    WIN32_TEST_MARKERS,
    VULNERABLE_PAGE,
    VULNERABLE_WIN32,
    evaluate_page_source,
    evaluate_sources,
    evaluate_win32_source,
    find_missing_markers,
    run_self_test,
)


class Issue3EnterSubmitRuntimeContractTests(unittest.TestCase):
    def test_find_missing_markers_reports_only_absent_markers(self) -> None:
        source = "\n".join((PAGE_REQUIRED_MARKERS[0], PAGE_REQUIRED_MARKERS[2]))
        missing = find_missing_markers(source, PAGE_REQUIRED_MARKERS[:3])
        self.assertEqual([PAGE_REQUIRED_MARKERS[1]], missing)

    def test_embedded_vulnerable_and_guarded_samples_stay_distinct(self) -> None:
        vulnerable_ok, vulnerable_details = evaluate_sources(
            VULNERABLE_PAGE,
            VULNERABLE_WIN32,
        )
        guarded_ok, guarded_details = evaluate_sources(
            GUARDED_PAGE,
            GUARDED_WIN32,
        )

        self.assertFalse(vulnerable_ok)
        self.assertIn("PAGE_RUNTIME_CONTRACT=fail", vulnerable_details)
        self.assertIn("WIN32_RUNTIME_CONTRACT=fail", vulnerable_details)
        self.assertTrue(guarded_ok)
        self.assertIn("PAGE_RUNTIME_CONTRACT=pass", guarded_details)
        self.assertIn("WIN32_RUNTIME_CONTRACT=pass", guarded_details)

    def test_page_contract_requires_runtime_and_regression_markers(self) -> None:
        runtime_only_source = GUARDED_PAGE.replace(PAGE_TEST_MARKERS[2], "")

        ok, detail = evaluate_page_source(runtime_only_source)

        self.assertFalse(ok)
        self.assertIn("missing regression coverage markers", detail)
        self.assertIn(PAGE_TEST_MARKERS[2], detail)

    def test_win32_contract_requires_runtime_and_regression_markers(self) -> None:
        runtime_only_source = GUARDED_WIN32.replace(WIN32_TEST_MARKERS[1], "")

        ok, detail = evaluate_win32_source(runtime_only_source)

        self.assertFalse(ok)
        self.assertIn("missing regression coverage markers", detail)
        self.assertIn(WIN32_TEST_MARKERS[1], detail)

    def test_embedded_self_test_stays_green(self) -> None:
        self.assertEqual(0, run_self_test())


if __name__ == "__main__":
    unittest.main()
