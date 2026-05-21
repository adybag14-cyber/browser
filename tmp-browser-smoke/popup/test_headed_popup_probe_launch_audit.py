from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_popup_probe_launch_audit import EXPECTATIONS, audit


class HeadedPopupProbeLaunchAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def render_probe_files(self, *, missing_label: str | None = None) -> dict[str, str]:
        rendered: dict[str, str] = {}
        for expectation in EXPECTATIONS:
            path = expectation["path"]
            rendered.setdefault(path, "// synthetic popup probe fixture\n")
            if expectation["label"] == missing_label:
                continue
            rendered[path] += expectation["snippet"] + "\n"
        return rendered

    def test_audit_passes_when_all_popup_launch_guards_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_probe_files().items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_popup_launch_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for relative_path, content in self.render_probe_files(
                missing_label="popup_script_policy_launches_headed_explicitly"
            ).items():
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            failed = next(check for check in result["checks"] if not check["present"])
            self.assertEqual(
                "popup_script_policy_launches_headed_explicitly", failed["label"]
            )
            self.assertTrue(failed["exists"])

    def test_audit_reports_missing_probe_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertTrue(all(not check["exists"] for check in result["checks"]))

    def test_audit_keeps_popup_representatives_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "popup_anchor_launches_headed_explicitly",
                "popup_form_enter_launches_headed_explicitly",
                "popup_form_post_launches_headed_explicitly",
                "popup_query_load_launches_headed_explicitly",
                "popup_script_blank_launches_headed_explicitly",
                "popup_script_policy_launches_headed_explicitly",
                "popup_script_policy_block_launches_headed_explicitly",
                "popup_named_anchor_launches_headed_explicitly",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()