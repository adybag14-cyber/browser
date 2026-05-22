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
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$GoogleStyle),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments)
    )
}

switch ($true) {
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        $useGoogleStyleCatalog = $ChangeArea -eq "google-attached-html"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)
        break
    }
}
""",
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlValidationHint {
    return [ordered]@{
        fixture = $leaf
        change_area = "attached-html"
        summary = "General attached page. Start with the closest bounded suite for the subsystem you changed, then use the attached-page localhost flow."
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

function Get-AttachedHtmlOverallRecommendation {
    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
    }
}

$helperPath = if ($GoogleStyle) {
    Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
}
""",
    "scripts/windows/start_attached_pages_catalog.ps1": r"""
if ($PrintManifest) {
    $launcherArgs += "--print-manifest"
} elseif ($AuditAssets) {
    $launcherArgs += "--audit-assets"
} elseif ($AuditSidecars) {
    $launcherArgs += "--audit-sidecars"
} else {
    $launcherArgs += @("--bind", $Bind, "--port", "$Port")
}
""",
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1": "# placeholder\n",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-manual-html-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class ManualHtmlValidationSurfaceTest(unittest.TestCase):
    FOLLOW_UP_SCRIPTS = (
        "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1",
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
        cls.attached_flow = read_text(
            cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1"
        )
        cls.catalog_launcher = read_text(
            cls.repo_root / "scripts/windows/start_attached_pages_catalog.ps1"
        )

    def test_manual_html_change_area_stays_on_attached_pages_catalog_follow_up(self) -> None:
        self.assertIn('$ChangeArea -eq "manual-html"', self.router)
        self.assertIn(
            'Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog',
            self.router,
        )
        self.assertIn(
            'Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes',
            self.router,
        )
        self.assertIn(
            'Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)',
            self.router,
        )

    def test_attached_html_notes_keep_manual_html_reuse_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        self.assertIn("manual-html change area still reuses this attached-pages catalog route", notes_block)
        self.assertIn("Start the catalog in one shell", notes_block)

    def test_general_attached_page_recommendation_stays_on_attached_html_route(self) -> None:
        hint_block = extract_function_block(self.attached_flow, "Get-AttachedHtmlValidationHint")
        self.assertIn('change_area = "attached-html"', hint_block)
        self.assertIn(
            r'bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"',
            hint_block,
        )
        self.assertIn(
            r'follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"',
            hint_block,
        )

        overall_block = extract_function_block(
            self.attached_flow, "Get-AttachedHtmlOverallRecommendation"
        )
        self.assertIn('change_area = "attached-html"', overall_block)
        self.assertIn(
            r'first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"',
            overall_block,
        )
        self.assertIn(
            r'follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"',
            overall_block,
        )
        self.assertIn(
            r'Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"',
            self.attached_flow,
        )

    def test_catalog_launcher_keeps_localhost_server_launch_path(self) -> None:
        self.assertIn('$launcherArgs += @("--bind", $Bind, "--port", "$Port")', self.catalog_launcher)
        self.assertIn('$launcherArgs += "--print-manifest"', self.catalog_launcher)
        self.assertIn('$launcherArgs += "--audit-assets"', self.catalog_launcher)
        self.assertIn('$launcherArgs += "--audit-sidecars"', self.catalog_launcher)

    def test_follow_up_scripts_exist_for_manual_html_route(self) -> None:
        for relative_path in self.FOLLOW_UP_SCRIPTS:
            self.assertTrue(
                (self.repo_root / relative_path).exists(),
                f"{relative_path} should exist for the manual-html follow-up ladder",
            )


if __name__ == "__main__":
    unittest.main()
