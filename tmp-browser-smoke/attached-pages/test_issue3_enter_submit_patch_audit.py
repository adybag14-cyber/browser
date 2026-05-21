from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_enter_submit_patch_audit import EXPECTATIONS, audit


class Issue3EnterSubmitPatchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_fixture(self, *, missing_label: str | None = None) -> dict[str, str]:
        files: dict[str, list[str]] = {}
        for expectation in EXPECTATIONS:
            if expectation["label"] == missing_label:
                continue
            files.setdefault(expectation["path"], ["// synthetic fixture"])
            files[expectation["path"]].append(expectation["snippet"])
        return {path: "\n".join(parts) + "\n" for path, parts in files.items()}

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_fixture().items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_page_helper_bridge(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_fixture(
                missing_label="page_deferred_enter_helpers_present"
            ).items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_deferred_enter_helpers_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_win32_queue_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_fixture(
                missing_label="win32_text_suppression_queue_present"
            ).items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_text_suppression_queue_present", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_source_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))


if __name__ == "__main__":
    unittest.main()