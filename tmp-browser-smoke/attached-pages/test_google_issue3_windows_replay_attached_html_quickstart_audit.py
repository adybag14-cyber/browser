import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_replay_attached_html_quickstart_audit as helper


DOC_SNIPPET = """# Issue #3 Windows Replay Attached HTML Quickstart

- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`
- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```
"""


GOOGLE_ENTRYPOINT_DOC_SNIPPET = """# Issue #3 Google Attached HTML Entrypoint

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1
```
"""


TOP_LEVEL_SHORTCUT_DOC_SNIPPET = """# Issue #3 Top-Level Shortcut Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
```
"""


SHORTCUT_BRIDGE_DOC_SNIPPET = """# Issue #3 Replay-Route Shortcut Bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
```
"""


REPLAY_SCRIPT_SNIPPET = """$helper = [ordered]@{
    commands = [ordered]@{
        windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments
        attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.',
        'Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.',
        'Use top_level_shortcut_first after the suite-router sidecar or the broader top-level attached-page bridge when you want the newer top-level shortcut bridge reprinted before the route collapses into the shorter attached-page shortcut surface.',
        'Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.',
        'Use attached_bundle_proof_entrypoint when the replay is already pinned to the known three-page compatibility bundle and you want the proof-only follow-up helper kept visible beside the proof surface checker before the route widens again.',
        'Use replay_route_shortcut after the top-level shortcut bridge, the attached-page shortcut, or replay_shortcuts when you want the narrower replay-route companion surfaced before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.'
    )
}

Write-Host (("  Replay surface check:    {0}") -f $helper.commands.windows_replay_attached_html_surface_check)
Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Suite-catalog guide:      {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Google issue bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)
Write-Host (("  Top-level shortcut:       {0}") -f $helper.commands.top_level_shortcut_first)
Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)
Write-Host (("  Bundle proof check:       {0}") -f $helper.commands.attached_bundle_proof_surface_check)
Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)
Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)
Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)
Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)
"""


GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand
        broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $googleAttachedHtmlSurfaceCheckArguments
        google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Use google_attached_html_sidecar_audit when the current saved export may be missing its whole sibling `_files` bundle and you want that simpler failure mode ruled in or out before the broader surface check or the deeper asset audit.',
        'Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.',
        'Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.',
        'Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.'
    )
}

Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)
Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)
Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)
Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host (("  Sidecar audit:         {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)
Write-Host (("  Broader surface check: {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)
Write-Host (("  Asset closure audit:   {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)
Write-Host (("  Google attached flow:  {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
"""


TOP_LEVEL_SHORTCUT_SCRIPT_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
    }
}

Write-Host (("  11. Shortcut entry:            {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  12. Windows replay quick:      {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Companion helpers:"))
Write-Host (("  Shortcut entrypoint:    {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Windows replay quick:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Replay route:           {0}") -f $entrypoint.helper_commands.replay_route_shortcut)
"""


REPLAY_ROUTE_SHORTCUT_SCRIPT_SNIPPET = """$entrypoint = [ordered]@{
    helper_commands = [ordered]@{
        replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand
    }
    notes = @(
        'Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.'
    )
}

Write-Host (("  8. Replay-to-Windows: {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
"""


REPLAY_ROUTE_SHORTCUT_CHECKER_SNIPPET = """docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md
show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1
"""


REPLAY_SHORTCUTS_WINDOWS_REPLAY_BRIDGE_SNIPPET = """$bridge = [ordered]@{
    commands = [ordered]@{
        windows_replay_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use windows_replay_quickstart as the default next helper whenever no explicit bundle inputs, saved summary, or non-default repo root need to take precedence first.'
    )
}

Write-Host (("  Replay quickstart check:  {0}") -f $bridge.commands.windows_replay_surface_check)
Write-Host (("  Windows replay quick:     {0}") -f $bridge.commands.windows_replay_quickstart)
"""


LAUNCHER_COMPANION_SNIPPET = """$helper = [ordered]@{
    helper_commands = [ordered]@{
        proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments
        proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments
    }
    notes = @(
        'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.'
    )
}

Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)
Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)
"""


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartAuditTests(unittest.TestCase):
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
        google_entrypoint_doc_text: str = GOOGLE_ENTRYPOINT_DOC_SNIPPET,
        top_level_shortcut_doc_text: str = TOP_LEVEL_SHORTCUT_DOC_SNIPPET,
        shortcut_bridge_doc_text: str = SHORTCUT_BRIDGE_DOC_SNIPPET,
        replay_script_text: str = REPLAY_SCRIPT_SNIPPET,
        google_entrypoint_script_text: str = GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET,
        top_level_shortcut_script_text: str = TOP_LEVEL_SHORTCUT_SCRIPT_SNIPPET,
        replay_route_shortcut_script_text: str = REPLAY_ROUTE_SHORTCUT_SCRIPT_SNIPPET,
        replay_route_shortcut_checker_text: str = REPLAY_ROUTE_SHORTCUT_CHECKER_SNIPPET,
        replay_shortcuts_windows_replay_bridge_text: str = REPLAY_SHORTCUTS_WINDOWS_REPLAY_BRIDGE_SNIPPET,
        launcher_companion_text: str = LAUNCHER_COMPANION_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md").write_text(
            google_entrypoint_doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md").write_text(
            top_level_shortcut_doc_text, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md").write_text(
            shortcut_bridge_doc_text, encoding="utf-8"
        )
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        ).write_text(replay_script_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_google_attached_html_entrypoint.ps1"
        ).write_text(google_entrypoint_script_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_top_level_shortcut_first_entrypoint.ps1"
        ).write_text(top_level_shortcut_script_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_replay_route_shortcut_entrypoint.ps1"
        ).write_text(replay_route_shortcut_script_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "check_google_issue3_replay_route_shortcut_validation_surface.ps1"
        ).write_text(replay_route_shortcut_checker_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1"
        ).write_text(replay_shortcuts_windows_replay_bridge_text, encoding="utf-8")
        (
            self.root
            / "scripts"
            / "windows"
            / "show_google_issue3_attached_pages_launcher_companion.ps1"
        ).write_text(launcher_companion_text, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_replay_surface_check_command(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_route_surface_check_output(self) -> None:
        self.write_contract_files(
            replay_script_text=REPLAY_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_suite_catalog_guidance(self) -> None:
        self.write_contract_files(
            replay_script_text=REPLAY_SCRIPT_SNIPPET.replace(
                "Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.",
                "drifted suite note",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_google_entrypoint_command(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_google_bridge_output(self) -> None:
        self.write_contract_files(
            replay_script_text=REPLAY_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Google issue bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_google_entrypoint_sidecar_audit_command(self) -> None:
        self.write_contract_files(
            google_entrypoint_doc_text=GOOGLE_ENTRYPOINT_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
            failing_snippets,
        )

    def test_build_audit_reports_missing_google_entrypoint_asset_audit_wiring(self) -> None:
        self.write_contract_files(
            google_entrypoint_script_text=GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET.replace(
                "        google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_google_entrypoint_broader_surface_note(self) -> None:
        self.write_contract_files(
            google_entrypoint_script_text=GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET.replace(
                "Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.",
                "drifted broader surface note",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_google_entrypoint_ladder_flow_output(self) -> None:
        self.write_contract_files(
            google_entrypoint_script_text=GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET.replace(
                'Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_google_entrypoint_companion_flow_output(self) -> None:
        self.write_contract_files(
            google_entrypoint_script_text=GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Google attached flow:  {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_google_entrypoint_flow_guidance(self) -> None:
        self.write_contract_files(
            google_entrypoint_script_text=GOOGLE_ENTRYPOINT_SCRIPT_SNIPPET.replace(
                "Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.",
                "drifted flow note",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_shortcut_surface_check_command(self) -> None:
        self.write_contract_files(
            shortcut_bridge_doc_text=SHORTCUT_BRIDGE_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_shortcut_helper_command(self) -> None:
        self.write_contract_files(
            shortcut_bridge_doc_text=SHORTCUT_BRIDGE_DOC_SNIPPET.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_to_windows_output(self) -> None:
        self.write_contract_files(
            replay_route_shortcut_script_text=REPLAY_ROUTE_SHORTCUT_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_replay_to_windows_guidance(self) -> None:
        self.write_contract_files(
            replay_route_shortcut_script_text=REPLAY_ROUTE_SHORTCUT_SCRIPT_SNIPPET.replace(
                "Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.",
                "drifted replay-to-windows note",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_replay_route_checker_proof_note_reference(self) -> None:
        self.write_contract_files(
            replay_route_shortcut_checker_text=REPLAY_ROUTE_SHORTCUT_CHECKER_SNIPPET.replace(
                "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_replay_route_checker_bridge_reference(self) -> None:
        self.write_contract_files(
            replay_route_shortcut_checker_text=REPLAY_ROUTE_SHORTCUT_CHECKER_SNIPPET.replace(
                "show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_replay_bridge_windows_quickstart_output(self) -> None:
        self.write_contract_files(
            replay_shortcuts_windows_replay_bridge_text=REPLAY_SHORTCUTS_WINDOWS_REPLAY_BRIDGE_SNIPPET.replace(
                'Write-Host (("  Windows replay quick:     {0}") -f $bridge.commands.windows_replay_quickstart)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_replay_bridge_default_handoff_guidance(self) -> None:
        self.write_contract_files(
            replay_shortcuts_windows_replay_bridge_text=REPLAY_SHORTCUTS_WINDOWS_REPLAY_BRIDGE_SNIPPET.replace(
                "Use windows_replay_quickstart as the default next helper whenever no explicit bundle inputs, saved summary, or non-default repo root need to take precedence first.",
                "drifted bridge note",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "Use windows_replay_quickstart as the default next helper whenever no explicit bundle inputs, saved summary, or non-default repo root need to take precedence first.",
            failing_snippets,
        )

    def test_build_audit_reports_missing_proof_companion_note(self) -> None:
        self.write_contract_files(
            doc_text=DOC_SNIPPET.replace(
                "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`\n",
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", failing_paths)

    def test_build_audit_reports_missing_launcher_companion_proof_bridge(self) -> None:
        self.write_contract_files(
            launcher_companion_text=LAUNCHER_COMPANION_SNIPPET.replace(
                'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)\n',
                "",
            )
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
            failing_paths,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(
            replay_script_text="# drifted\n",
            google_entrypoint_script_text="# drifted\n",
            replay_route_shortcut_script_text="# drifted\n",
            replay_route_shortcut_checker_text="# drifted\n",
            replay_shortcuts_windows_replay_bridge_text="# drifted\n",
            launcher_companion_text="# drifted\n",
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Replay Attached HTML Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            report,
        )

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(
            doc_text="# drifted\n",
            google_entrypoint_doc_text="# drifted\n",
            top_level_shortcut_doc_text="# drifted\n",
            shortcut_bridge_doc_text="# drifted\n",
            google_entrypoint_script_text="# drifted\n",
            replay_route_shortcut_script_text="# drifted\n",
            replay_route_shortcut_checker_text="# drifted\n",
            replay_shortcuts_windows_replay_bridge_text="# drifted\n",
            launcher_companion_text="# drifted\n",
        )

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()