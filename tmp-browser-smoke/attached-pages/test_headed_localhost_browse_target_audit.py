from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from headed_localhost_browse_target_audit import EXPECTATIONS, audit


class HeadedLocalhostBrowseTargetAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            grouped_contents: dict[str, list[str]] = {}
            for expectation in EXPECTATIONS:
                grouped_contents.setdefault(expectation["path"], []).append(expectation["snippet"])
            for relative_path, snippets in grouped_contents.items():
                self.write_repo_file(repo_root, relative_path, "\n\n".join(snippets))

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            grouped_contents: dict[str, list[str]] = {}
            for index, expectation in enumerate(EXPECTATIONS):
                snippet = "# missing localhost loopback test" if index == 5 else expectation["snippet"]
                grouped_contents.setdefault(expectation["path"], []).append(snippet)
            for relative_path, snippets in grouped_contents.items():
                self.write_repo_file(repo_root, relative_path, "\n\n".join(snippets))

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][5]["present"])
            self.assertTrue(result["checks"][5]["exists"])

    def test_audit_reports_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(len(EXPECTATIONS), result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_localhost_and_attached_page_routes_in_scope(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "normalize_loopback_http_branch",
                "normalize_loopback_host_set",
                "normalize_loopback_regression_test",
                "implicit_loopback_helper",
                "attached_html_local_path_test",
                "schemeless_localhost_loopback_test",
                "fqdn_localhost_loopback_test",
                "ipv6_loopback_route_test",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()