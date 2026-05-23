import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_full_use_attached_bundle_bridge_audit as helper


WINDOWS_DOC_SNIPPET = """# Windows Full Use

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1
```
"""


BRIDGE_DOC_SNIPPET = """# Issue #3 Windows Full-Use Attached Bundle Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_bundle_first_bridge.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait
```
"""


BRIDGE_HELPER_SNIPPET = """$bridge = [ordered]@{
    commands = [ordered]@{
        windows_full_use_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedBrowserArguments
        windows_validation_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedBrowserArguments
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleChangeAreaArguments -RepoRootOverride $RepoRoot
        bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedBrowserArguments
        replay_route_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_bundle_first_bridge.ps1' -Arguments $sharedBrowserArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedBrowserArguments
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $sharedArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleBrowserArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleBrowserArguments -Switches @('Wait')
    }
}

Write-Host (("  Bundle-suite helper:  {0}") -f $bridge.commands.bundle_suite_surface)
Write-Host (("  Replay bundle bridge: {0}") -f $bridge.commands.replay_route_bundle_first)
Write-Host (("  Bundle-first helper:  {0}") -f $bridge.commands.bundle_first_entrypoint)
Write-Host (("  Bundle surface check: {0}") -f $bridge.commands.bundle_surface_check)
Write-Host (("  Bundle runner:        {0}") -f $bridge.commands.bundle_runner)
"""


SURFACE_CHECK_SNIPPET = """$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md" -Kind "file" -Purpose "Pinned three-page bundle bridge note for the Windows full-use route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1" -Kind "file" -Purpose "Pinned three-page bundle bridge helper for the Windows full-use route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced before the narrower bundle-first helper.")
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner for the pinned three-page route.")
)
"""


class GoogleIssue3WindowsFullUseAttachedBundleBridgeAuditTests(unittest.TestCase):
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
        bridge_doc_text: str = BRIDGE_DOC_SNIPPET,
        bridge_helper_text: str = BRIDGE_HELPER_SNIPPET,
        surface_check_text: str = SURFACE_CHECK_SNIPPET,
    ) -> None:
        (self.root / "docs" / "WINDOWS_FULL_USE.md").write_text(windows_doc_text, encoding="utf-8")
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md").write_text(
            bridge_doc_text, encoding="utf-8"
        )
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_windows_full_use_attached_bundle_bridge.ps1"
        ).write_text(bridge_helper_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1"
        ).write_text(surface_check_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_bridge_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_windows_doc_bridge_note(self) -> None:
        self.write_contract_files(
            windows_doc_text=WINDOWS_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1\n",
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_bundle_suite_note(self) -> None:
        self.write_contract_files(
            bridge_doc_text=BRIDGE_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'\n",
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'",
            failing_snippets,
        )

    def test_build_audit_reports_missing_bundle_runner_note(self) -> None:
        self.write_contract_files(
            bridge_doc_text=BRIDGE_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait\n",
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_bundle_bridge_wiring(self) -> None:
        self.write_contract_files(
            bridge_helper_text=BRIDGE_HELPER_SNIPPET.replace(
                "        replay_route_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_bundle_first_bridge.ps1' -Arguments $sharedBrowserArguments\n",
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1", failing_paths)

    def test_build_audit_reports_missing_bundle_runner_output(self) -> None:
        self.write_contract_files(
            bridge_helper_text=BRIDGE_HELPER_SNIPPET.replace(
                'Write-Host (("  Bundle runner:        {0}") -f $bridge.commands.bundle_runner)\n',
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1", failing_paths)

    def test_build_audit_reports_missing_surface_check_runner_reference(self) -> None:
        self.write_contract_files(
            surface_check_text=SURFACE_CHECK_SNIPPET.replace(
                '(New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner for the pinned three-page route.")\n',
                "",
            )
        )

        audit = helper.build_bridge_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1",
            failing_paths,
        )

    def test_missing_path_summary_groups_multiple_expectations(self) -> None:
        self.write_contract_files(bridge_helper_text="# drifted\n")

        audit = helper.build_bridge_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1", summary)
        helper_summary = summary["scripts/windows/show_google_issue3_windows_full_use_attached_bundle_bridge.ps1"]
        self.assertGreater(helper_summary["missing_expectation_count"], 1)
        self.assertIn(
            "broader Windows full-use attached HTML route wired",
            helper_summary["first_missing_purpose"],
        )
        self.assertIn(
            "show_google_issue3_windows_full_use_attached_html_route.ps1",
            helper_summary["first_missing_snippet"],
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(bridge_doc_text="# drifted\n", bridge_helper_text="# drifted\n")

        audit = helper.build_bridge_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Full-Use Attached Bundle Bridge Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("Missing path summary:", report)
        self.assertIn("First snippet:", report)
        self.assertIn("[FAIL] docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md", report)

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


if __name__ == "__main__":
    unittest.main()