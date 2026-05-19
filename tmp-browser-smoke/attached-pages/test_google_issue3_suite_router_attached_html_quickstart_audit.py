import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_suite_router_attached_html_quickstart_audit as helper


DOC_SNIPPET = """# Issue #3 Suite-Router Attached HTML Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1
python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars --input '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
```
"""


HELPER_SNIPPET = """function Format-AttachedPagesSidecarAuditCommand {
    $command = 'python .\\\\tmp-browser-smoke\\\\attached-pages\\\\start_attached_pages_catalog.py --audit-sidecars'
}

$helper = [ordered]@{
    commands = [ordered]@{
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
        suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
    }
}

Write-Host (("  Attached pages audit:        {0}") -f $helper.commands.attached_pages_sidecar_audit)
Write-Host (("  Issue-specific Google check: {0}") -f $helper.commands.google_issue3_attached_html_surface_check)
Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)
"""


class GoogleIssue3SuiteRouterAttachedHtmlQuickstartAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        doc_text: str = DOC_SNIPPET,
        helper_text: str = HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_suite_router_attached_html_quickstart.ps1").write_text(
            helper_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_sidecar_audit_line(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars --input '<attached-html-root>'\n",
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars --input '<attached-html-root>'",
            failing_snippets,
        )

    def test_build_audit_reports_missing_issue_specific_google_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host (("  Issue-specific Google check: {0}") -f $helper.commands.google_issue3_attached_html_surface_check)\n',
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Suite-Router Attached HTML Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()