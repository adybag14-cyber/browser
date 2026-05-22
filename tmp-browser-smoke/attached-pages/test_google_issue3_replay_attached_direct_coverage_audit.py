import contextlib
import io
import json
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import google_issue3_replay_attached_direct_coverage_audit as helper


class GoogleIssue3ReplayAttachedDirectCoverageAuditTests(unittest.TestCase):
    def test_build_direct_coverage_audit_passes_when_every_expectation_has_a_case(self) -> None:
        expectations = (
            {"path": "docs/a.md", "snippet": "alpha", "purpose": "alpha purpose"},
            {"path": "docs/b.md", "snippet": "beta", "purpose": "beta purpose"},
        )
        drift_cases = (
            ("alpha_case", "docs/a.md", "alpha", ""),
            ("beta_case", "docs/b.md", "beta", "drifted"),
        )

        audit = helper.build_direct_coverage_audit(expectations, drift_cases)

        self.assertEqual(2, audit["expectation_count"])
        self.assertEqual(2, audit["direct_case_count"])
        self.assertEqual(0, audit["uncovered_count"])
        self.assertEqual(0, audit["orphan_drift_case_count"])
        self.assertTrue(all(result["has_direct_case"] for result in audit["results"]))

    def test_build_direct_coverage_audit_groups_uncovered_expectations_by_path(self) -> None:
        expectations = (
            {"path": "docs/a.md", "snippet": "alpha", "purpose": "alpha purpose"},
            {"path": "docs/a.md", "snippet": "beta", "purpose": "beta purpose"},
            {"path": "docs/b.md", "snippet": "gamma", "purpose": "gamma purpose"},
        )
        drift_cases = (("alpha_case", "docs/a.md", "alpha", ""),)

        audit = helper.build_direct_coverage_audit(expectations, drift_cases)

        self.assertEqual(2, audit["uncovered_count"])
        self.assertEqual(2, audit["uncovered_path_count"])
        uncovered = {entry["path"]: entry for entry in audit["uncovered_paths"]}
        self.assertEqual(1, uncovered["docs/a.md"]["missing_expectation_count"])
        self.assertEqual("beta purpose", uncovered["docs/a.md"]["first_missing_purpose"])
        self.assertEqual("beta", uncovered["docs/a.md"]["first_missing_snippet"])
        self.assertEqual(1, uncovered["docs/b.md"]["missing_expectation_count"])

    def test_build_direct_coverage_audit_reports_orphan_cases(self) -> None:
        expectations = (
            {"path": "docs/a.md", "snippet": "alpha", "purpose": "alpha purpose"},
        )
        drift_cases = (
            ("alpha_case", "docs/a.md", "alpha", ""),
            ("orphan_case", "docs/a.md", "beta", ""),
        )

        audit = helper.build_direct_coverage_audit(expectations, drift_cases)

        self.assertEqual(1, audit["orphan_drift_case_count"])
        self.assertEqual("orphan_case", audit["orphan_drift_cases"][0]["name"])

    def test_main_loads_modules_from_a_custom_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            (root / "mini_helper.py").write_text(
                textwrap.dedent(
                    """
                    EXPECTATIONS = (
                        {"path": "docs/a.md", "snippet": "alpha", "purpose": "alpha purpose"},
                        {"path": "docs/b.md", "snippet": "beta", "purpose": "beta purpose"},
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            (root / "mini_test.py").write_text(
                textwrap.dedent(
                    """
                    DRIFT_CASES = (
                        ("alpha_case", "docs/a.md", "alpha", ""),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                exit_code = helper.main(
                    [
                        "--helper-module",
                        "mini_helper",
                        "--test-module",
                        "mini_test",
                        "--module-dir",
                        str(root),
                        "--json",
                    ]
                )

            self.assertEqual(1, exit_code)
            payload = json.loads(output.getvalue())
            self.assertEqual("mini_helper", payload["helper_module"])
            self.assertEqual("mini_test", payload["test_module"])
            self.assertEqual(str(root.resolve()), payload["module_dir"])
            self.assertEqual(2, payload["expectation_count"])
            self.assertEqual(1, payload["uncovered_count"])
            self.assertEqual("docs/b.md", payload["uncovered_paths"][0]["path"])

    def test_main_reports_module_directory_errors_in_text(self) -> None:
        output = io.StringIO()
        missing_dir = "/tmp/does-not-exist-direct-coverage-audit"
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(
                ["--module-dir", missing_dir, "--helper-module", "missing_helper"]
            )

        self.assertEqual(1, exit_code)
        text = output.getvalue()
        self.assertIn("Google Issue #3 Replay Attached Direct Coverage Audit", text)
        self.assertIn("Error: module directory does not exist:", text)


if __name__ == "__main__":
    unittest.main()
