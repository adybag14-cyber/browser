from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_gate_source_audit import (
    TRACE_GATE_SOURCES,
    audit_trace_gate_source,
    audit_trace_gate_sources,
    failing_trace_gate_sources,
)
from issue3_trace_target_catalog import ISSUE3_TRACE_HINTS


def _write_trace_gate_source(path: Path, function_name: str, hints: tuple[str, ...]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(
            [
                f"fn {function_name}(url: []const u8) bool {{",
                "    return",
                *[f'        std.mem.indexOf(u8, url, "{hint}") != null or' for hint in hints[:-1]],
                f'        std.mem.indexOf(u8, url, "{hints[-1]}") != null;',
                "}",
            ]
        ),
        encoding="utf-8",
    )


class Issue3TraceGateSourceAuditTests(unittest.TestCase):
    def test_audit_trace_gate_source_reports_complete_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "src/display/win32_backend.zig"
            _write_trace_gate_source(source_path, "googleInputTraceEnabled", ISSUE3_TRACE_HINTS)
            audit = audit_trace_gate_source(source_path, "googleInputTraceEnabled")
            self.assertTrue(audit.function_present)
            self.assertEqual((), audit.missing_hints)

    def test_audit_trace_gate_source_reports_missing_hints(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "src/lightpanda.zig"
            _write_trace_gate_source(
                source_path,
                "googleRenderTraceEnabled",
                ISSUE3_TRACE_HINTS[:3],
            )
            audit = audit_trace_gate_source(source_path, "googleRenderTraceEnabled")
            self.assertIn("body_onload_keyboard_input.html", audit.missing_hints)
            self.assertIn("department of war", audit.missing_hints)

    def test_audit_trace_gate_source_reports_missing_function(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "src/lightpanda.zig"
            source_path.parent.mkdir(parents=True, exist_ok=True)
            source_path.write_text("fn unrelated() void {}\n", encoding="utf-8")
            audit = audit_trace_gate_source(source_path, "googleRenderTraceEnabled")
            self.assertFalse(audit.function_present)

    def test_failing_trace_gate_sources_filters_to_problem_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            for relative_path, function_name in TRACE_GATE_SOURCES.items():
                hints = ISSUE3_TRACE_HINTS
                if relative_path.endswith("lightpanda.zig"):
                    hints = ISSUE3_TRACE_HINTS[:4]
                _write_trace_gate_source(root / relative_path, function_name, hints)

            failing = failing_trace_gate_sources(root)
            self.assertEqual(1, len(failing))
            self.assertTrue(failing[0].relative_path.endswith("src/lightpanda.zig"))

    def test_audit_trace_gate_sources_uses_standard_relative_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            for relative_path, function_name in TRACE_GATE_SOURCES.items():
                _write_trace_gate_source(root / relative_path, function_name, ISSUE3_TRACE_HINTS)

            audits = audit_trace_gate_sources(root)
            self.assertEqual(set(TRACE_GATE_SOURCES), {audit.relative_path for audit in audits})


if __name__ == "__main__":
    unittest.main()
