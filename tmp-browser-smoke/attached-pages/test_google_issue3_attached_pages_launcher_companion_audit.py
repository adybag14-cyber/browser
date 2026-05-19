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
        windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments
        python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-sidecars')
        python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--audit-sidecars')
        python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--require-complete-sidecars', '--require-complete-assets')
        python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')
    }
    companion_paths = [ordered]@{
        launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'
        replay_route_shortcut_bridge_note = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    }
    notes = @(
        'Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.',
        'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.',
        'Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.',
        'Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.',
        'The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.'
    )
}

Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle)
Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)
Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)
Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)
Write-Host (("Launcher surface check: {0}") -f $helper.companion_paths.launcher_companion_surface_check)
Write-Host 'Replay re-entry helpers:'
Write-Host (("  Windows replay quick: {0}") -f $helper.helper_commands.windows_replay_quickstart)
Write-Host (("  Replay-route helper: {0}") -f $helper.helper_commands.replay_route_shortcut)
Write-Host (("Replay-route note:       {0}") -f $helper.companion_paths.replay_route_shortcut_bridge_note)
"""

README_SNIPPET = """Use scripts/windows/start_attached_pages_catalog.ps1 for Windows wrapper flow.
Use --audit-sidecars for sidecar-first checks.
Use --require-complete-sidecars \\
  --require-complete-assets before trusting localhost launch.
"""

WRAPPER_SNIPPET = """param(
    [string]$PreferredInitialPage,
    [string[]]$InputPath
)
$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage
$launcherArgs += "--audit-sidecars"
$launcherArgs += "--require-complete-sidecars"
$launcherArgs += "--require-complete-assets"
"""

PYTHON_LAUNCHER_SNIPPET = """parser.add_argument('--preferred-initial-page')
run_launcher(
    preferred_initial_page=args.preferred_initial_page,
)
"""

SHORTCUT_DOC_SNIPPET = """# Issue #3 Replay Route Shortcut Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```
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
        python_launcher_text: str = PYTHON_LAUNCHER_SNIPPET,
        shortcut_doc_text: str = SHORTCUT_DOC_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md").write_text(
            shortcut_doc_text, encoding="utf-8"
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
        (self.root / "tmp-browser-smoke" / "attached-pages" / "start_attached_pages_catalog.py").write_text(
            python_launcher_text, encoding="utf-8"
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

    def test_build_audit_reports_missing_surface_check_wiring(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "    surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments",
            failing_snippets,
        )

    def test_build_audit_reports_missing_launcher_surface_check_path(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "        launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'",
            failing_snippets,
        )

    def test_build_audit_reports_missing_google_strict_python_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)\n',
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_python_sidecar_preferred_page_wiring(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "        python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-sidecars')\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-sidecars')",
            failing_snippets,
        )

    def test_build_audit_reports_missing_strict_bundle_guidance(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.",
                "drifted strict guidance",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_cross_platform_guidance(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.",
                "drifted python guidance",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.",
            failing_snippets,
        )

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

    def test_build_audit_reports_missing_proof_surface_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)\n',
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_replay_reentry_section(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "Write-Host 'Replay re-entry helpers:'\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_replay_route_helper_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("  Replay-route helper: {0}") -f $helper.helper_commands.replay_route_shortcut)\n',
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_replay_route_note_path_mapping(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "        replay_route_shortcut_bridge_note = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "replay_route_shortcut_bridge_note = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_note_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("Replay-route note:       {0}") -f $helper.companion_paths.replay_route_shortcut_bridge_note)\n',
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1", failing_paths)

    def test_build_audit_reports_missing_replay_route_guidance(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
                "drifted replay-route note",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_note(self) -> None:
        self.write_contract_files(shortcut_doc_text="# drifted\n")

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md", failing_paths)

    def test_build_audit_reports_missing_strict_readme_text(self) -> None:
        self.write_contract_files(readme_text="Use scripts/windows/start_attached_pages_catalog.ps1\n")

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("tmp-browser-smoke/attached-pages/README.md", failing_paths)

    def test_build_audit_reports_missing_wrapper_sidecar_gate(self) -> None:
        self.write_contract_files(
            wrapper_text='param(\n    [string]$PreferredInitialPage,\n    [string[]]$InputPath\n)\n$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage\n$launcherArgs += "--audit-sidecars"\n$launcherArgs += "--require-complete-assets"\n'
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/start_attached_pages_catalog.ps1", failing_paths)

    def test_build_audit_reports_missing_wrapper_preferred_initial_page_handoff(self) -> None:
        self.write_contract_files(
            wrapper_text=WRAPPER_SNIPPET.replace(
                "$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage\n",
                "",
            )
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage",
            failing_snippets,
        )

    def test_build_audit_reports_missing_python_launcher_preferred_flag(self) -> None:
        self.write_contract_files(
            python_launcher_text=PYTHON_LAUNCHER_SNIPPET.replace("parser.add_argument('--preferred-initial-page')\n", "")
        )

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn("--preferred-initial-page", failing_snippets)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(wrapper_text="# drifted\n", python_launcher_text="# drifted\n")

        audit = helper.build_launcher_companion_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Attached-Pages Launcher Companion Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/start_attached_pages_catalog.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n", wrapper_text="# drifted\n", python_launcher_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()