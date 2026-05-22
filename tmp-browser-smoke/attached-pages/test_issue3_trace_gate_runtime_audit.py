from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_gate_runtime_audit import EXPECTATIONS, audit
from issue3_trace_target_catalog import ISSUE3_TRACE_HINTS


WIN32_HELPER = "fn traceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {"
RENDER_HELPER = "fn browseTraceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {"
WIN32_TEST = 'test "win32 google input trace gate includes attached compatibility pages and headed fixtures" {'
RENDER_TEST = 'test "browse render trace gate includes attached compatibility pages and headed fixtures" {'


class Issue3TraceGateRuntimeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_source(
        self,
        helper_snippet: str,
        test_snippet: str,
        *,
        missing_hint: str | None = None,
        include_helper: bool = True,
        include_test: bool = True,
    ) -> str:
        parts = ["// synthetic runtime trace gate fixture"]
        if include_helper:
            parts.append(helper_snippet)
        for hint in ISSUE3_TRACE_HINTS:
            if hint == missing_hint:
                continue
            parts.append(f"// {hint}")
        if include_test:
            parts.append(test_snippet)
        return "\n".join(parts) + "\n"

    def render_repo(
        self,
        repo_root: Path,
        *,
        win32_missing_hint: str | None = None,
        render_missing_hint: str | None = None,
        include_win32_helper: bool = True,
        include_render_helper: bool = True,
        include_win32_test: bool = True,
        include_render_test: bool = True,
    ) -> None:
        self.write_repo_file(
            repo_root,
            "src/display/win32_backend.zig",
            self.render_source(
                WIN32_HELPER,
                WIN32_TEST,
                missing_hint=win32_missing_hint,
                include_helper=include_win32_helper,
                include_test=include_win32_test,
            ),
        )
        self.write_repo_file(
            repo_root,
            "src/lightpanda.zig",
            self.render_source(
                RENDER_HELPER,
                RENDER_TEST,
                missing_hint=render_missing_hint,
                include_helper=include_render_helper,
                include_test=include_render_test,
            ),
        )

    def test_audit_passes_when_all_trace_gate_contracts_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_win32_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, include_win32_helper=False)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_ignore_case_trace_helper_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_render_catalog_hint(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, render_missing_hint="department of war")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            failed = next(
                check
                for check in result["checks"]
                if check["label"] == "render_trace_gate_covers_issue3_catalog_hints"
            )
            self.assertFalse(failed["present"])
            self.assertIn("department of war", failed["details"])

    def test_audit_reports_missing_render_regression_test(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, include_render_test=False)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            failed = next(
                check
                for check in result["checks"]
                if check["label"] == "render_trace_gate_regression_test_present"
            )
            self.assertFalse(failed["present"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_both_runtime_trace_files_in_scope(self) -> None:
        covered_paths = {expectation["path"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {"src/display/win32_backend.zig", "src/lightpanda.zig"},
            covered_paths,
        )


if __name__ == "__main__":
    unittest.main()