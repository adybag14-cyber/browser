import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_function_block(source: str, function_name: str) -> str:
    pattern = re.compile(
        rf"function\s+{re.escape(function_name)}[^\{{]*\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find function block for {function_name}")
    return match.group(0)


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-AttachedHtmlNotes {
    $notes = @(
        "Run the attached-pages sidecar audit first so missing sibling _files directories are visible before the browser is blamed.",
        "Run the attached-pages asset audit second so missing local assets stay visible before the browser is blamed.",
        "After the sidecar audit passes, reuse -RequireCompleteSidecars when you want the manifest or localhost catalog launch to fail fast on incomplete saved-page bundles.",
        "After the asset audit passes, reuse -RequireCompleteAssets when you want the manifest or localhost catalog launch to fail fast on incomplete saved-page asset sets.",
        "Pair -RequireCompleteSidecars with -RequireCompleteAssets when both bundle structure and local asset closure must be complete before replay.",
        "Use the attached-pages catalog wrapper to pin the current HTML bundle and expose short localhost routes at /, /manifest.json, /pages/<n>, /named/<slug>, and /raw/... .",
        "The broader attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1.",
        "The Google-shaped attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1.",
        "The issue #3 top-level attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1.",
        "The shorter issue #3 attached-page change-area quickstart remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1.",
        "The dedicated issue #3 validation-router attached-html surface checker remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1.",
        "The manual-html change area still reuses this attached-pages catalog route when you want a direct saved-page replay without a narrower bounded family.",
        "Start the catalog in one shell, then open the generated catalog or a manifest-backed short route from a second shell."
    )
    return $notes
}

function Get-AttachedHtmlRouteCommands {
    return @(
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets')),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
    )
}

$attachedCommands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage
Write-Route -Name "attached-html" -Commands $attachedCommands -Notes (Get-AttachedHtmlNotes)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage) -Notes (Get-AttachedHtmlNotes)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
""",
    "scripts/windows/start_attached_pages_catalog.ps1": "# placeholder\n",
    "scripts/windows/show_attached_html_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/show_google_attached_html_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": "# placeholder\n",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlValidationSurfaceTest(unittest.TestCase):
    FOLLOW_UP_SCRIPTS = (
        "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1",
        "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1",
        "scripts/windows/show_attached_html_validation_flow.ps1",
        "scripts/windows/show_google_attached_html_validation_flow.ps1",
        "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
    )

    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")

    def test_attached_html_route_commands_keep_audits_manifest_guards_and_local_browser_launch(self) -> None:
        commands_block = extract_function_block(self.router, "Get-AttachedHtmlRouteCommands")
        for required in (
            "AuditSidecars",
            "AuditAssets",
            "PrintManifest",
            "RequireCompleteSidecars",
            "RequireCompleteAssets",
            "http://127.0.0.1:8235/",
        ):
            self.assertIn(required, commands_block)

    def test_attached_html_notes_keep_bundle_and_localhost_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        self.assertIn("sidecar audit first", notes_block)
        self.assertIn("asset audit second", notes_block)
        self.assertIn("/manifest.json, /pages/<n>, /named/<slug>, and /raw/...", notes_block)
        self.assertIn("manual-html change area still reuses this attached-pages catalog route", notes_block)
        self.assertIn("Start the catalog in one shell", notes_block)

    def test_router_keeps_default_and_follow_up_attached_html_surfaces(self) -> None:
        default_surface = re.search(
            r'Write-Route\s+-Name\s+"attached-html"\s+-Commands\s+\$attachedCommands',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should keep the attached-html route")

        catalog_follow_up = re.search(
            r'Write-Route\s+-Name\s+"attached-pages-catalog-follow-up"\s+-Commands\s+\(Get-AttachedHtmlRouteCommands',
            self.router,
        )
        self.assertIsNotNone(
            catalog_follow_up,
            "change-area router should keep the attached-pages catalog follow-up route",
        )

        issue3_follow_up = re.findall(
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)',
            self.router,
        )
        self.assertGreaterEqual(
            len(issue3_follow_up),
            2,
            "default and change-area surfaces should both keep the issue #3 attached-html follow-up route",
        )

    def test_issue3_follow_up_stack_keeps_router_checker_and_bundle_helpers(self) -> None:
        commands_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpCommands")
        for script_name in (
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(script_name, commands_block)

        for relative_path in self.FOLLOW_UP_SCRIPTS:
            self.assertTrue(
                (self.repo_root / relative_path).exists(),
                f"{relative_path} should exist for the follow-up ladder",
            )


if __name__ == "__main__":
    unittest.main()
