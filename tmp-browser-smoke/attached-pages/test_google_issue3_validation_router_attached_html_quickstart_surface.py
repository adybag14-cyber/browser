import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1": r"""
$references = @(
    @{ Path = "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" },
    @{ Path = "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" },
    @{ Path = "scripts/windows/check_google_attached_html_validation_surface.ps1" },
    @{ Path = "scripts/windows/show_google_attached_html_validation_flow.ps1" },
    @{ Path = "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" },
    @{ Path = "scripts/windows/check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" }
)

$contentExpectations = @(
    @{ Path = "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"; Snippet = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' },
    @{ Path = "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"; Snippet = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' },
    @{ Path = "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"; Snippet = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' },
    @{ Path = "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md"; Snippet = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'validation_router_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_validation_router_attached_html_quickstart_surface.ps1'' -RepoRootOverride $RepoRoot' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_attached_html_validation_surface.ps1'' -RepoRootOverride $RepoRoot' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_google_attached_html_validation_flow.ps1'' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'google_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'suite_catalog_entrypoints_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1'' -RepoRootOverride $RepoRoot' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'suite_router_next_steps = Format-HelperCommand -ScriptName ''show_google_issue3_suite_router_next_steps.ps1'' -Arguments $bundleArguments' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'attached_bundle_first = Format-HelperCommand -ScriptName ''show_google_issue3_attached_bundle_first_entrypoint.ps1'' -Arguments $browserAwareArguments' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Surface checker:            {0}\") -f $helper.commands.validation_router_attached_html_surface_check)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Google attached surface:     {0}\") -f $helper.commands.google_attached_html_surface_check)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Google attached flow:        {0}\") -f $helper.commands.google_attached_html_flow)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Google attached bridge:      {0}\") -f $helper.commands.google_attached_html_entrypoint)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Suite catalog surface:       {0}\") -f $helper.commands.suite_catalog_entrypoints_surface_check)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Next-step matrix:            {0}\") -f $helper.commands.suite_router_next_steps)' },
    @{ Path = "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"; Snippet = 'Write-Host ((\"  Bundle-first helper:         {0}\") -f $helper.commands.attached_bundle_first)' }
)
""",
    "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1": r"""
$helper = [ordered]@{
    commands = [ordered]@{
        validation_router_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_catalog_entrypoints_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -RepoRootOverride $RepoRoot
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserAwareArguments
    }
    notes = @(
        'Use suite_catalog_entrypoints_surface_check when RepoRoot, SummaryPath, or pinned InputPath values already matter and you want the suite-catalog surface to fail fast before this validation-router bridge hands control over to the broader issue #3 context-preserving route.'
    )
}

Write-Host 'Google issue #3 validation-router attached HTML quickstart'
Write-Host ((\"  Surface checker:            {0}\") -f $helper.commands.validation_router_attached_html_surface_check)
Write-Host ((\"  Google attached surface:     {0}\") -f $helper.commands.google_attached_html_surface_check)
Write-Host ((\"  Google attached flow:        {0}\") -f $helper.commands.google_attached_html_flow)
Write-Host ((\"  Google attached bridge:      {0}\") -f $helper.commands.google_attached_html_entrypoint)
Write-Host ((\"  Suite catalog surface:       {0}\") -f $helper.commands.suite_catalog_entrypoints_surface_check)
Write-Host ((\"  Next-step matrix:            {0}\") -f $helper.commands.suite_router_next_steps)
Write-Host ((\"  Bundle-first helper:         {0}\") -f $helper.commands.attached_bundle_first)
""",
    "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md": r"""
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1
docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md
""",
    "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md": r"""
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-validation-router-attached-html-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3ValidationRouterAttachedHtmlQuickstartSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1"
        )
        cls.quickstart = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1"
        )
        cls.note = read_text(
            cls.repo_root / "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md"
        )
        cls.windows_bridge_note = read_text(
            cls.repo_root / "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md"
        )

    def test_surface_checker_keeps_router_google_and_bundle_references(self) -> None:
        expected_fragments = (
            "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md",
            "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1",
            "scripts/windows/check_google_attached_html_validation_surface.ps1",
            "scripts/windows/show_google_attached_html_validation_flow.ps1",
            "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
            "scripts/windows/check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1",
            "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
            "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.surface_check)

    def test_surface_checker_keeps_note_and_helper_content_expectations(self) -> None:
        expected_fragments = (
            r'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1',
            r'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1',
            r'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1',
            "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md",
            "validation_router_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_validation_router_attached_html_quickstart_surface.ps1'' -RepoRootOverride $RepoRoot",
            "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_attached_html_validation_surface.ps1'' -RepoRootOverride $RepoRoot",
            "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_google_attached_html_validation_flow.ps1'' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
            "google_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments",
            "suite_catalog_entrypoints_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1'' -RepoRootOverride $RepoRoot",
            "suite_router_next_steps = Format-HelperCommand -ScriptName ''show_google_issue3_suite_router_next_steps.ps1'' -Arguments $bundleArguments",
            "attached_bundle_first = Format-HelperCommand -ScriptName ''show_google_issue3_attached_bundle_first_entrypoint.ps1'' -Arguments $browserAwareArguments",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.surface_check)

    def test_quickstart_keeps_printed_surface_check_and_follow_up_commands(self) -> None:
        expected_fragments = (
            'Write-Host ((\\"  Surface checker:            {0}\\") -f $helper.commands.validation_router_attached_html_surface_check)',
            'Write-Host ((\\"  Google attached surface:     {0}\\") -f $helper.commands.google_attached_html_surface_check)',
            'Write-Host ((\\"  Google attached flow:        {0}\\") -f $helper.commands.google_attached_html_flow)',
            'Write-Host ((\\"  Google attached bridge:      {0}\\") -f $helper.commands.google_attached_html_entrypoint)',
            'Write-Host ((\\"  Suite catalog surface:       {0}\\") -f $helper.commands.suite_catalog_entrypoints_surface_check)',
            'Write-Host ((\\"  Next-step matrix:            {0}\\") -f $helper.commands.suite_router_next_steps)',
            'Write-Host ((\\"  Bundle-first helper:         {0}\\") -f $helper.commands.attached_bundle_first)',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.quickstart)
        self.assertIn("Use suite_catalog_entrypoints_surface_check when RepoRoot, SummaryPath, or pinned InputPath values already matter", self.quickstart)

    def test_notes_keep_validation_router_bridge_visible_from_both_written_routes(self) -> None:
        self.assertIn(
            r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            self.note,
        )
        self.assertIn(
            r"powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_router_attached_html_quickstart.ps1",
            self.windows_bridge_note,
        )


if __name__ == "__main__":
    unittest.main()
