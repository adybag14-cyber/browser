from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from audit_issue3_trace_logs import format_report, iter_trace_paths, load_trace_lines, main
from issue3_trace_target_catalog import REPRESENTATIVE_TRACE_URLS


class AuditIssue3TraceLogsTests(unittest.TestCase):
    def test_iter_trace_paths_collects_log_files_from_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            wanted = root / "browse-render.log"
            wanted.write_text("stage|url=https://www.google.com/|detail=ok\n", encoding="utf-8")
            (root / "ignore.txt").write_text("skip\n", encoding="utf-8")

            self.assertEqual([wanted], list(iter_trace_paths([root])))

    def test_format_report_marks_missing_targets(self) -> None:
        lines = [f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok"]
        report = format_report([], lines)
        self.assertIn("Matched targets: 1/7", report)
        self.assertIn("fixture-title-probe", report)

    def test_main_succeeds_when_all_targets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            trace = root / "runtime-input.log"
            trace.write_text(
                "\n".join(
                    f"stage|url={url}|detail=ok"
                    for url in REPRESENTATIVE_TRACE_URLS.values()
                ),
                encoding="utf-8",
            )
            self.assertEqual(0, main([str(root)]))

    def test_main_returns_nonzero_when_targets_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            trace = root / "runtime-input.log"
            trace.write_text(
                f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok\n",
                encoding="utf-8",
            )
            self.assertEqual(1, main([str(root)]))

    def test_load_trace_lines_reads_multiple_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            first = root / "first.log"
            second = root / "second.log"
            first.write_text("a\n", encoding="utf-8")
            second.write_text("b\nc\n", encoding="utf-8")
            self.assertEqual(["a", "b", "c"], load_trace_lines([first, second]))


if __name__ == "__main__":
    unittest.main()
