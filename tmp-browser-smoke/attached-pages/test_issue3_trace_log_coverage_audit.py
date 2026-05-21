from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_log_coverage_audit import (
    REPRESENTATIVE_TRACE_URLS,
    TRACE_LOG_PATTERNS,
    audit_trace_logs,
    collect_matching_lines,
    format_gap_report,
    main,
    matching_trace_urls,
    missing_trace_urls,
)


class Issue3TraceLogCoverageAuditTests(unittest.TestCase):
    def test_collect_matching_lines_reads_globbed_logs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "runtime-input-backend-111.log").write_text("first\n", encoding="utf-8")
            (root / "runtime-input-backend-222.log").write_text("second\n", encoding="utf-8")

            self.assertEqual(
                ["first", "second"],
                collect_matching_lines(root, "runtime-input-backend-*.log"),
            )

    def test_matching_trace_urls_marks_seen_entries(self) -> None:
        lines = [
            "browse|url=https://www.google.com/|ok",
            "browse|url=http://127.0.0.1:8000/google_home_title_probe.html|ok",
        ]
        seen = matching_trace_urls(lines)
        self.assertTrue(seen["google-home"])
        self.assertTrue(seen["fixture-title-probe"])
        self.assertFalse(seen["saved-anthropic-job"])

    def test_missing_trace_urls_reports_only_missing_entries(self) -> None:
        lines = ["browse|url=https://www.google.com/|ok"]
        missing = missing_trace_urls(lines)
        self.assertNotIn("google-home", missing)
        self.assertIn("fixture-onload-input", missing)
        self.assertIn("saved-department-of-war", missing)

    def test_audit_trace_logs_reports_per_family_gaps(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            root.mkdir(parents=True, exist_ok=True)
            (root / "browse-render.log").write_text(
                "browse|url=https://www.google.com/|ok\n",
                encoding="utf-8",
            )
            (root / "runtime-input-backend-1.log").write_text(
                "input|url=http://127.0.0.1:8000/body_onload_keyboard_input.html|ok\n",
                encoding="utf-8",
            )
            (root / "wndproc-input-1.log").write_text(
                "wndproc|url=file:///tmp/Job%20Application%20for%20Research%20Manager%20at%20Anthropic.html|ok\n",
                encoding="utf-8",
            )

            report = audit_trace_logs(root)
            self.assertEqual(set(TRACE_LOG_PATTERNS), set(report))
            self.assertIn("fixture-mousedown-input", report["browse-render"])
            self.assertIn("saved-google-safety", report["runtime-input"])
            self.assertIn("google-home", report["wndproc-input"])

    def test_format_gap_report_marks_ok_and_missing_families(self) -> None:
        report = {
            "browse-render": [],
            "runtime-input": ["fixture-title-probe", "saved-google-safety"],
        }
        formatted = format_gap_report(report)
        self.assertIn("browse-render: ok", formatted)
        self.assertIn("runtime-input: missing 2", formatted)
        self.assertIn("  - saved-google-safety", formatted)

    def test_main_returns_zero_when_all_representative_urls_are_seen(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            joined_lines = "\n".join(
                f"trace|url={url}|ok" for url in REPRESENTATIVE_TRACE_URLS.values()
            )
            for pattern in TRACE_LOG_PATTERNS.values():
                filename = pattern.replace("*", "123")
                (root / filename).write_text(joined_lines + "\n", encoding="utf-8")

            self.assertEqual(0, main(["--log-root", str(root)]))

    def test_main_returns_one_when_any_family_is_missing_targets(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "browse-render.log").write_text(
                "trace|url=https://www.google.com/|ok\n",
                encoding="utf-8",
            )
            (root / "runtime-input-backend-1.log").write_text(
                "trace|url=https://www.google.com/|ok\n",
                encoding="utf-8",
            )
            (root / "wndproc-input-1.log").write_text(
                "trace|url=https://www.google.com/|ok\n",
                encoding="utf-8",
            )

            self.assertEqual(1, main(["--log-root", str(root)]))


if __name__ == "__main__":
    unittest.main()