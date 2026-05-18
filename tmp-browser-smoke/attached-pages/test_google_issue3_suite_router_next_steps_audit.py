import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_suite_router_next_steps_audit as helper


DOC_SNIPPET = """# Issue #3 Suite Router Next Steps

4. `show_headed_validation_suites.ps1 -ChangeArea google-attached-html`
   Next helper:
   `powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_google_attached_html_entrypoint.ps1`

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md` for the Google-shaped attached-page bridge that stays available before the route collapses into the narrower issue `#3` helpers
"""


SCRIPT_SNIPPET = """$matrix = @(
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'
        default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
    }
)

$helper = [ordered]@{
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
}
"""


class GoogleIssue3SuiteRouterNextStepsAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)

    def tearDown(self):
        self.tempdir.cleanup()

    def write_contract_files(self, *, doc_text: str = DOC_SNIPPET, script_text: str = SCRIPT_SNIPPET) -> None:
        (self.root / "docs" / "ISSUE3_SUITE_ROUTER_NEXT_STEPS.md").write_text(doc_text, encoding="utf-8")
        (self.root / "scripts" / "windows" / "show_google_issue3_suite_router_next_steps.ps1").write_text(
            script_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_google_route_contract_is_present(self):
        self.write_contract_files()

        audit = helper.build_suite_router_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_google_entrypoint_contract(self):
        self.write_contract_files(script_text=SCRIPT_SNIPPET.replace(
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "show_google_attached_html_validation_flow.ps1",
            1,
        ))

        audit = helper.build_suite_router_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_suite_router_next_steps.ps1", failing_paths)

    def test_text_report_surfaces_failure_count(self):
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_suite_router_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Suite-Router Next-Steps Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self):
        self.write_contract_files(doc_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()
