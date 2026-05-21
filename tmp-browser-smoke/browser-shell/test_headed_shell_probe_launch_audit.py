from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_shell_probe_launch_audit import EXPECTATIONS, audit


class HeadedShellProbeLaunchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def write_expectation_fixtures(
        self,
        repo_root: Path,
        expectations: list[dict[str, str]] | tuple[dict[str, str], ...],
        *,
        override_first_snippet: str | None = None,
        skip_first: bool = False,
    ) -> None:
        grouped: dict[str, list[str]] = {}
        for index, expectation in enumerate(expectations):
            if skip_first and index == 0:
                continue
            snippet = expectation["snippet"]
            if override_first_snippet is not None and index == 0:
                snippet = override_first_snippet
            grouped.setdefault(expectation["path"], []).append(snippet)

        for relative_path, snippets in grouped.items():
            body = "# synthetic fixture\n" + "\n".join(snippets) + "\n"
            self.write_repo_file(repo_root, relative_path, body)

    def test_audit_passes_when_all_expected_launches_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixtures(repo_root, EXPECTATIONS)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixtures(
                repo_root,
                EXPECTATIONS,
                override_first_snippet="# missing headed launch",
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_expectation_fixtures(repo_root, EXPECTATIONS, skip_first=True)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_browser_shell_surfaces_in_coverage(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "tabs_primary_probe_headed_launch",
                "bookmark_persist_run1_headed_launch",
                "download_probe_headed_launch",
                "popup_anchor_probe_headed_launch",
                "zoom_probe_headed_launch",
                "bare_metal_policy_headed_launch",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
