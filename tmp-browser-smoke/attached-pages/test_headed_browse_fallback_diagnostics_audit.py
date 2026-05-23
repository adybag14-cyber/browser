from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location(
    "headed_browse_fallback_diagnostics_audit",
    Path(__file__).with_name("headed_browse_fallback_diagnostics_audit.py"),
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class HeadedBrowseFallbackDiagnosticsAuditTests(unittest.TestCase):
    def write_source(self, repo_root: Path, content: str) -> None:
        target = repo_root / MODULE.SOURCE_PATH
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_repo_root_from_finds_build_zig(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            nested = repo_root / "tmp-browser-smoke" / "attached-pages"
            nested.mkdir(parents=True)
            (repo_root / "build.zig").write_text("// sentinel\n", encoding="utf-8")

            self.assertEqual(MODULE.repo_root_from(nested), repo_root)

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(expectation["snippet"] for expectation in MODULE.EXPECTATIONS)
            self.write_source(repo_root, content)

            result = MODULE.audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(
                expectation["snippet"] for expectation in MODULE.EXPECTATIONS[1:]
            )
            self.write_source(repo_root, content)

            result = MODULE.audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_source_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = MODULE.audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(MODULE.EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_fallback_and_completion_coverage_labels(self) -> None:
        covered_labels = {expectation["label"] for expectation in MODULE.EXPECTATIONS}
        self.assertTrue(
            {
                "browse_headed_runtime_log_exists",
                "browse_headed_fallback_log_exists",
                "browse_headed_fallback_keeps_reason",
                "browse_error_logs_navigation_state",
                "browse_finished_log_exists",
                "fallback_test_covers_linux_unsupported_case",
                "fallback_test_covers_windows_supported_case",
                "artifact_status_test_covers_unavailable_surface",
                "artifact_status_test_covers_settled_surface",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()