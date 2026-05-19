import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import google_issue3_suite_router_handoff_audit as helper


WINDOWS_REPLAY_DOC = """# Issue #3 Windows Replay Quickstart

- `docs/ISSUE3_SUITE_ROUTER_HANDOFF.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\check_google_issue3_suite_router_handoff_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_suite_router_handoff.ps1
```
"""


REPLAY_DISCOVERY_DOC = """# Issue #3 Replay Discovery Handoff

```powershell
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\check_google_issue3_suite_router_handoff_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_suite_router_handoff.ps1
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```
"""


HANDOFF_SCRIPT = """$handoff = [ordered]@{
    bridge_sequence = [ordered]@{
        suite_router_surface_check = $handoffSurfaceCheckCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = $googleAttachedHtmlFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
    }
}

suite_router_surface_check = $handoffSurfaceCheckCommand
google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
google_attached_html_flow = $googleAttachedHtmlFlowCommand
google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments

Write-Host (("  5. Handoff surface check:         {0}") -f $handoff.bridge_sequence.suite_router_surface_check)
Write-Host (("  6. Google attached surface check: {0}") -f $handoff.bridge_sequence.google_attached_html_surface_check)
Write-Host (("  7. Google attached flow:          {0}") -f $handoff.bridge_sequence.google_attached_html_flow)
Write-Host (("  9. Google attached bridge:        {0}") -f $handoff.bridge_sequence.google_attached_html_entrypoint)
"""


class GoogleIssue3SuiteRouterHandoffAuditTests(unittest.TestCase):
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
        windows_replay_text: str = WINDOWS_REPLAY_DOC,
        replay_discovery_text: str = REPLAY_DISCOVERY_DOC,
        handoff_script_text: str = HANDOFF_SCRIPT,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md").write_text(
            windows_replay_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_REPLAY_DISCOVERY_HANDOFF.md").write_text(
            replay_discovery_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_suite_router_handoff.ps1").write_text(
            handoff_script_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_suite_router_handoff_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_discovery_helper(self) -> None:
        self.write_contract_files(
            replay_discovery_text=REPLAY_DISCOVERY_DOC.replace(
                "powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_suite_router_handoff.ps1\n",
                "",
            )
        )

        audit = helper.build_suite_router_handoff_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md", failing_paths)

    def test_build_audit_reports_missing_google_bridge_output(self) -> None:
        self.write_contract_files(
            handoff_script_text=HANDOFF_SCRIPT.replace(
                'Write-Host (("  9. Google attached bridge:        {0}") -f $handoff.bridge_sequence.google_attached_html_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_suite_router_handoff_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_suite_router_handoff.ps1", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(handoff_script_text="# drifted\n")

        audit = helper.build_suite_router_handoff_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Suite-Router Handoff Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_suite_router_handoff.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(windows_replay_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()