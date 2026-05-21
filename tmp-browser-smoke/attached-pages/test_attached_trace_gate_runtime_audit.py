from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from attached_trace_gate_runtime_audit import EXPECTATIONS, audit


class AttachedTraceGateRuntimeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_repo_fixture(self, *, missing_label: str | None = None) -> dict[str, str]:
        files: dict[str, list[str]] = {}
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                continue
            files.setdefault(expectation["path"], [f"// synthetic fixture for {expectation['path']}"])
            files[expectation["path"]].append(expectation["snippet"])
        return {path: "\n".join(parts) + "\n" for path, parts in files.items()}

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_repo_fixture().items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_trace_gate_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_repo_fixture(
                missing_label="render_attached_pages_in_trace_gate"
            ).items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("render_attached_pages_in_trace_gate", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_expectations_cover_runtime_and_render_trace_files(self) -> None:
        covered_paths = {expectation["path"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {"src/display/win32_backend.zig", "src/lightpanda.zig"},
            covered_paths,
        )


if __name__ == "__main__":
    unittest.main()