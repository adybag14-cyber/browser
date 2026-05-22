import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlValidationHint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle
    )

    $leaf = [System.IO.Path]::GetFileName($Path)
    $pathLower = $Path.ToLowerInvariant()
    $rawLower = ""

    $hasSearchField = $rawLower -match "<(input|textarea)[^>]+name\s*=\s*['`\""""]q['`\""""]" -or
        $rawLower -match "(id|class|name)\s*=\s*['`\""""](apjfqb|gsfi|tsf|btnk)['`\""""]"
    $hasGoogleSafetySignals = $rawLower -match "google safety|safety centre|online safety|privacy"
    $hasGoogleSearchSignals = $pathLower -match "google" -and $hasSearchField -and -not $hasGoogleSafetySignals
    $hasApplicationSignals = $pathLower -match "job|application|apply|greenhouse" -or
        $rawLower -match "job application|greenhouse|type\s*=\s*['`\""""]submit['`\""""]|aria-label\s*=\s*['`\""""]apply['`\""""]"
    $hasDenseAssetSignals = $pathLower -match "_files" -or
        $rawLower -match "jquery\.datatables|bootstrap|min\.css|_files/" -or
        ([regex]::Matches($rawLower, "<link\b").Count -ge 6) -or
        ([regex]::Matches($rawLower, "<script\b").Count -ge 6)

    if (($GoogleStyle -and $hasGoogleSearchSignals) -or $hasGoogleSearchSignals) {
        return [ordered]@{
            change_area = "google-attached-html"
            summary = "Google-style search or query page. Keep the issue #3 localhost-first validation flow ahead of manual follow-up."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($hasApplicationSignals) {
        return [ordered]@{
            change_area = "input"
            summary = "Form-heavy or application-style page. Start with shared form-controls and inline input gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($hasDenseAssetSignals) {
        return [ordered]@{
            change_area = "rendering"
            summary = "Asset-heavy saved page. Start with layout/rendering plus stylesheet or image gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        summary = "General attached page. Start with the closest bounded suite for the subsystem you changed, then use the attached-page localhost flow."
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

function Get-AttachedHtmlOverallRecommendation {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Hints,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        $BundleRecommendation
    )

    if ($BundleRecommendation -and $BundleRecommendation.overall_recommendation -and $BundleRecommendation.overall_recommendation.bundle_validation_profile) {
        $bundleOverall = $BundleRecommendation.overall_recommendation
        return [ordered]@{
            change_area = "attached-html-target-bundle"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
            follow_up = $bundleOverall.bundle_surface_check
            summary = "Known three-page attached HTML compatibility bundle detected. Keep the bundle-aware route pinned before the broader generic attached-page flow."
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
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-flow-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlValidationFlowHintsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow = read_text(
            cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1"
        )

    def test_per_page_hint_logic_keeps_google_input_rendering_and_general_routes(self) -> None:
        expected_fragments = (
            'change_area = "google-attached-html"',
            "Google-style search or query page.",
            r"show_google_attached_html_validation_flow.ps1",
            r"run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle",
            'change_area = "input"',
            "Form-heavy or application-style page.",
            r"show_headed_validation_suites.ps1 -ChangeArea input",
            r"run_localhost_html_validation_recommended.ps1 -Wait",
            'change_area = "rendering"',
            "Asset-heavy saved page.",
            r"show_headed_validation_suites.ps1 -ChangeArea rendering",
            r"show_headed_validation_suites.ps1 -ChangeArea network",
            'change_area = "attached-html"',
            "General attached page.",
            r"show_headed_validation_suites.ps1 -ChangeArea attached-html",
            r"show_attached_html_validation_flow.ps1",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.flow)

    def test_google_and_asset_detection_signals_stay_present(self) -> None:
        expected_fragments = (
            'name\\s*=\\s*[\'`\\""""]q',
            '(apjfqb|gsfi|tsf|btnk)',
            "google safety|safety centre|online safety|privacy",
            "job|application|apply|greenhouse",
            "job application|greenhouse|type\\s*=\\s*[(",
            "jquery\\.datatables|bootstrap|min\\.css|_files/",
            "[regex]::Matches($rawLower, \"<link\\b\").Count -ge 6",
            "[regex]::Matches($rawLower, \"<script\\b\").Count -ge 6",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.flow)

    def test_overall_recommendation_prefers_bundle_then_google_then_input_then_rendering(self) -> None:
        expected_fragments = (
            'change_area = "attached-html-target-bundle"',
            r"show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "Known three-page attached HTML compatibility bundle detected.",
            "bundle_validation_profile",
            "bundle_surface_check",
            "bundle_asset_closure",
            "bundle_flow",
            "bundle_runner",
            "bundle_summary",
            'change_area = "google-attached-html"',
            'change_area = "input"',
            'change_area = "rendering"',
            'change_area = "attached-html"',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.flow)

    def test_overall_recommendation_keeps_expected_first_steps_and_follow_ups(self) -> None:
        expected_fragments = (
            r"show_google_attached_html_validation_flow.ps1",
            r"run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle",
            r"show_headed_validation_suites.ps1 -ChangeArea input",
            r"run_localhost_html_validation_recommended.ps1 -Wait",
            r"show_headed_validation_suites.ps1 -ChangeArea rendering",
            r"show_headed_validation_suites.ps1 -ChangeArea network",
            r"show_headed_validation_suites.ps1 -ChangeArea attached-html",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.flow)


if __name__ == "__main__":
    unittest.main()
