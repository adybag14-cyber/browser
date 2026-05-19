import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_replay_shortcuts_audit as helper


DOC_SNIPPET = """# Issue #3 Replay Shortcuts

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1
```
"""


HELPER_SNIPPET = """$shortcuts = [ordered]@{
    helper_commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleFirstArguments
        replay_shortcuts_windows_replay_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Arguments $bundleFirstArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use runner_patch_next_step after the safe-route wrapper or reuse-current-outputs helper names one of the three current runner-patch states; when RepoRoot or SummaryPath is already in play, this command now keeps that same replay context attached to the next-step helper.',
        'Use fresh_safe_route_replay when current issue #3 outputs may be stale or missing and no explicit bundle inputs are already pinned. Use reuse_current_outputs only when the current saved outputs are already trusted.'
    )
}

Write-Host (("Recommended first helper: {0}") -f $shortcuts.recommended_first_helper_command)
Write-Host (("  Windows full-use route:      {0}") -f $shortcuts.read_first_commands.windows_full_use_attached_html_route)
Write-Host (("  Replay->Windows bridge:      {0}") -f $shortcuts.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
Write-Host (("  Runner next-step helper:     {0}") -f $shortcuts.helper_commands.runner_patch_next_step)
Write-Host (("  Fresh safe replay:           {0}") -f $shortcuts.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:       {0}") -f $shortcuts.helper_commands.reuse_current_outputs)
"""


class GoogleIssue3ReplayShortcutsAuditTests(unittest.TestCase):
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
        (self.root / "docs" / "ISSUE3_REPLAY_SHORTCUTS.md").write_text(doc_text, encoding="utf-8")
        (self.root / "scripts" / "windows" / "show_google_issue3_replay_shortcuts.ps1").write_text(
            helper_text, encoding="utf-8"
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_shortcuts_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_safe_route_doc_entry(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_shortcuts_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_runner_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host (("  Runner next-step helper:     {0}") -f $shortcuts.helper_commands.runner_patch_next_step)\n',
                "",
            )
        )

        audit = helper.build_replay_shortcuts_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_replay_shortcuts.ps1", failing_paths)

    def test_build_audit_reports_missing_reuse_outputs_command(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments\n",
                "",
            )
        )

        audit = helper.build_replay_shortcuts_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_replay_shortcuts.ps1", failing_paths)

    def test_build_audit_reports_missing_windows_route_doc_entry(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_shortcuts_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1",
            failing_snippets,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_replay_shortcuts_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Replay Shortcuts Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_replay_shortcuts.ps1", report)

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