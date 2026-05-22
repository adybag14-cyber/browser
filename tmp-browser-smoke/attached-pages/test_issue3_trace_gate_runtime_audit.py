from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_gate_runtime_audit import STATIC_EXPECTATIONS, TRACE_HINTS, audit


class Issue3TraceGateRuntimeAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_file(self, relative_path: str, *, missing_label: str | None = None, missing_hint: str | None = None) -> str:
        parts = [f"// synthetic {relative_path} fixture"]
        for expectation in STATIC_EXPECTATIONS:
            if expectation["path"] != relative_path:
                continue
            if expectation["label"] == missing_label:
                continue
            parts.append(expectation["snippet"])
        for hint in TRACE_HINTS:
            if hint == missing_hint:
                continue
            parts.append(hint)
        return "\n".join(parts) + "\n"

    def render_repo(self, repo_root: Path, *, missing_label: str | None = None, missing_hint: str | None = None) -> None:
        for relative_path in ("src/display/win32_backend.zig", "src/lightpanda.zig"):
            self.write_repo_file(
                repo_root,
                relative_path,
                self.render_file(relative_path, missing_label=missing_label, missing_hint=missing_hint),
            )

    def test_audit_passes_when_all_runtime_gate_expectations_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_win32_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_label="win32_casefold_trace_helper_present")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_casefold_trace_helper_present", failed["label"])

    def test_audit_reports_missing_render_hint(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root, missing_hint="Department%20of%20War")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            failed = next(
                check
                for check in result["checks"]
                if not check["present"] and check["label"] == "render_trace_hint::Department%20of%20War"
            )
            self.assertEqual("src/lightpanda.zig", failed["path"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))


if __name__ == "__main__":
    unittest.main()