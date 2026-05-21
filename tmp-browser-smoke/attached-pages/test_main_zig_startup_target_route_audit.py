from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from main_zig_startup_target_route_audit import EXPECTATIONS, audit


class MainZigStartupTargetRouteAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_main_zig(self, *, missing_label: str | None = None) -> str:
        parts = ["// synthetic src/main.zig fixture"]
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                continue
            parts.append(expectation["snippet"])
        return "\n".join(parts) + "\n"

    def test_audit_passes_when_all_expected_guardrails_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(repo_root, "src/main.zig", self.render_main_zig())

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_guard_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(
                repo_root,
                "src/main.zig",
                self.render_main_zig(missing_label="bare_local_html_guard_precedes_implicit_remote"),
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("bare_local_html_guard_precedes_implicit_remote", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_main_zig_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_dotted_filename_regressions_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "dotted_bare_html_regression_test_present",
                "dotted_bare_xhtml_regression_test_present",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
