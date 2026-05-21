from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_gate_gap_report import (
    TRACE_GATE_FUNCTIONS,
    audit_trace_gate_source,
    audit_trace_gate_sources,
    extract_function_block,
    format_gap_report,
    main,
    matching_gate_hints,
    missing_gate_hints,
)
from issue3_trace_target_catalog import ISSUE3_TRACE_HINTS


class Issue3TraceGateGapReportTests(unittest.TestCase):
    def test_extract_function_block_returns_named_function(self) -> None:
        source = "fn before() bool { return false; }\nfn target() bool { return true; }\n"
        self.assertEqual("fn target() bool { return true; }", extract_function_block(source, "target"))

    def test_extract_function_block_rejects_missing_function(self) -> None:
        with self.assertRaisesRegex(ValueError, "missing function"):
            extract_function_block("fn other() bool { return false; }", "target")

    def test_matching_gate_hints_is_case_insensitive(self) -> None:
        source = 'fn target() bool { return trace("GOOGLE_HOME_TITLE_PROBE.HTML") or trace("google.com"); }'
        seen = matching_gate_hints(source, "target", ("google_home_title_probe.html", "google.com"))
        self.assertTrue(seen["google_home_title_probe.html"])
        self.assertTrue(seen["google.com"])

    def test_missing_gate_hints_reports_only_uncovered_hints(self) -> None:
        source = 'fn target() bool { return trace("google.com"); }'
        missing = missing_gate_hints(source, "target", ("google.com", "body_onload_keyboard_input.html"))
        self.assertEqual(["body_onload_keyboard_input.html"], missing)

    def test_audit_trace_gate_source_reads_repo_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "gate.zig"
            source_path.write_text(
                'fn googleRenderTraceEnabled(url: []const u8) bool { return trace("google.com"); }\n',
                encoding="utf-8",
            )
            missing = audit_trace_gate_source(source_path, "googleRenderTraceEnabled")
            self.assertIn("google-home-", missing)
            self.assertNotIn("google.com", missing)

    def test_audit_trace_gate_sources_uses_repo_style_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            for relative_path, function_name in TRACE_GATE_FUNCTIONS.items():
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    f'fn {function_name}(url: []const u8) bool {{ return trace("google.com") or trace("google-home-"); }}\n',
                    encoding="utf-8",
                )

            report = audit_trace_gate_sources(root)
            self.assertEqual(set(TRACE_GATE_FUNCTIONS), set(report))
            self.assertTrue(all("google_home_title_probe.html" in missing for missing in report.values()))

    def test_format_gap_report_marks_ok_and_missing_files(self) -> None:
        report = {
            "src/lightpanda.zig": [],
            "src/display/win32_backend.zig": ["google_home_title_probe.html", "anthropic"],
        }
        formatted = format_gap_report(report)
        self.assertIn("src/lightpanda.zig: ok", formatted)
        self.assertIn("src/display/win32_backend.zig: missing 2", formatted)
        self.assertIn("  - anthropic", formatted)

    def test_main_returns_zero_for_complete_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            joined_hints = " or ".join(f'trace("{hint}")' for hint in ISSUE3_TRACE_HINTS)
            for relative_path, function_name in TRACE_GATE_FUNCTIONS.items():
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    f"fn {function_name}(url: []const u8) bool {{ return {joined_hints}; }}\n",
                    encoding="utf-8",
                )

            self.assertEqual(0, main(["--base-dir", str(root)]))

    def test_main_returns_one_for_missing_hints(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            for relative_path, function_name in TRACE_GATE_FUNCTIONS.items():
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    f'fn {function_name}(url: []const u8) bool {{ return trace("google.com"); }}\n',
                    encoding="utf-8",
                )

            self.assertEqual(1, main(["--base-dir", str(root)]))


if __name__ == "__main__":
    unittest.main()
