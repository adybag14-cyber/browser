import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_replay_attached_html_quickstart_audit as helper


DOC_SNIPPET = """# Issue #3 Windows Replay Attached HTML Quickstart

- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
```
"""


SCRIPT_SNIPPET = """$helper = [ordered]@{
    commands = [ordered]@{
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.'
    )
}

Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)
Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)
Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)
"""


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self, *, doc_text: str = DOC_SNIPPET, script_text: str = SCRIPT_SNIPPET) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_windows_replay_attached_html_quickstart.ps1").write_text(
            script_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_proof_command(self) -> None:
        self.write_contract_files(doc_text=DOC_SNIPPET.replace(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\n",
            "",
        ))

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(script_text="# drifted\n")

        audit = helper.build_replay_attached_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Replay Attached HTML Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1", report)

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