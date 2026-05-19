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

WINDOWS_CATALOG_NOTE_SNIPPET = """# Issue #3 Windows Full-Use Attached HTML Catalog Quickstart

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -RequireCompleteAssets -PrintManifest
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
        attached_html_target_bundle_proof_entrypoint_note = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        windows_full_use_attached_html_catalog_quickstart_note = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
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

Write-Host ((("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle))
Write-Host ((("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle))
Write-Host 'Pinned bundle proof follow-up:'
Write-Host ((("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check))
Write-Host ((("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint))
Write-Host ((("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle))
Write-Host ((("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle))
Write-Host ((("Launcher surface check: {0}") -f $helper.companion_paths.launcher_companion_surface_check))
Write-Host ((("Bundle proof note:       {0}") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note))
Write-Host 'Replay re-entry helpers:'
Write-Host ((("  Windows replay quick: {0}") -f $helper.helper_commands.windows_replay_quickstart))
Write-Host ((("  Replay-route helper: {0}") -f $helper.helper_commands.replay_route_shortcut))
Write-Host ((("Windows catalog note:    {0}") -f $helper.companion_paths.windows_full_use_attached_html_catalog_quickstart_note))
Write-Host ((("Replay-route note:       {0}") -f $helper.companion_paths.replay_route_shortcut_bridge_note))
"""

CHECKER_SNIPPET = """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"Write-Host 'Pinned bundle proof follow-up:'\" -Purpose 'Launcher companion helper prints a dedicated proof follow-up section header.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Surface check:      {0}\\\") -f $helper.helper_commands.proof_surface_check)' -Purpose 'Launcher companion helper prints the pinned proof-entrypoint surface checker.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Proof entrypoint:   {0}\\\") -f $helper.helper_commands.proof_entrypoint)' -Purpose 'Launcher companion helper prints the pinned proof-entrypoint helper.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"Bundle proof note:       {0}\\\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)' -Purpose 'Launcher companion helper prints the pinned bundle proof note beside the companion paths.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.' -Purpose 'Launcher companion helper notes preserve when to hand control back into the pinned proof route after launcher preflight narrows the run to the known bundle.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments\\\" -Purpose 'Launcher companion helper keeps the Windows replay re-entry helper wired into its command map after sidecar, asset, or proof preflight.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments\\\" -Purpose 'Launcher companion helper keeps the narrower replay-route re-entry helper wired into its command map after preflight narrows the problem.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"Write-Host 'Replay re-entry helpers:'\\\" -Purpose 'Launcher companion helper prints a dedicated replay re-entry section header once proof-only follow-up is complete.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Windows replay quick: {0}\\\") -f $helper.helper_commands.windows_replay_quickstart)' -Purpose 'Launcher companion helper prints the Windows replay re-entry helper once preflight is complete.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Replay-route helper: {0}\\\") -f $helper.helper_commands.replay_route_shortcut)' -Purpose 'Launcher companion helper prints the narrower replay-route re-entry helper once preflight is complete.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.' -Purpose 'Launcher companion helper notes preserve when to hand control back to the Windows replay attached-html quickstart after launcher preflight.'),
(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.' -Purpose 'Launcher companion helper notes preserve when to prefer the shorter replay-route companion after launcher preflight narrows the problem.'),
"""

FULL_USE_ROUTE_NOTE_SNIPPET = """# Issue #3 Windows Full-Use Attached HTML Route

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'
```
"""

