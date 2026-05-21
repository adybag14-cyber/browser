from __future__ import annotations

import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

from headed_runtime_startup_contract_audit import EXPECTATIONS, audit


class HeadedRuntimeStartupContractAuditTests(unittest.TestCase):
    def write_repo_file(self, repo_root: Path, relative_path: str, content: str) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def write_contract_files(self, repo_root: Path, overrides: dict[str, str] | None = None) -> None:
        grouped: dict[str, list[str]] = defaultdict(list)
        for expectation in EXPECTATIONS:
            grouped[expectation["path"]].append(expectation["snippet"])

        for relative_path, snippets in grouped.items():
            content = "\n".join(["// synthetic fixture", *snippets, ""])
            if overrides and relative_path in overrides:
                content = overrides[relative_path]
            self.write_repo_file(repo_root, relative_path, content)

    def test_audit_passes_when_all_expected_contracts_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_contract_files(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            first = EXPECTATIONS[0]
            self.write_contract_files(
                repo_root,
                overrides={first["path"]: "// drifted fixture\n"},
            )

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            first_path_expectation_count = sum(
                1 for expectation in EXPECTATIONS if expectation["path"] == first["path"]
            )
            self.assertEqual(first_path_expectation_count, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])
            self.assertTrue(result["checks"][0]["exists"])

    def test_audit_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            first_path = EXPECTATIONS[0]["path"]
            self.write_contract_files(repo_root)
            (repo_root / first_path).unlink()

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            first_path_expectation_count = sum(
                1 for expectation in EXPECTATIONS if expectation["path"] == first_path
            )
            self.assertEqual(first_path_expectation_count, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_keeps_runtime_and_command_mode_coverage(self) -> None:
        covered_labels = {expectation["label"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "main_bare_local_html_helper",
                "main_loopback_ipv6_test",
                "config_file_url_browse_support",
                "config_headed_remote_html_browse_test",
            }.issubset(covered_labels)
        )


if __name__ == "__main__":
    unittest.main()