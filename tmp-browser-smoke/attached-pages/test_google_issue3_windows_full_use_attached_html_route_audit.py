import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_full_use_attached_html_route_audit as helper


WINDOWS_DOC_SNIPPET = """# Windows Full Use

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath \"<saved-html-or-folder>\" -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1
```
"""


ROUTE_DOC_SNIPPET = """# Issue #3 Windows Full-Use Attached HTML Route

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
```
"""


ROUTE_HELPER_SNIPPET = """$route = [ordered]@{
    helper_commands = [ordered]@{
        windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $browserAwareBundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserAwareBundleArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
    }
}

Write-Host (("  Surface checker:          {0}") -f $route.helper_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  4. Windows catalog qk:    {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  5. Replay attached qk:    {0}") -f $route.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 13. Bundle suite surface:  {0}") -f $route.helper_commands.attached_bundle_suite_surface)
Write-Host ((" 28. Bundle-first route:    {0}") -f $route.helper_commands.attached_bundle_first)
"""


CATALOG_HELPER_SNIPPET = """$helper = [ordered]@{
    helper_commands = [ordered]@{
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
    }
}
$helper.recommended_next_key = 'attached_pages_sidecar_audit'
"""


class GoogleIssue3WindowsFullUseAttachedHtmlRouteAuditTests(unittest.TestCase):
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
        windows_doc_text: str = WINDOWS_DOC_SNIPPET,
        route_doc_text: str = ROUTE_DOC_SNIPPET,
        route_helper_text: str = ROUTE_HELPER_SNIPPET,
        catalog_helper_text: str = CATALOG_HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "WINDOWS_FULL_USE.md").write_text(windows_doc_text, encoding="utf-8")
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md").write_text(
            route_doc_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_windows_full_use_attached_html_route.ps1").write_text(
            route_helper_text, encoding="utf-8"
        )
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1"
        ).write_text(catalog_helper_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_route_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_wrapper_sidecar_audit(self) -> None:
        self.write_contract_files(
            route_doc_text=ROUTE_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
                "",
            )
        )

        audit = helper.build_route_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_attached_output(self) -> None:
        self.write_contract_files(
            route_helper_text=ROUTE_HELPER_SNIPPET.replace(
                'Write-Host (("  5. Replay attached qk:    {0}") -f $route.helper_commands.windows_replay_attached_html_quickstart)\n',
                "",
            )
        )

        audit = helper.build_route_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1", failing_paths)

    def test_build_audit_reports_missing_bundle_suite_output(self) -> None:
        self.write_contract_files(
            route_helper_text=ROUTE_HELPER_SNIPPET.replace(
                'Write-Host ((" 13. Bundle suite surface:  {0}") -f $route.helper_commands.attached_bundle_suite_surface)\n',
                "",
            )
        )

        audit = helper.build_route_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1", failing_paths)

    def test_build_audit_reports_missing_catalog_helper_default(self) -> None:
        self.write_contract_files(catalog_helper_text="# drifted\n")

        audit = helper.build_route_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
            failing_paths,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(route_helper_text="# drifted\n", catalog_helper_text="# drifted\n")

        audit = helper.build_route_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Full-Use Attached HTML Route Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(route_doc_text="# drifted\n", catalog_helper_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()