FULL_USE_ROUTE_CHECKER_SNIPPET = """(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars' -Purpose 'The Windows full-use route checker keeps guarding the wrapper-backed sidecar audit on the broader route note.'),
(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Purpose 'The Windows full-use route checker keeps guarding the replay-attached quickstart handoff on the broader route note.'),
(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath ''<bundle-html-or-folder>''' -Purpose 'The Windows full-use route checker keeps guarding the compact bundle-suite handoff on the broader route note.'),
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
        windows_catalog_note_text: str = WINDOWS_CATALOG_NOTE_SNIPPET,
        launcher_companion_text: str = LAUNCHER_COMPANION_SNIPPET,
        checker_text: str = CHECKER_SNIPPET,
        full_use_route_note_text: str = FULL_USE_ROUTE_NOTE_SNIPPET,
        full_use_route_checker_text: str = FULL_USE_ROUTE_CHECKER_SNIPPET,
        readme_text: str = README_SNIPPET,
        wrapper_text: str = WRAPPER_SNIPPET,
        python_launcher_text: str = PYTHON_LAUNCHER_SNIPPET,
        shortcut_doc_text: str = SHORTCUT_DOC_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md").write_text(
            windows_catalog_note_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md").write_text(
            shortcut_doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md").write_text(
            full_use_route_note_text, encoding="utf-8"
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_attached_pages_launcher_companion.ps1").write_text(
            launcher_companion_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1").write_text(
            checker_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1").write_text(
            full_use_route_checker_text,
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

    def assert_failing_path(self, audit: dict[str, object], path: str) -> None:
        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(path, failing_paths)

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_launcher_companion_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_catalog_note_path_on_helper_surface(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "        windows_full_use_attached_html_catalog_quickstart_note = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_catalog_note_output_on_helper_surface(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host ((("Windows catalog note:    {0}") -f $helper.companion_paths.windows_full_use_attached_html_catalog_quickstart_note))\n',
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_helper_proof_header_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "Write-Host 'Pinned bundle proof follow-up:'\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_helper_proof_surface_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host ((("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check))\n',
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_helper_proof_entrypoint_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host ((("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint))\n',
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_helper_bundle_proof_note_path(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                "        attached_html_target_bundle_proof_entrypoint_note = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_helper_bundle_proof_note_output(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host ((("Bundle proof note:       {0}") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note))\n',
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        )

    def test_build_audit_reports_missing_checker_proof_header_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"Write-Host 'Pinned bundle proof follow-up:'\" -Purpose 'Launcher companion helper prints a dedicated proof follow-up section header.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_proof_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Proof entrypoint:   {0}\\\") -f $helper.helper_commands.proof_entrypoint)' -Purpose 'Launcher companion helper prints the pinned proof-entrypoint helper.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_proof_surface_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Surface check:      {0}\\\") -f $helper.helper_commands.proof_surface_check)' -Purpose 'Launcher companion helper prints the pinned proof-entrypoint surface checker.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_bundle_proof_note_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"Bundle proof note:       {0}\\\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)' -Purpose 'Launcher companion helper prints the pinned bundle proof note beside the companion paths.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_proof_guidance_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.' -Purpose 'Launcher companion helper notes preserve when to hand control back into the pinned proof route after launcher preflight narrows the run to the known bundle.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_reentry_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Replay-route helper: {0}\\\") -f $helper.helper_commands.replay_route_shortcut)' -Purpose 'Launcher companion helper prints the narrower replay-route re-entry helper once preflight is complete.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_wiring_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments\\\" -Purpose 'Launcher companion helper keeps the Windows replay re-entry helper wired into its command map after sidecar, asset, or proof preflight.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_route_wiring_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments\\\" -Purpose 'Launcher companion helper keeps the narrower replay-route re-entry helper wired into its command map after preflight narrows the problem.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_header_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \\\"Write-Host 'Replay re-entry helpers:'\\\" -Purpose 'Launcher companion helper prints a dedicated replay re-entry section header once proof-only follow-up is complete.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_quick_output_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Windows replay quick: {0}\\\") -f $helper.helper_commands.windows_replay_quickstart)' -Purpose 'Launcher companion helper prints the Windows replay re-entry helper once preflight is complete.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_route_output_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Replay-route helper: {0}\\\") -f $helper.helper_commands.replay_route_shortcut)' -Purpose 'Launcher companion helper prints the narrower replay-route re-entry helper once preflight is complete.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_quickstart_guidance_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.' -Purpose 'Launcher companion helper notes preserve when to hand control back to the Windows replay attached-html quickstart after launcher preflight.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_checker_replay_route_guidance_guard(self) -> None:
        self.write_contract_files(
            checker_text=CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.' -Purpose 'Launcher companion helper notes preserve when to prefer the shorter replay-route companion after launcher preflight narrows the problem.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_catalog_quickstart_checker(self) -> None:
        self.write_contract_files(
            windows_catalog_note_text=WINDOWS_CATALOG_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        )

    def test_build_audit_reports_missing_catalog_quickstart_helper(self) -> None:
        self.write_contract_files(
            windows_catalog_note_text=WINDOWS_CATALOG_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        )

    def test_build_audit_reports_missing_catalog_quickstart_strict_manifest_step(self) -> None:
        self.write_contract_files(
            windows_catalog_note_text=WINDOWS_CATALOG_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -RequireCompleteAssets -PrintManifest\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        )

    def test_build_audit_reports_missing_full_use_route_catalog_checker(self) -> None:
        self.write_contract_files(
            full_use_route_note_text=FULL_USE_ROUTE_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        )

    def test_build_audit_reports_missing_full_use_route_catalog_helper(self) -> None:
        self.write_contract_files(
            full_use_route_note_text=FULL_USE_ROUTE_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        )

    def test_build_audit_reports_missing_full_use_route_change_area_quickstart(self) -> None:
        self.write_contract_files(
            full_use_route_note_text=FULL_USE_ROUTE_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        )

    def test_build_audit_reports_missing_full_use_route_checker_sidecar_guard(self) -> None:
        self.write_contract_files(
            full_use_route_checker_text=FULL_USE_ROUTE_CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars' -Purpose 'The Windows full-use route checker keeps guarding the wrapper-backed sidecar audit on the broader route note.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_full_use_route_checker_guard(self) -> None:
        self.write_contract_files(
            full_use_route_checker_text=FULL_USE_ROUTE_CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Purpose 'The Windows full-use route checker keeps guarding the replay-attached quickstart handoff on the broader route note.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_full_use_route_checker_bundle_suite_guard(self) -> None:
        self.write_contract_files(
            full_use_route_checker_text=FULL_USE_ROUTE_CHECKER_SNIPPET.replace(
                """(New-ValidationContentExpectation -Path \\\"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\\\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath ''<bundle-html-or-folder>''' -Purpose 'The Windows full-use route checker keeps guarding the compact bundle-suite handoff on the broader route note.'),\n""",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        )

    def test_build_audit_reports_missing_full_use_route_bundle_first_helper(self) -> None:
        self.write_contract_files(
            full_use_route_note_text=FULL_USE_ROUTE_NOTE_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath '<bundle-html-or-folder>'\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        )

    def test_build_audit_reports_missing_replay_route_bridge_checker(self) -> None:
        self.write_contract_files(
            shortcut_doc_text=SHORTCUT_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        )

    def test_build_audit_reports_missing_replay_route_bridge_helper(self) -> None:
        self.write_contract_files(
            shortcut_doc_text=SHORTCUT_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        )

    def test_build_audit_reports_missing_wrapper_audit_sidecars_forwarding(self) -> None:
        self.write_contract_files(
            wrapper_text=WRAPPER_SNIPPET.replace('$launcherArgs += "--audit-sidecars"\n', "")
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/start_attached_pages_catalog.ps1",
        )

    def test_build_audit_reports_missing_wrapper_preferred_page_parameter(self) -> None:
        self.write_contract_files(
            wrapper_text=WRAPPER_SNIPPET.replace("    [string]$PreferredInitialPage,\n", "")
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/start_attached_pages_catalog.ps1",
        )

    def test_build_audit_reports_missing_wrapper_preferred_page_reorder(self) -> None:
        self.write_contract_files(
            wrapper_text=WRAPPER_SNIPPET.replace(
                "$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "scripts/windows/start_attached_pages_catalog.ps1",
        )

    def test_build_audit_reports_missing_python_preferred_page_flag(self) -> None:
        self.write_contract_files(
            python_launcher_text=PYTHON_LAUNCHER_SNIPPET.replace(
                "parser.add_argument('--preferred-initial-page')\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        )

    def test_build_audit_reports_missing_python_preferred_page_threading(self) -> None:
        self.write_contract_files(
            python_launcher_text=PYTHON_LAUNCHER_SNIPPET.replace(
                "    preferred_initial_page=args.preferred_initial_page,\n",
                "",
            )
        )
        self.assert_failing_path(
            helper.build_launcher_companion_audit(self.root),
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        )

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
