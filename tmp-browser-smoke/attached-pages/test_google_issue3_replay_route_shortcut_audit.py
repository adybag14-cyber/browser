import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_replay_route_shortcut_audit as helper


DOC_SNIPPET = """# Issue #3 Replay-Route Shortcut Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_bundle_first_bridge.ps1
```
"""


REPLAY_ROUTE_SCRIPT_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    top_level_commands = [ordered]@{
        replay_route_shortcut_surface_check = $replayRouteShortcutSurfaceCheckCommand
    }
    notes = @(
        'Use google_attached_html_flow when the current attached inputs are already Google-shaped and you still want that narrower attached-page flow helper reprinted directly from the replay-route shortcut surface before deciding whether to narrow into the attached-page shortcut, replay shortcuts, the replay-shortcuts Windows replay attached-page bridge, the next-step matrix, contextual flow, the bundle-first branch, or the safe-route map.'
    )
}

Write-Host (("  Attached-page flow:   {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host (("  Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_flow)
Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
Write-Host (("  Windows replay quick: {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
"""


class GoogleIssue3ReplayRouteShortcutAuditTests(unittest.TestCase):
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
        script_text: str = REPLAY_ROUTE_SCRIPT_SNIPPET,
    ) -> None:
        (
            self.root / "docs" / "ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"
        ).write_text(doc_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_replay_route_shortcut_entrypoint.ps1"
        ).write_text(script_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_route_shortcut_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertEqual(0, audit["missing_path_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_google_attached_flow_note(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_route_shortcut_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [
            result["snippet"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_to_windows_output(self) -> None:
        self.write_contract_files(
            script_text=REPLAY_ROUTE_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)\n',
                "",
            )
        )

        audit = helper.build_replay_route_shortcut_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [
            result["path"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_bundle_first_wiring(self) -> None:
        self.write_contract_files(
            script_text=REPLAY_ROUTE_SCRIPT_SNIPPET.replace(
                "        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments\n",
                "",
            )
        )

        audit = helper.build_replay_route_shortcut_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [
            result["snippet"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments",
            failing_snippets,
        )

    def test_build_audit_groups_multiple_missing_expectations_by_path(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_replay_route_shortcut_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md", summary)
        self.assertEqual(1, audit["missing_path_count"])
        self.assertGreater(audit["missing_count"], 1)
        self.assertGreater(
            summary["docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"][
                "missing_expectation_count"
            ],
            1,
        )
        self.assertIn(
            "dedicated fail-fast checker visible",
            summary["docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"][
                "first_missing_purpose"
            ],
        )
        self.assertIn(
            "check_google_issue3_replay_route_shortcut_validation_surface.ps1",
            summary["docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"][
                "first_missing_snippet"
            ],
        )

    def test_text_report_surfaces_failure_summary(self) -> None:
        self.write_contract_files(script_text="# drifted\n")

        audit = helper.build_replay_route_shortcut_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Replay-Route Shortcut Audit", report)
        self.assertIn("Missing paths:", report)
        self.assertIn(
            "- scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1 (",
            report,
        )
        self.assertIn(
            "First snippet: replay_route_shortcut_surface_check = $replayRouteShortcutSurfaceCheckCommand",
            report,
        )

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n", script_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertGreater(payload["missing_path_count"], 0)

    def test_main_reports_missing_repo_root_in_json(self) -> None:
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

    def test_main_reports_missing_repo_root_in_text(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Google Issue #3 Replay-Route Shortcut Audit", report)
        self.assertIn(f"Repo root: {missing_root}", report)
        self.assertIn("Error: repo root does not exist:", report)


if __name__ == "__main__":
    unittest.main()
