from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from browse_target_startup_diagnostics_audit import EXPECTATIONS, audit


class BrowseTargetStartupDiagnosticsAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def write_expectation_fixture(
        self,
        repo_root: Path,
        replacements: dict[str, dict[str, str]] | None = None,
        skip_paths: set[str] | None = None,
    ) -> None:
        grouped: dict[str, list[str]] = {}
        for expectation in EXPECTATIONS:
            if skip_paths and expectation["path"] in skip_paths:
                continue
            replacement = None
            if replacements:
                replacement = replacements.get(expectation["label"])
            snippet = replacement["snippet"] if replacement else expectation["snippet"]
            grouped.setdefault(expectation["path"], []).append(snippet)

        for relative_path, snippets in grouped.items():
            content = "// synthetic fixture\n" + "\n".join(snippets) + "\n"
            self.write_repo_file(repo_root, relative_path, content)

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixture(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixture(
                repo_root,
                replacements={
                    EXPECTATIONS[0]["label"]: {
                        "snippet": "// missing startup diagnostics snippet",
                    }
                },
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixture(repo_root, skip_paths={"src/main.zig"})

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_all_diagnostic_scopes_in_coverage(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "main_browser_internal_helper",
                "main_about_internal_helper",
                "main_local_path_candidate_helper",
                "main_implicit_loopback_helper",
                "main_implicit_remote_helper",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()