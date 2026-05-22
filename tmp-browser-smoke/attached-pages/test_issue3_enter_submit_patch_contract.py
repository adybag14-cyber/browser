from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_enter_submit_patch_contract import EXPECTATIONS, audit, render_fixture_file


class Issue3EnterSubmitPatchContractTests(unittest.TestCase):
    def render_repo(self, repo_root: Path, *, missing_label: str | None = None) -> None:
        grouped_paths = sorted({expectation["path"] for expectation in EXPECTATIONS})
        for relative_path in grouped_paths:
            target = repo_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            label = missing_label if any(
                expectation["path"] == relative_path and expectation["label"] == missing_label
                for expectation in EXPECTATIONS
            ) else None
            target.write_text(
                render_fixture_file(relative_path, missing_label=label),
                encoding="utf-8",
            )

    def test_audit_passes_when_patch_contract_is_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_page_focus_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(
                repo_root,
                missing_label="page_apply_helper_requires_same_focused_input",
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("page_apply_helper_requires_same_focused_input", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_win32_byte_match_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.render_repo(
                repo_root,
                missing_label="win32_text_input_matches_queued_bytes",
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual("win32_text_input_matches_queued_bytes", failed["label"])
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_repo_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_checker_keeps_both_runtime_files_in_scope(self) -> None:
        covered_paths = {expectation["path"] for expectation in EXPECTATIONS}
        self.assertEqual(
            {"src/browser/Page.zig", "src/display/win32_backend.zig"},
            covered_paths,
        )

    def test_checker_keeps_saved_patch_queue_labels_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertIn("win32_keydown_queues_exact_text_bytes", covered_labels)
        self.assertIn("win32_text_input_matches_queued_bytes", covered_labels)
        self.assertIn("win32_matching_helper_clears_stale_queue_on_miss", covered_labels)


if __name__ == "__main__":
    unittest.main()