from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md": """
    # Issue #3 Windows Replay Quickstart

    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1
    .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
    """,
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md": """
    # Issue #3 Windows Replay Attached HTML Quickstart

    docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md
    docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
    """,
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md": """
    # Issue #3 Google Attached HTML Validation Flow

    docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_shortcut_entrypoint.ps1
    """,
    "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1": r"""
    New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file"
    New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file"
    New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file"
    New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file"
    New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file"
    New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file"
    New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1'
    New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1'
    New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1'
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot"
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot"
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments"
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageArguments"
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host ((\"  Google attached check:    {0}\") -f $helper.commands.google_attached_html_surface_check)'
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host ((\"  Google attached flow:     {0}\") -f $helper.commands.google_attached_html_validation_flow)'
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host ((\"  Google issue bridge:      {0}\") -f $helper.commands.google_attached_html_entrypoint)'
    New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host ((\"  Launcher companion:       {0}\") -f $helper.commands.attached_pages_launcher_companion)'
    """,
    "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1": r"""
    suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
    google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
    google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
    attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageArguments
    attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
    attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments
    attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments
    top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
    replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
    Write-Host ((\"  Suite-catalog guide:      {0}\") -f $helper.commands.suite_catalog_entrypoints)
    Write-Host ((\"  Google attached check:    {0}\") -f $helper.commands.google_attached_html_surface_check)
    Write-Host ((\"  Google attached flow:     {0}\") -f $helper.commands.google_attached_html_validation_flow)
    Write-Host ((\"  Google issue bridge:      {0}\") -f $helper.commands.google_attached_html_entrypoint)
    Write-Host ((\"  Launcher companion:       {0}\") -f $helper.commands.attached_pages_launcher_companion)
    Write-Host ((\"  Bundle suite surface:     {0}\") -f $helper.commands.attached_bundle_suite_surface)
    Write-Host ((\"  Bundle proof check:       {0}\") -f $helper.commands.attached_bundle_proof_surface_check)
    Write-Host ((\"  Bundle proof entry:       {0}\") -f $helper.commands.attached_bundle_proof_entrypoint)
    Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.
    Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.
    Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page asset-closure and preferred-initial-page helper visible after the dedicated Google-shaped attached-page surface check and before the route narrows back into the suite-router sidecar or the shorter attached-page shortcut.
    Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.
    Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.
    Use attached_bundle_proof_entrypoint when the replay is already pinned to the known three-page compatibility bundle and you want the proof-only follow-up helper kept visible beside the proof surface checker before the route widens again.
    """,
    "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1": r"""
    proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments
    proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments
    windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments
    replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments
    Write-Host ((\"  Surface check:      {0}\") -f $helper.helper_commands.proof_surface_check)
    Write-Host ((\"  Proof entrypoint:   {0}\") -f $helper.helper_commands.proof_entrypoint)
    Write-Host ((\"  Windows replay quick: {0}\") -f $helper.helper_commands.windows_replay_quickstart)
    Write-Host ((\"  Replay-route helper: {0}\") -f $helper.helper_commands.replay_route_shortcut)
    Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.
    Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.
    Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.
    docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md
    """,
    "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1": r"""
    windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
    Write-Host ((\"  12. Windows replay quick:      {0}\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
    Write-Host ((\"  Windows replay quick:   {0}\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
    """,
    "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1": r"""
    replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand
    Write-Host ((\"  8. Replay-to-Windows: {0}\") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
    Write-Host ((\"  Replay-to-Windows:    {0}\") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
    Write-Host ((\"  Replay bridge check:  {0}\") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)
    Write-Host ((\"  Windows replay quick: {0}\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-windows-replay-attached-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class WindowsReplayAttachedHtmlQuickstartSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.windows_replay_quickstart = read_text(
            cls.repo_root / "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        )
        cls.replay_attached_quickstart = read_text(
            cls.repo_root / "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
        )
        cls.google_attached_flow = read_text(
            cls.repo_root / "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"
        )
        cls.route_helper = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        )
        cls.launcher_companion = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1"
        )
        cls.top_level_shortcut = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1"
        )
        cls.replay_route_shortcut = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1"
        )

    def test_replay_quickstart_note_keeps_bundle_and_suite_catalog_surfaces_visible(self) -> None:
        for fragment in (
            "check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1",
            "show_google_issue3_suite_catalog_entrypoints.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(fragment, self.windows_replay_quickstart)

    def test_attached_replay_note_keeps_google_and_proof_followups_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
            "check_google_attached_html_validation_surface.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        ):
            self.assertIn(fragment, self.replay_attached_quickstart)

    def test_google_attached_flow_note_keeps_replay_and_bundle_bridges_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
            "show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_google_issue3_replay_route_shortcut_entrypoint.ps1",
            "show_google_issue3_attached_html_shortcut_entrypoint.ps1",
        ):
            self.assertIn(fragment, self.google_attached_flow)

    def test_surface_checker_keeps_key_references_and_route_contracts_visible(self) -> None:
        for fragment in (
            'New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"',
            'New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1"',
            "check_google_attached_html_validation_surface.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "show_google_issue3_attached_pages_launcher_companion.ps1",
            'Write-Host ((\\"  Google attached check:    {0}\\") -f $helper.commands.google_attached_html_surface_check)',
            'Write-Host ((\\"  Google attached flow:     {0}\\") -f $helper.commands.google_attached_html_validation_flow)',
            'Write-Host ((\\"  Google issue bridge:      {0}\\") -f $helper.commands.google_attached_html_entrypoint)',
            'Write-Host ((\\"  Launcher companion:       {0}\\") -f $helper.commands.attached_pages_launcher_companion)',
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_helper_keeps_google_launcher_bundle_and_shortcut_commands_visible(self) -> None:
        for fragment in (
            "suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1'",
            "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot",
            "google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
            "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments",
            "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageArguments",
            "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments",
            "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments",
            "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments",
            "top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments",
            "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
            'Write-Host ((\\"  Suite-catalog guide:      {0}\\") -f $helper.commands.suite_catalog_entrypoints)',
            'Write-Host ((\\"  Google attached check:    {0}\\") -f $helper.commands.google_attached_html_surface_check)',
            'Write-Host ((\\"  Google attached flow:     {0}\\") -f $helper.commands.google_attached_html_validation_flow)',
            'Write-Host ((\\"  Google issue bridge:      {0}\\") -f $helper.commands.google_attached_html_entrypoint)',
            'Write-Host ((\\"  Launcher companion:       {0}\\") -f $helper.commands.attached_pages_launcher_companion)',
            'Write-Host ((\\"  Bundle suite surface:     {0}\\") -f $helper.commands.attached_bundle_suite_surface)',
            'Write-Host ((\\"  Bundle proof check:       {0}\\") -f $helper.commands.attached_bundle_proof_surface_check)',
            'Write-Host ((\\"  Bundle proof entry:       {0}\\") -f $helper.commands.attached_bundle_proof_entrypoint)',
            "Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.",
            "Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.",
            "Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page asset-closure and preferred-initial-page helper visible after the dedicated Google-shaped attached-page surface check and before the route narrows back into the suite-router sidecar or the shorter attached-page shortcut.",
            "Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.",
            "Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.",
            "Use attached_bundle_proof_entrypoint when the replay is already pinned to the known three-page compatibility bundle and you want the proof-only follow-up helper kept visible beside the proof surface checker before the route widens again.",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_launcher_companion_keeps_proof_and_reentry_handoffs_visible(self) -> None:
        for fragment in (
            "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments",
            "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments",
            "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments",
            "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments",
            'Write-Host ((\\"  Surface check:      {0}\\") -f $helper.helper_commands.proof_surface_check)',
            'Write-Host ((\\"  Proof entrypoint:   {0}\\") -f $helper.helper_commands.proof_entrypoint)',
            'Write-Host ((\\"  Windows replay quick: {0}\\") -f $helper.helper_commands.windows_replay_quickstart)',
            'Write-Host ((\\"  Replay-route helper: {0}\\") -f $helper.helper_commands.replay_route_shortcut)',
            "Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.",
            "Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.",
            "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
        ):
            self.assertIn(fragment, self.launcher_companion)

    def test_shortcut_helpers_keep_windows_replay_bridge_visible(self) -> None:
        for fragment in (
            "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments",
            'Write-Host ((\\"  12. Windows replay quick:      {0}\\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
            'Write-Host ((\\"  Windows replay quick:   {0}\\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        ):
            self.assertIn(fragment, self.top_level_shortcut)

        for fragment in (
            "replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand",
            'Write-Host ((\\"  8. Replay-to-Windows: {0}\\") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
            'Write-Host ((\\"  Replay-to-Windows:    {0}\\") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
            'Write-Host ((\\"  Replay bridge check:  {0}\\") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)',
            'Write-Host ((\\"  Windows replay quick: {0}\\") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        ):
            self.assertIn(fragment, self.replay_route_shortcut)


if __name__ == "__main__":
    unittest.main()
