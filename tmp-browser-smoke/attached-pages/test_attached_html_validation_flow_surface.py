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
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlFlowMetadata {
    return [ordered]@{
        validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }
        allow_missing_local_assets = $AllowMissingLocalAssets
        search_roots = if ($UsingExplicitInputPath) { @() } else { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) }
    }
}

function Get-AttachedHtmlValidationHint {
    if (($GoogleStyle -and $hasGoogleSearchSignals) -or $hasGoogleSearchSignals) {
        return [ordered]@{
            change_area = "google-attached-html"
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($hasApplicationSignals) {
        return [ordered]@{
            change_area = "input"
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($hasDenseAssetSignals) {
        return [ordered]@{
            change_area = "rendering"
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

function Get-AttachedHtmlOverallRecommendation {
    if ($BundleRecommendation -and $BundleRecommendation.overall_recommendation -and $BundleRecommendation.overall_recommendation.bundle_validation_profile) {
        $bundleOverall = $BundleRecommendation.overall_recommendation
        return [ordered]@{
            change_area = "attached-html-target-bundle"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
            follow_up = $bundleOverall.bundle_surface_check
            bundle_validation_profile = $bundleOverall.bundle_validation_profile
            bundle_locked_input_count = $bundleOverall.bundle_locked_input_count
            bundle_surface_check = $bundleOverall.bundle_surface_check
            bundle_asset_closure = $bundleOverall.bundle_asset_closure
            bundle_flow = $bundleOverall.bundle_flow
            bundle_runner = $bundleOverall.bundle_runner
            bundle_summary = $bundleOverall.bundle_summary
        }
    }

    if ($GoogleStyle -or ($Hints | Where-Object { $_.change_area -eq "google-attached-html" })) {
        return [ordered]@{
            change_area = "google-attached-html"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "input" }) {
        return [ordered]@{
            change_area = "input"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "rendering" }) {
        return [ordered]@{
            change_area = "rendering"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
    }
}

$attachedAssetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath)
$assetClosureChecker = Join-Path $repoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"
$assetClosureJson = (& $assetClosureChecker @assetClosureArgs) -join [Environment]::NewLine
$assetClosureAudit = $assetClosureJson | ConvertFrom-Json -Depth 10
$helperPath = if ($GoogleStyle) {
    Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
}
$helperArgs["ManualGoogleStyle"] = $true
$helperArgs["LeaveOpen"] = $true
$helperArgs["Json"] = $true
$attachedHtmlHints = Get-AttachedHtmlValidationHints -ResolvedInputPath $resolvedInputPath -GoogleStyle ([bool]$GoogleStyle)
$attachedHtmlBundleRecommendation = Get-AttachedHtmlTargetBundleRecommendation -RepoRoot $repoRoot -ResolvedInputPath $resolvedInputPath
$overallRecommendation = Get-AttachedHtmlOverallRecommendation -Hints $attachedHtmlHints -GoogleStyle ([bool]$GoogleStyle) -BundleRecommendation $attachedHtmlBundleRecommendation
$result = [ordered]@{
    attached_html = $attachedHtmlMetadata
    missing_asset_audit = $attachedAssetAudit
    asset_closure_audit = $assetClosureAudit
    fixture_hints = $attachedHtmlHints
    overall_recommendation = $overallRecommendation
    flow = $helperJson | ConvertFrom-Json -Depth 10
}
Write-Host "Attached HTML validation flow"
Write-Host ("Inputs discovered: {0}" -f $attachedHtmlMetadata.input_count)
Write-Host ("Input mode: {0}" -f $attachedHtmlMetadata.input_mode)
Write-Host ("Validation mode: {0}" -f $attachedHtmlMetadata.validation_mode)
Write-Host "Per-page bounded validation hints:"
Write-Host ("Overall first bounded step: {0}" -f $overallRecommendation.first_step)
Write-Host ("Overall follow-up: {0}" -f $overallRecommendation.follow_up)
Write-Host ("Bundle validation profile: {0}" -f $overallRecommendation.bundle_validation_profile)
Write-Host ("Bundle surface check: {0}" -f $overallRecommendation.bundle_surface_check)
Write-Host ("Bundle asset-closure check: {0}" -f $overallRecommendation.bundle_asset_closure)
Write-Host ("Bundle flow helper: {0}" -f $overallRecommendation.bundle_flow)
Write-Host ("Bundle runner: {0}" -f $overallRecommendation.bundle_runner)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-validation-flow-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlValidationFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow_script = read_text(cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1")

    def test_flow_metadata_keeps_validation_mode_and_asset_closure_markers(self) -> None:
        metadata_block = extract_function_block(self.flow_script, "Get-AttachedHtmlFlowMetadata")
        self.assertIn('validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }', metadata_block)
        self.assertIn("allow_missing_local_assets = $AllowMissingLocalAssets", metadata_block)
        self.assertIn("search_roots = if ($UsingExplicitInputPath) { @() } else { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) }", metadata_block)

    def test_validation_hint_keeps_google_input_rendering_and_general_routes(self) -> None:
        hint_block = extract_function_block(self.flow_script, "Get-AttachedHtmlValidationHint")
        self.assertIn('change_area = "google-attached-html"', hint_block)
        self.assertIn(r"show_google_attached_html_validation_flow.ps1", hint_block)
        self.assertIn(r"run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle", hint_block)
        self.assertIn('change_area = "input"', hint_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea input", hint_block)
        self.assertIn(r"run_localhost_html_validation_recommended.ps1 -Wait", hint_block)
        self.assertIn('change_area = "rendering"', hint_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea rendering", hint_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea network", hint_block)
        self.assertIn('change_area = "attached-html"', hint_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea attached-html", hint_block)
        self.assertIn(r"show_attached_html_validation_flow.ps1", hint_block)

    def test_overall_recommendation_keeps_bundle_and_fallback_priority_surfaces(self) -> None:
        recommendation_block = extract_function_block(self.flow_script, "Get-AttachedHtmlOverallRecommendation")
        self.assertIn('change_area = "attached-html-target-bundle"', recommendation_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle", recommendation_block)
        for marker in (
            "bundle_validation_profile",
            "bundle_locked_input_count",
            "bundle_surface_check",
            "bundle_asset_closure",
            "bundle_flow",
            "bundle_runner",
            "bundle_summary",
        ):
            self.assertIn(marker, recommendation_block)
        self.assertIn('change_area = "google-attached-html"', recommendation_block)
        self.assertIn(r"show_google_attached_html_validation_flow.ps1", recommendation_block)
        self.assertIn('change_area = "input"', recommendation_block)
        self.assertIn('change_area = "rendering"', recommendation_block)
        self.assertIn('change_area = "attached-html"', recommendation_block)

    def test_flow_keeps_asset_closure_audit_and_json_result_shape(self) -> None:
        self.assertIn("Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath", self.flow_script)
        self.assertIn('Join-Path $repoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"', self.flow_script)
        self.assertIn("$assetClosureJson", self.flow_script)
        self.assertIn("$assetClosureAudit = $assetClosureJson | ConvertFrom-Json -Depth 10", self.flow_script)
        self.assertIn("Get-AttachedHtmlValidationHints -ResolvedInputPath $resolvedInputPath", self.flow_script)
        self.assertIn("Get-AttachedHtmlTargetBundleRecommendation -RepoRoot $repoRoot -ResolvedInputPath $resolvedInputPath", self.flow_script)
        self.assertIn("Get-AttachedHtmlOverallRecommendation -Hints $attachedHtmlHints", self.flow_script)
        for marker in (
            "attached_html = $attachedHtmlMetadata",
            "missing_asset_audit = $attachedAssetAudit",
            "asset_closure_audit = $assetClosureAudit",
            "fixture_hints = $attachedHtmlHints",
            "overall_recommendation = $overallRecommendation",
            "flow = $helperJson | ConvertFrom-Json -Depth 10",
        ):
            self.assertIn(marker, self.flow_script)

    def test_flow_keeps_localhost_helper_and_google_style_switching(self) -> None:
        self.assertIn('Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"', self.flow_script)
        self.assertIn('Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"', self.flow_script)
        self.assertIn('$helperArgs["ManualGoogleStyle"] = $true', self.flow_script)
        self.assertIn('$helperArgs["LeaveOpen"] = $true', self.flow_script)
        self.assertIn('$helperArgs["Json"] = $true', self.flow_script)

    def test_printed_output_keeps_bundle_and_hint_summary_lines(self) -> None:
        for marker in (
            'Write-Host "Attached HTML validation flow"',
            'Write-Host ("Inputs discovered: {0}" -f $attachedHtmlMetadata.input_count)',
            'Write-Host ("Input mode: {0}" -f $attachedHtmlMetadata.input_mode)',
            'Write-Host ("Validation mode: {0}" -f $attachedHtmlMetadata.validation_mode)',
            'Write-Host "Per-page bounded validation hints:"',
            'Write-Host ("Overall first bounded step: {0}" -f $overallRecommendation.first_step)',
            'Write-Host ("Overall follow-up: {0}" -f $overallRecommendation.follow_up)',
            'Write-Host ("Bundle validation profile: {0}" -f $overallRecommendation.bundle_validation_profile)',
            'Write-Host ("Bundle surface check: {0}" -f $overallRecommendation.bundle_surface_check)',
            'Write-Host ("Bundle asset-closure check: {0}" -f $overallRecommendation.bundle_asset_closure)',
            'Write-Host ("Bundle flow helper: {0}" -f $overallRecommendation.bundle_flow)',
            'Write-Host ("Bundle runner: {0}" -f $overallRecommendation.bundle_runner)',
        ):
            self.assertIn(marker, self.flow_script)


if __name__ == "__main__":
    unittest.main()
