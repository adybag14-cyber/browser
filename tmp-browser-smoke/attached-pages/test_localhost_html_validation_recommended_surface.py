import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
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
    "scripts/windows/show_localhost_html_validation_flow.ps1": r"""
$suiteHelper = '.\scripts\windows\show_headed_validation_suites.ps1'
$attachedHelper = '.\scripts\windows\run_attached_html_localhost_validation.ps1'
$sanitizedHelper = '.\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1'
$googleRunner = '.\scripts\windows\run_google_input_validation.ps1'
$googleAttachedFlowHelper = '.\scripts\windows\show_google_attached_html_validation_flow.ps1'
$attachedCommand = "powershell -ExecutionPolicy Bypass -File $attachedHelper -Port $Port$preferredInitialPageArgument -Wait"
$googleSavedFlowCommand = "powershell -ExecutionPolicy Bypass -File $googleAttachedFlowHelper -Port $Port$preferredInitialPageArgument"
$sanitizedCommand = "powershell -ExecutionPolicy Bypass -File $sanitizedHelper -InputPath '<saved-html-or-folder>' -Port $Port$preferredInitialPageArgument -Wait"
$googleManualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'"
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "suite-map"; command = "powershell -ExecutionPolicy Bypass -File $suiteHelper -ChangeArea manual-html" }
        [ordered]@{ name = "attached-auto"; command = $attachedCommand }
        [ordered]@{ name = "sanitized"; command = $sanitizedCommand }
        [ordered]@{ name = "google-flow"; command = $googleSavedFlowCommand }
        [ordered]@{ name = "google-manual"; command = $googleManualCommand }
    )
    notes = @(
        "Run the matching bounded suite first, then move into direct or staged localhost validation.",
        "Use attached-auto when the current run already has HTML snapshots under agent_files and you want the helper to auto-discover the inputs and preferred first page before the manual headed follow-up.",
        "Use sanitized when the saved inputs have Unicode-heavy filenames, were exported as standalone HTML files with sibling *_files assets, or need to be staged into one ASCII-safe localhost root before the headed browser starts.",
        "Use google-flow before google-manual when the saved-page follow-up is part of the Google-style headed typing investigation.",
        "When PreferredInitialPage is set, the attached-auto, summary, direct, staged, sanitized, Google-style flow, and Google manual commands keep that page as the first headed target."
    )
}
""",
    "scripts/windows/run_localhost_html_validation_recommended.ps1": r"""
function Get-AttachedHtmlInputPath {
    return @(Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle)
}

function Resolve-AttachedHtmlRunnerSelection {
    $bundleChecker = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
    $bundleRunner = Join-Path $PSScriptRoot "run_attached_html_target_bundle_validation.ps1"
    $attachedRunner = Join-Path $PSScriptRoot "run_attached_html_localhost_validation.ps1"
    return [pscustomobject]@{ runner_label = ".\scripts\windows\run_attached_html_target_bundle_validation.ps1"; validation_mode = $overall.bundle_validation_profile }
    return [pscustomobject]@{ runner_label = ".\scripts\windows\run_attached_html_localhost_validation.ps1"; validation_mode = if ($GoogleStyle) { "google-style" } else { "general" } }
}

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        Write-Host "Mode: direct saved-page root"
        Write-Host "Runner: .\scripts\windows\run_saved_page_localhost_validation.ps1"
    }
    "InputPath" {
        if ($attachedSelection.runner_label -like "*target_bundle*") {
            Write-Host "Mode: pinned attached HTML target bundle"
            Write-Host ("Validation mode: {0}" -f $attachedSelection.validation_mode)
            if ($AllowMissingLocalAssets) { Write-Host "Attached asset policy: degraded mode allowed" }
            $bundleArgs.AllowMissingLocalAssets = $true
        } elseif ($GoogleStyle) {
            Write-Host "Mode: staged attached HTML inputs"
            Write-Host "Validation mode: google-style"
            if ($AllowMissingLocalAssets) { Write-Host "Attached asset policy: degraded mode allowed" }
            $attachedArgs.AllowMissingLocalAssets = $true
        } else {
            Write-Host "Mode: sanitized saved-page inputs"
            Write-Host "Runner: .\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1"
        }
    }
    default {
        $attachedHtml = Get-AttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
        throw "No PageRoot or InputPath was provided, and no attached HTML files were found under: roots"
        if ($attachedSelection.runner_label -like "*target_bundle*") {
            Write-Host "Mode: auto-discovered attached HTML target bundle"
            if ($AllowMissingLocalAssets) { Write-Host "Attached asset policy: degraded mode allowed" }
            $bundleArgs.AllowMissingLocalAssets = $true
        } else {
            Write-Host "Mode: auto-discovered attached HTML"
            if ($GoogleStyle) { Write-Host "Validation mode: google-style" }
            if ($AllowMissingLocalAssets) { Write-Host "Attached asset policy: degraded mode allowed" }
            $attachedArgs.AllowMissingLocalAssets = $true
        }
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-localhost-html-recommended-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class LocalhostHtmlValidationRecommendedSurfaceTest(unittest.TestCase):
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
        cls.localhost_flow = read_text(cls.repo_root / "scripts/windows/show_localhost_html_validation_flow.ps1")
        cls.recommended_runner = read_text(cls.repo_root / "scripts/windows/run_localhost_html_validation_recommended.ps1")

    def test_manual_html_route_keeps_attached_catalog_follow_up(self) -> None:
        self.assertIn('$ChangeArea -eq "manual-html"', self.router)
        self.assertIn('Write-Route -Name "attached-pages-catalog-follow-up"', self.router)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', self.router)

    def test_localhost_flow_keeps_manual_html_google_and_sanitized_steps(self) -> None:
        for fragment in (
            'name = "suite-map"',
            'name = "attached-auto"',
            'name = "sanitized"',
            'name = "google-flow"',
            'name = "google-manual"',
            r".\scripts\windows\run_attached_html_localhost_validation.ps1",
            r".\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1",
            r".\scripts\windows\show_google_attached_html_validation_flow.ps1",
            r".\scripts\windows\run_google_input_validation.ps1",
            'Use google-flow before google-manual',
        ):
            self.assertIn(fragment, self.localhost_flow)

    def test_recommended_runner_keeps_bundle_google_style_and_sanitized_modes(self) -> None:
        for fragment in (
            "check_attached_html_target_bundle.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "run_attached_html_localhost_validation.ps1",
            'Write-Host "Mode: direct saved-page root"',
            'Write-Host "Mode: pinned attached HTML target bundle"',
            'Write-Host "Mode: staged attached HTML inputs"',
            'Write-Host "Mode: sanitized saved-page inputs"',
            'Write-Host "Mode: auto-discovered attached HTML target bundle"',
            'Write-Host "Mode: auto-discovered attached HTML"',
            'Validation mode: google-style',
            'No PageRoot or InputPath was provided, and no attached HTML files were found under:',
            '$bundleArgs.AllowMissingLocalAssets = $true',
            '$attachedArgs.AllowMissingLocalAssets = $true',
        ):
            self.assertIn(fragment, self.recommended_runner)


if __name__ == "__main__":
    unittest.main()
