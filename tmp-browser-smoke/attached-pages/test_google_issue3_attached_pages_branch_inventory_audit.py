import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_pages_branch_inventory_audit as helper


class GoogleIssue3AttachedPagesBranchInventoryAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_build_inventory_counts_existing_and_missing_targets(self) -> None:
        (self.root / "docs").mkdir()
        (self.root / "docs" / "WINDOWS_FULL_USE.md").write_text("runbook", encoding="utf-8")

        targets = [
            {
                "path": "docs/WINDOWS_FULL_USE.md",
                "purpose": "existing runbook",
            },
            {
                "path": "scripts/windows/start_attached_pages_catalog.ps1",
                "purpose": "missing helper",
            },
        ]

        inventory = helper.build_inventory(self.root, targets)

        self.assertEqual(2, inventory["target_count"])
        self.assertEqual(1, inventory["existing_count"])
        self.assertEqual(1, inventory["missing_count"])
        self.assertEqual("file", inventory["results"][0]["kind"])
        self.assertEqual("missing", inventory["results"][1]["kind"])

    def test_parse_targets_can_use_defaults_and_custom_paths(self) -> None:
        targets = helper.parse_targets(
            ["tmp-browser-smoke/attached-pages/custom_probe.py"],
            include_defaults=True,
        )

        self.assertGreaterEqual(len(targets), len(helper.DEFAULT_TARGETS) + 1)
        self.assertEqual(
            "tmp-browser-smoke/attached-pages/custom_probe.py",
            targets[-1]["path"],
        )
        self.assertEqual("User-supplied path probe.", targets[-1]["purpose"])

    def test_render_text_report_mentions_missing_target(self) -> None:
        inventory = {
            "repo_root": str(self.root),
            "target_count": 1,
            "existing_count": 0,
            "missing_count": 1,
            "results": [
                {
                    "path": "scripts/windows/start_attached_pages_catalog.ps1",
                    "purpose": "missing helper",
                    "exists": False,
                    "kind": "missing",
                }
            ],
        }

        report = helper.render_text_report(inventory)

        self.assertIn("Missing: 1", report)
        self.assertIn("missing: scripts/windows/start_attached_pages_catalog.ps1", report)

    def test_build_repo_root_error_inventory_records_error(self) -> None:
        inventory = helper.build_repo_root_error_inventory(
            "/definitely/missing",
            "repo root does not exist: /definitely/missing",
        )

        self.assertEqual("repo_root_not_found", inventory["error_type"])
        self.assertIn("repo root does not exist", inventory["error"])


if __name__ == "__main__":
    unittest.main()