import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_replay_quickstart_audit as helper


REPLAY_DOC_SNIPPET = """# Issue #3 Windows Replay Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
```
"""

REPLAY_ATTACHED_DOC_SNIPPET = """# Issue #3 Windows Replay Attached HTML Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
```
"""

HELPER_SNIPPET = """$helper = [ordered]@{
    replay_attached_html_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    commands = [ordered]@{
        windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_pages_launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        suite_router_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        replay_route_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart once the main replay quickstart narrows into the attached localhost branch, so the helper command and note stay paired on the same surface.',
        'Use attached_pages_launcher_surface_check and attached_pages_launcher_companion when the replay has already narrowed into attached localhost follow-up and you want the wrapper-backed sidecar, asset, manifest, and strict-launch ladder printed on one smaller surface before reopening the broader Google-shaped, top-level, or bundle-first branches.',
        'Use suite_router_shortcut_first after attached_html_shortcut when you want the narrower suite-router shortcut bridge reprinted before the route collapses into replay_shortcuts.',
        'Use replay_route and replay_route_shortcut_entrypoint when you want the broader issue #3 route or the narrower replay-route follow-up printed beside the shortcut helpers.'
    )
}

Write-Host ((\"  Launcher surface check:    {0}\") -f $helper.commands.attached_pages_launcher_surface_check)
Write-Host ((\"  Launcher companion:        {0}\") -f $helper.commands.attached_pages_launcher_companion)
Write-Host ((\"  Router shortcut:           {0}\") -f $helper.commands.suite_router_shortcut_first)
Write-Host ((\"  Route shortcut:            {0}\") -f $helper.commands.replay_route_shortcut_entrypoint)
"""


class GoogleIssue3WindowsReplayQuickstartAuditTests(unittest.TestCase):
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
        replay_doc_text: str = REPLAY_DOC_SNIPPET,
        replay_attached_doc_text: str = REPLAY_ATTACHED_DOC_SNIPPET,
        helper_text: str = HELPER_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md").write_text(
            replay_doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            replay_attached_doc_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_windows_replay_quickstart.ps1").write_text(
            helper_text, encoding="utf-8"
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_attached_checker(self) -> None:
        self.write_contract_files(
            replay_doc_text=REPLAY_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md", failing_paths)

    def test_build_audit_reports_missing_launcher_repo_root_route(self) -> None:
        self.write_contract_files(
            replay_attached_doc_text=REPLAY_ATTACHED_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", failing_paths)

    def test_build_audit_reports_missing_launcher_helper_wiring(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                "        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_replay_quickstart.ps1", failing_paths)

    def test_build_audit_reports_missing_suite_router_shortcut_doc_command(self) -> None:
        self.write_contract_files(
            replay_doc_text=REPLAY_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_shortcut_helper_output(self) -> None:
        self.write_contract_files(
            helper_text=HELPER_SNIPPET.replace(
                'Write-Host ((\"  Route shortcut:            {0}\") -f $helper.commands.replay_route_shortcut_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_windows_replay_quickstart.ps1", failing_paths)

    def test_build_audit_reports_missing_proof_note_reference(self) -> None:
        self.write_contract_files(
            replay_doc_text=REPLAY_DOC_SNIPPET.replace(
                "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
            failing_snippets,
        )

    def test_build_audit_reports_missing_proof_surface_checker(self) -> None:
        self.write_contract_files(
            replay_doc_text=REPLAY_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_proof_helper(self) -> None:
        self.write_contract_files(
            replay_doc_text=REPLAY_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            failing_snippets,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(helper_text="# drifted\n")

        audit = helper.build_replay_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Replay Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_windows_replay_quickstart.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(replay_doc_text="# drifted\n", helper_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()
