from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from attached_page_filename_route_audit import (
    REAL_ATTACHED_PAGE_FILENAMES,
    SOURCE_EXPECTATIONS,
    SOURCE_PATH,
    TARGET_EXAMPLES,
    audit,
    classify_target,
)


class AttachedPageFilenameRouteAuditTests(unittest.TestCase):
    def write_source(self, repo_root: Path, content: str) -> None:
        target = repo_root / SOURCE_PATH
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_classify_target_keeps_real_attached_filenames_on_local_path_route(self) -> None:
        for filename in REAL_ATTACHED_PAGE_FILENAMES:
            with self.subTest(filename=filename):
                classification = classify_target(filename)
                self.assertEqual("path", classification["scheme"])
                self.assertEqual("local_path", classification["scope"])
                self.assertEqual("(none)", classification["host"])
                self.assertEqual("(none)", classification["port"])

    def test_classify_target_keeps_relative_and_windows_attached_paths_on_local_path_route(self) -> None:
        for example in TARGET_EXAMPLES:
            with self.subTest(label=example["label"]):
                classification = classify_target(example["target"])
                self.assertEqual(example["expected_scheme"], classification["scheme"])
                self.assertEqual(example["expected_scope"], classification["scope"])

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(expectation["snippet"] for expectation in SOURCE_EXPECTATIONS)
            self.write_source(repo_root, content)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_source_count"])
            self.assertEqual(0, result["misclassified_target_count"])

    def test_audit_reports_missing_source_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            content = "\n".join(expectation["snippet"] for expectation in SOURCE_EXPECTATIONS[1:])
            self.write_source(repo_root, content)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_source_count"])
            self.assertFalse(result["source_checks"][0]["present"])
            self.assertTrue(result["source_checks"][0]["exists"])

    def test_real_attached_page_manifest_keeps_all_three_uploaded_pages_visible(self) -> None:
        self.assertEqual(3, len(REAL_ATTACHED_PAGE_FILENAMES))
        joined = "\n".join(REAL_ATTACHED_PAGE_FILENAMES)
        self.assertIn("Google Safety Centre", joined)
        self.assertIn("Anthropic", joined)
        self.assertIn("Department of War", joined)


if __name__ == "__main__":
    unittest.main()