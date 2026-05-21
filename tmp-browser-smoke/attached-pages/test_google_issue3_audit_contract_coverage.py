import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path


HELPER_PATH = (
    Path(__file__).resolve().parent / "google_issue3_audit_contract_coverage.py"
)
SPEC = importlib.util.spec_from_file_location(
    "google_issue3_audit_contract_coverage", HELPER_PATH
)
helper = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
SPEC.loader.exec_module(helper)


class GoogleIssue3AuditContractCoverageTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.audit_path = self.root / "audit_module.py"
        self.test_path = self.root / "test_module.py"

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_modules(self, drift_cases: str) -> None:
        self.audit_path.write_text(
            """
EXPECTATIONS = (
    {
        "path": "docs/example.md",
        "snippet": "alpha",
        "purpose": "keep alpha visible",
    },
    {
        "path": "docs/example.md",
        "snippet": "beta",
        "purpose": "keep beta visible",
    },
    {
        "path": "scripts/example.ps1",
        "snippet": "gamma",
        "purpose": "keep gamma wired",
    },
)
""".strip()
            + "\n",
            encoding="utf-8",
        )
        self.test_path.write_text(
            f"DRIFT_CASES = (\n{drift_cases}\n)\n",
            encoding="utf-8",
        )

    def test_build_coverage_report_passes_when_all_expectations_are_covered(self) -> None:
        self.write_modules(
            """    ("case_alpha", "docs/example.md", "alpha", ""),
    ("case_beta", "docs/example.md", "beta", ""),
    ("case_gamma", "scripts/example.ps1", "gamma", ""),"""
        )

        report = helper.build_coverage_report(self.audit_path, self.test_path)

        self.assertEqual(3, report["expectation_count"])
        self.assertEqual(3, report["drift_case_count"])
        self.assertEqual(0, report["uncovered_count"])
        self.assertEqual([], report["uncovered"])

    def test_build_coverage_report_surfaces_uncovered_expectations(self) -> None:
        self.write_modules(
            """    ("case_alpha", "docs/example.md", "alpha", ""),
    ("case_gamma", "scripts/example.ps1", "gamma", ""),"""
        )

        report = helper.build_coverage_report(self.audit_path, self.test_path)

        self.assertEqual(1, report["uncovered_count"])
        self.assertEqual("docs/example.md", report["uncovered"][0]["path"])
        self.assertEqual("beta", report["uncovered"][0]["snippet"])
        self.assertEqual(1, report["uncovered_paths"][0]["missing_expectation_count"])

    def test_render_text_report_includes_grouped_summary(self) -> None:
        self.write_modules("""    ("case_gamma", "scripts/example.ps1", "gamma", ""),""")

        report = helper.build_coverage_report(self.audit_path, self.test_path)
        text = helper.render_text_report(report)

        self.assertIn("Google Issue #3 Audit Contract Coverage", text)
        self.assertIn("Uncovered expectations: 2", text)
        self.assertIn("[WARN] docs/example.md (2 missing)", text)
        self.assertIn("first purpose: keep alpha visible", text)
        self.assertIn("first snippet: alpha", text)

    def test_cli_json_output_returns_nonzero_when_expectations_are_uncovered(self) -> None:
        self.write_modules("""    ("case_alpha", "docs/example.md", "alpha", ""),""")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                ["--audit-module", str(self.audit_path), "--test-module", str(self.test_path), "--json"]
            )

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(2, payload["uncovered_count"])
        self.assertEqual("docs/example.md", payload["uncovered_paths"][0]["path"])

    def test_cli_json_output_reports_module_load_errors_cleanly(self) -> None:
        self.write_modules("""    ("case_alpha", "docs/example.md", "alpha", ""),""")
        missing_test_path = self.root / "missing_test_module.py"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(
                ["--audit-module", str(self.audit_path), "--test-module", str(missing_test_path), "--json"]
            )

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("coverage_check_failed", payload["error_type"])
        self.assertEqual(str(missing_test_path), payload["test_module_path"])
        self.assertIn("No such file or directory", payload["error"])


if __name__ == "__main__":
    unittest.main()
