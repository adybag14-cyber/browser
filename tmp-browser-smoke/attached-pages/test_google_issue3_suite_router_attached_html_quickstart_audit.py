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

REPLAY_NOTE_SNIPPET = """# Issue #3 Windows Replay Attached HTML Quickstart

Keep these companion notes nearby:
- `docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1
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

REPLAY_HELPER_SNIPPET = """$helper = [ordered]@{
    commands = [ordered]@{
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
    }
}

Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)
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
        replay_note_text: str = REPLAY_NOTE_SNIPPET,
        helper_text: str = HELPER_SNIPPET,
        replay_helper_text: str = REPLAY_HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text,
            encoding="utf-8",
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            replay_note_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_suite_router_attached_html_quickstart.ps1").write_text(
            helper_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_windows_replay_attached_html_quickstart.ps1").write_text(
            replay_helper_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertEqual(0, audit["missing_path_count"])
        self.assertEqual([], audit["missing_paths"])
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

    def test_build_audit_reports_missing_bundle_suite_surface_line(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_suite_catalog_helper_line(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1\n",
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1",
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

    def test_build_audit_reports_missing_google_attached_bridge_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            'Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)',
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_note_bridge(self) -> None:
        self.write_contract_files(
            replay_note_text=REPLAY_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1\n",
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_helper_output(self) -> None:
        self.write_contract_files(
            replay_helper_text=REPLAY_HELPER_SNIPPET.replace(
                'Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)\n',
                "",
            )
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1", failing_paths)

    def test_missing_path_summary_groups_multiple_expectations_for_one_path(self) -> None:
        self.write_contract_files(
            doc_text="# drifted\n"
        )

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md", summary)
        self.assertGreater(
            summary["docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md"]["missing_expectation_count"],
            1,
        )
        self.assertIn(
            "fail-fast checker visible",
            summary["docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md"]["first_missing_purpose"],
        )

    def test_text_report_surfaces_grouped_missing_paths(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Missing paths:", report)
        self.assertIn("docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md (", report)
        self.assertIn(
            "First missing purpose: The suite-router attached HTML quickstart keeps its fail-fast checker visible before the narrower route is trusted.",
            report,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_suite_router_attached_html_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Suite-Router Attached HTML Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("Missing paths:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1", report)

    def test_cli_json_output_returns_nonzero_and_grouped_summary_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertGreater(payload["missing_path_count"], 0)
        self.assertEqual(
            "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
            payload["missing_paths"][0]["path"],
        )
        self.assertGreater(
            payload["missing_paths"][0]["missing_expectation_count"],
            1,
        )


if __name__ == "__main__":
    unittest.main()
