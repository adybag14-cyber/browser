from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_saved_memory_inputs_surface_audit import EXPECTATIONS, audit


class Issue3SavedMemoryInputsSurfaceAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            grouped: dict[str, list[str]] = {}
            for expectation in EXPECTATIONS:
                grouped.setdefault(expectation["path"], []).append(expectation["snippet"])

            for relative_path, snippets in grouped.items():
                self.write_repo_file(repo_root, relative_path, "\n\n".join(snippets))

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            grouped: dict[str, list[str]] = {}
            for expectation in EXPECTATIONS:
                grouped.setdefault(expectation["path"], []).append(expectation["snippet"])

            first_label = EXPECTATIONS[0]["label"]
            for relative_path, snippets in grouped.items():
                content = "\n\n".join(snippets)
                if relative_path == EXPECTATIONS[0]["path"]:
                    content = content.replace(EXPECTATIONS[0]["snippet"], "# missing snippet", 1)
                self.write_repo_file(repo_root, relative_path, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            missing_checks = [check for check in result["checks"] if not check["present"]]
            self.assertEqual([first_label], [check["label"] for check in missing_checks])
            self.assertTrue(missing_checks[0]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_saved_memory_and_snapshot_route_surfaces_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "runtime_gates_saved_snapshot_note",
                "saved_memory_helper_repo_snapshot",
                "saved_memory_helper_fallback_zig_arg",
                "snapshot_route_synced_restore_section",
                "snapshot_surface_checker_sync_mode",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()
