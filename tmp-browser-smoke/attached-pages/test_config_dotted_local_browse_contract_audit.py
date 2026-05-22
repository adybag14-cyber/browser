#!/usr/bin/env python3
"""Unit tests for the dotted local browse-target contract audit."""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).with_name("config_dotted_local_browse_contract_audit.py")
SPEC = importlib.util.spec_from_file_location("config_dotted_local_browse_contract_audit", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ConfigDottedLocalBrowseContractAuditTest(unittest.TestCase):
    def test_audit_passes_when_expected_snippets_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            for expectation in MODULE.EXPECTATIONS:
                target = repo_root / expectation["path"]
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open("a", encoding="utf-8") as handle:
                    handle.write(expectation["snippet"])
                    handle.write("\n")

            result = MODULE.audit(repo_root)

        self.assertTrue(result["ok"], msg=result)
        self.assertEqual(0, result["missing_count"], msg=result)

    def test_audit_reports_missing_expectations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            (repo_root / "src").mkdir(parents=True, exist_ok=True)
            (repo_root / "src/Config.zig").write_text("", encoding="utf-8")

            result = MODULE.audit(repo_root)

        self.assertFalse(result["ok"], msg=result)
        self.assertGreater(result["missing_count"], 0, msg=result)


if __name__ == "__main__":
    unittest.main()
