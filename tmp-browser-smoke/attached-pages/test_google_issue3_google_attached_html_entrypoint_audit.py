import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_google_attached_html_entrypoint_audit as helper


DOC_SNIPPET = """# Issue #3 Google Attached HTML Entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
```
"""

HELPER_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand
        broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $googleAttachedHtmlSurfaceCheckArguments
        google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Use google_attached_html_sidecar_audit when the current saved export may be missing its whole sibling `_files` bundle and you want that simpler failure mode ruled in or out before the broader surface check or the deeper asset audit.',
        'Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.',
        'Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.',
        'Use attached_bundle_change_area, attached_bundle_suite_surface, or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader issue #3 helpers.'
    )
}

Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)
Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)
Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)
Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host ((" 15. Bundle suite helper:  {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)
Write-Host ((" 16. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
"""


class GoogleIssue3GoogleAttachedHtmlEntrypointAuditTests(unittest.TestCase):
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
        (self.root / "docs" / "ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md").write_text(
            doc_text,
            encoding="utf-8",
        )
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_google_attached_html_entrypoint.ps1"
        ).write_text(helper_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_sidecar_audit_command(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
                "",
            )
        )

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md", failing_paths)

    def test_build_audit_reports_missing_issue_specific_checker_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)\n',
                "",
            )
        )

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
            failing_snippets,
        )

    def test_build_audit_reports_missing_broader_surface_guidance(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.",
                "drifted broader-surface note",
            )
        )

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_asset_closure_guidance(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.",
                "drifted asset note",
            )
        )

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_paths,
        )

    def test_missing_path_summary_groups_multiple_expectations_for_one_path(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md", summary)
        self.assertGreater(
            summary["docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md"][
                "missing_expectation_count"
            ],
            1,
        )
        self.assertIn(
            "issue-specific Google attached-html checker visible",
            summary["docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md"][
                "first_missing_purpose"
            ],
        )
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            summary["docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md"][
                "missing_snippets"
            ],
        )

    def test_missing_path_summary_keeps_helper_snippets_for_grouped_drift(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_google_attached_entrypoint_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        helper_summary = summary[
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1"
        ]
        self.assertGreater(helper_summary["missing_expectation_count"], 1)
        self.assertIn(
            "google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand",
            helper_summary["missing_snippets"],
        )
        self.assertIn(
            'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
            helper_summary["missing_snippets"],
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_google_attached_entrypoint_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Google Attached HTML Entrypoint Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            report,
        )

    def test_cli_json_output_returns_nonzero_and_grouped_summary_when_contract_drifts(
        self,
    ) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertGreater(payload["missing_path_count"], 0)
        self.assertEqual(
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            payload["missing_paths"][0]["path"],
        )
        self.assertGreater(
            payload["missing_paths"][0]["missing_expectation_count"],
            1,
        )
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
            payload["missing_paths"][0]["missing_snippets"],
        )

    def test_cli_json_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])
        self.assertIsNone(payload["missing_count"])
        self.assertIn("repo root does not exist:", payload["error"])

    def test_cli_text_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Google Issue #3 Google Attached HTML Entrypoint Audit", report)
        self.assertIn(f"Repo root: {missing_root}", report)
        self.assertIn("Error: repo root does not exist:", report)


if __name__ == "__main__":
    unittest.main()