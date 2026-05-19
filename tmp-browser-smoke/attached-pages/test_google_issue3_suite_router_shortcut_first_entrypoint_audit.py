import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_suite_router_shortcut_first_entrypoint_audit as helper


REPLAY_QUICKSTART_SNIPPET = """# Issue #3 Windows Replay Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
```
"""


SHORTCUT_BRIDGE_SNIPPET = """# Issue #3 Suite-Router Shortcut Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
```
"""


HELPER_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        suite_router_shortcut_surface_check = $suiteRouterShortcutSurfaceCheckCommand
        suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_attached_html_asset_audit = $googleAttachedHtmlAssetClosureCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Use google_attached_html_asset_audit when missing sidecars or local asset drift might explain the current Google-shaped attached-page failure and you want the deeper audit reprinted before the narrower issue-specific checker or bridge takes over.',
        'Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.'
    )
}

Write-Host ((\"  7. Shortcut surface:       {0}\") -f $entrypoint.helper_commands.suite_router_shortcut_surface_check)
Write-Host ((\" 12. Google surface check:   {0}\") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host ((\" 13. Google asset audit:     {0}\") -f $entrypoint.helper_commands.google_attached_html_asset_audit)
Write-Host ((\" 14. Issue-specific check:   {0}\") -f $entrypoint.helper_commands.google_issue3_attached_html_surface_check)
Write-Host ((\" 15. Google entrypoint:      {0}\") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host ((\" 18. Replay-route shortcut:  {0}\") -f $entrypoint.helper_commands.replay_route_shortcut)
"""


class GoogleIssue3SuiteRouterShortcutFirstEntrypointAuditTests(unittest.TestCase):
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
        replay_quickstart_text: str = REPLAY_QUICKSTART_SNIPPET,
        shortcut_bridge_text: str = SHORTCUT_BRIDGE_SNIPPET,
        helper_text: str = HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md").write_text(
            replay_quickstart_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md").write_text(
            shortcut_bridge_text, encoding="utf-8"
        )
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_suite_router_shortcut_first_entrypoint.ps1"
        ).write_text(helper_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_shortcut_first_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_quickstart_checker(self) -> None:
        self.write_contract_files(
            replay_quickstart_text=REPLAY_QUICKSTART_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_shortcut_first_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [
            result["snippet"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_bridge_asset_audit(self) -> None:
        self.write_contract_files(
            shortcut_bridge_text=SHORTCUT_BRIDGE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle\n",
                "",
            )
        )

        audit = helper.build_shortcut_first_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [
            result["snippet"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle",
            failing_snippets,
        )

    def test_build_audit_reports_missing_helper_replay_route_shortcut(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments\n",
                "",
            )
        )

        audit = helper.build_shortcut_first_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_helper_default_next_note(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.",
                "drifted note",
            )
        )

        audit = helper.build_shortcut_first_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [
            result["snippet"] for result in audit["results"] if not result["exists"]
        ]
        self.assertIn(
            "Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.",
            failing_snippets,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_shortcut_first_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn(
            "Google Issue #3 Suite-Router Shortcut-First Entrypoint Audit", report
        )
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
            report,
        )

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(shortcut_bridge_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()