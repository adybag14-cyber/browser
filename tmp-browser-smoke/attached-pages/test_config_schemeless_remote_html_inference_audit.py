from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from config_schemeless_remote_html_inference_audit import EXPECTATIONS, audit


class ConfigSchemelessRemoteHtmlInferenceAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_config_zig(self, *, missing_label: str | None = None) -> str:
        parts = ["// synthetic src/Config.zig fixture"]
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                continue
            parts.append(expectation["snippet"])
        return "\n".join(parts) + "\n"

    def test_audit_passes_when_all_expected_guardrails_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(repo_root, "src/Config.zig", self.render_config_zig())

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_remote_guard_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(
                repo_root,
                "src/Config.zig",
                self.render_config_zig(
                    missing_label="config_scheme_less_remote_guard_precedes_html_suffix_autobrowse"
                ),
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual(
                "config_scheme_less_remote_guard_precedes_html_suffix_autobrowse",
                failed["label"],
            )
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_headed_override_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_repo_file(
                repo_root,
                "src/Config.zig",
                self.render_config_zig(
                    missing_label="config_headed_remote_html_override_regression"
                ),
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual(
                "config_headed_remote_html_override_regression",
                failed["label"],
            )

    def test_audit_reports_missing_config_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_remote_loopback_and_override_regressions_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "config_scheme_less_remote_html_fetch_regression",
                "config_scheme_less_remote_xhtml_fetch_regression",
                "config_scheme_less_loopback_html_browse_regression",
                "config_scheme_less_ipv4_loopback_html_browse_regression",
                "config_headed_remote_html_override_regression",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
