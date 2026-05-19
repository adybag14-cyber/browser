import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_html_target_bundle_proof_entrypoint_audit as helper


DOC_SNIPPET = """# Issue #3 Attached HTML Target-Bundle Proof Entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
```
"""


HELPER_SNIPPET = """$entrypoint = [ordered]@{
    bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleArguments
    local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $fixtureSurfaceArguments
    bundle_suite_surface_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $reentryArguments
    notes = @(
        'Use bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.'
    )
}

Write-Host (("  Surface check: {0}") -f $entrypoint.bundle_surface_check_command)
Write-Host (("  Surface check: {0}") -f $entrypoint.local_html_fixture_surface_check_command)
Write-Host (("  Suite surface: {0}") -f $entrypoint.bundle_suite_surface_command)
Write-Host (("  Probe:         {0}") -f $entrypoint.local_html_fixture_probe_command)
"""


class GoogleIssue3AttachedHtmlTargetBundleProofEntrypointAuditTests(unittest.TestCase):
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
        (
            self.root / "docs" / "ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md"
        ).write_text(doc_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
        ).write_text(helper_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_proof_entrypoint_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_note_checker(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_proof_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md", failing_paths)

    def test_build_audit_reports_missing_bundle_surface_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host (("  Surface check: {0}") -f $entrypoint.bundle_surface_check_command)\n',
                "",
            )
        )

        audit = helper.build_proof_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_bundle_guidance(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "Use bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.",
                "drifted proof guidance",
            )
        )

        audit = helper.build_proof_entrypoint_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.",
            failing_snippets,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_proof_entrypoint_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn(
            "Google Issue #3 Attached HTML Target-Bundle Proof Entrypoint Audit", report
        )
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            report,
        )

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n", helper_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()