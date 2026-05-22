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
        "The Google-shaped attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1.",
        "The dedicated issue #3 validation-router attached-html surface checker remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1."
    )
    return $notes
}

switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        $useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"
        $bundleFocused = $SuiteName -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        Write-Route -Name $SuiteName -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        $useGoogleStyleCatalog = $ChangeArea -eq "google-attached-html"
        $bundleFocused = $ChangeArea -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
}
""",
    "scripts/windows/show_google_attached_html_validation_flow.ps1": r"""
$base = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
$helperCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle -Port 8123"
$runnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Port 8123 -Wait"
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1"
$metadata = [ordered]@{
    validation_mode = "google-style"
    preferred_initial_page_mode = "google-style-auto"
    helper_command = $helperCommand
    runner_command = $runnerCommand
    surface_check_command = $SurfaceCheckCommand
    asset_closure_command = $base
}
""",
    "scripts/windows/start_attached_pages_catalog.ps1": r"""
param(
    [switch]$GoogleStyle,
    [switch]$PrintManifest,
    [switch]$AuditAssets,
    [switch]$AuditSidecars,
    [switch]$RequireCompleteSidecars,
    [switch]$RequireCompleteAssets
)

if ($GoogleStyle) {
    $launcherArgs += "--google-style"
}
if ($RequireCompleteSidecars) {
    $launcherArgs += "--require-complete-sidecars"
}
if ($RequireCompleteAssets) {
    $launcherArgs += "--require-complete-assets"
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-attached-html-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleAttachedHtmlValidationSurfaceTest(unittest.TestCase):
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
        cls.google_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_attached_html_validation_flow.ps1"
        )
        cls.catalog_launcher = read_text(
            cls.repo_root / "scripts/windows/start_attached_pages_catalog.ps1"
        )

    def test_router_keeps_google_attached_html_suite_and_change_area(self) -> None:
        self.assertIn('$SuiteName -eq "google-attached-html"', self.router)
        self.assertIn('$ChangeArea -eq "google-attached-html"', self.router)
        self.assertIn('$useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"', self.router)
        self.assertIn('$useGoogleStyleCatalog = $ChangeArea -eq "google-attached-html"', self.router)
        self.assertIn("Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog", self.router)
        self.assertIn('Write-Route -Name $SuiteName -Commands $commands -Notes $notes', self.router)
        self.assertIn('Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes', self.router)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', self.router)

    def test_attached_html_notes_keep_google_shaped_follow_up_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        self.assertIn("Google-shaped attached-page helper remains available", notes_block)
        self.assertIn("show_google_attached_html_validation_flow.ps1", notes_block)
        self.assertIn("validation-router attached-html surface checker", notes_block)

    def test_google_attached_html_helper_keeps_google_style_commands(self) -> None:
        self.assertIn("check_attached_html_local_asset_closure.ps1 -GoogleStyle", self.google_helper)
        self.assertIn("show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle", self.google_helper)
        self.assertIn("run_google_attached_html_validation.ps1", self.google_helper)
        self.assertIn("check_google_attached_html_validation_surface.ps1", self.google_helper)
        self.assertIn('validation_mode = "google-style"', self.google_helper)
        self.assertIn('preferred_initial_page_mode = "google-style-auto"', self.google_helper)

    def test_catalog_launcher_keeps_google_style_and_strict_bundle_flags(self) -> None:
        self.assertIn("[switch]$GoogleStyle", self.catalog_launcher)
        self.assertIn('$launcherArgs += "--google-style"', self.catalog_launcher)
        self.assertIn("[switch]$RequireCompleteSidecars", self.catalog_launcher)
        self.assertIn("[switch]$RequireCompleteAssets", self.catalog_launcher)
        self.assertIn('$launcherArgs += "--require-complete-sidecars"', self.catalog_launcher)
        self.assertIn('$launcherArgs += "--require-complete-assets"', self.catalog_launcher)


if __name__ == "__main__":
    unittest.main()
