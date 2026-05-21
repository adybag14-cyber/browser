from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_product_surface_probe_launch_audit import EXPECTATIONS, audit


class HeadedProductSurfaceProbeLaunchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_launches_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in EXPECTATIONS:
                joined = "\n".join(expectation["snippets"])
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{joined}\n",
                )

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_in_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for index, expectation in enumerate(EXPECTATIONS):
                snippets = list(expectation["snippets"])
                if index == 0:
                    snippets = snippets[:-1]
                joined = "\n".join(snippets or ["# missing headed launch"])
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{joined}\n",
                )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])
            self.assertEqual(1, len(result["checks"][0]["missing_snippets"]))

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in EXPECTATIONS[1:]:
                joined = "\n".join(expectation["snippets"])
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{joined}\n",
                )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_browser_surface_coverage(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {
                "find_probe_headed_launch",
                "settings_restore_off_headed_launches",
                "bookmark_close_headed_launch",
                "download_delete_headed_launch",
            },
            covered_labels,
        )


if __name__ == "__main__":
    unittest.main()