import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_attached_pages_launcher_companion_audit as helper


DOC_SNIPPET = """# Issue #3 Windows Replay Attached HTML Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```
"""

LAUNCHER_COMPANION_SNIPPET = """$helper = [ordered]@{
    surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments
    helper_commands = [ordered]@{
        wrapper_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')
        wrapper_google_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars', 'RequireCompleteAssets')
        proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments
        proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments
        python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @('--require-complete-sidecars', '--require-complete-assets')
        python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')
    }
    notes = @(
        'Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.',
        'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.'
    )
}

Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle)
Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)
Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)
Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)
"""

README_SNIPPET = """Use scripts/windows/start_attached_pages_catalog.ps1 for Windows wrapper flow.
Use --audit-sidecars for sidecar-first checks.
Use --require-complete-sidecars \\
  --require-complete-assets before trusting localhost launch.
"""

WRAPPER_SNIPPET = """$launcherArgs += "--audit-sidecars"
$launcherArgs += "--require-complete-assets"
"""


class GoogleIssue3AttachedPagesLauncherCompanionAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)
        (self.root / "tmp-browser-smoke" / "attached-pages").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        doc_text: str = DOC_SNIPPET,
        launcher_companion_text: str = LAUNCHER_COMPANION_SNIPPET,
        readme_text: str = README_SNIPPET,
        wrapper_text: str = WRAPPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_attached_pages_launcher_companion.ps1").write_text(
            launcher_companion_text,
            encoding="utf-8",
        )
        (self.root / "tmp-browser-smoke" / "attached-pages" / "README.md").write_text(
            readme_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "start_attached_pages_catalog.ps1").write_text(
            wrapper_text, encoding="utf-8"
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_helper_command(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", failing_paths)

    def test_build_audit_reports_missing_proof_bridge_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_strict_readme_text(self) -> None:
        self.write_contract_files(readme_text="Use scripts/windows/start_attached_pages_catalog.ps1\n")

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("tmp-browser-smoke/attached-pages/README.md", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(wrapper_text="# drifted\n")

        audit = helper.build_launcher_companion_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Attached-Pages Launcher Companion Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/start_attached_pages_catalog.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n", wrapper_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()