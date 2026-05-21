from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from inline_flow_headed_launch_audit import EXPECTATIONS, audit


class InlineFlowHeadedLaunchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_launches_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in EXPECTATIONS:
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{expectation['snippet']}\n",
                )

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for index, expectation in enumerate(EXPECTATIONS):
                snippet = expectation["snippet"] if index else "# missing headed launch"
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{snippet}\n",
                )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in EXPECTATIONS[1:]:
                self.write_repo_file(
                    repo_root,
                    expectation["path"],
                    f"# synthetic fixture\n{expectation['snippet']}\n",
                )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])


if __name__ == "__main__":
    unittest.main()