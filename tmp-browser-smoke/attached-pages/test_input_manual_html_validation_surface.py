import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
)

switch ($true) {
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1"
        ) -Notes @(
            "Use the attached-pages catalog wrapper to pin the current HTML bundle and expose short localhost routes."
        )
        Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1",
            "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1"
        ) -Notes @(
            "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
        )
        break
    }
}
""",
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

    try {
        $rawLower = (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop).ToLowerInvariant()
    } catch {
        $rawLower = ""
    }

    $hasApplicationSignals = $pathLower -match "job|application|apply|greenhouse" -or
        $rawLower -match "job application|greenhouse|type\s*=\s*['`""]submit['`""]|aria-label\s*=\s*['`""]apply['`""]"
    $hasDenseAssetSignals = $pathLower -match "_files" -or
        $rawLower -match "jquery\.datatables|bootstrap|min\.css|_files/" -or
        ([regex]::Matches($rawLower, "<link\b").Count -ge 6) -or
        ([regex]::Matches($rawLower, "<script\b").Count -ge 6)

    if ($hasApplicationSignals) {
        return [ordered]@{
            fixture = $leaf
            change_area = "input"
            summary = "Form-heavy or application-style page. Start with shared form-controls and inline input gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($hasDenseAssetSignals) {
        return [ordered]@{
            fixture = $leaf
            change_area = "rendering"
            summary = "Asset-heavy saved page. Start with layout/rendering plus stylesheet or image gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        fixture = $leaf
        change_area = "attached-html"
        summary = "General attached page. Start with the closest bounded suite for the subsystem you changed, then use the attached-page localhost flow."
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
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

    if ($Hints | Where-Object { $_.change_area -eq "input" }) {
        return [ordered]@{
            change_area = "input"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
    }
}
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-manual-html-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputManualHtmlValidationSurfaceTest(unittest.TestCase):
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
        cls.attached_flow = read_text(cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1")
        cls.enter_submit_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")
        cls.label_click_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1")

    def test_default_router_keeps_bounded_input_route(self) -> None:
        self.assertIn('Write-Route -Name "input"', self.router)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1', self.router)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\label-click-probe.ps1', self.router)
        self.assertIn("bounded input checks already committed on this branch", self.router)
        self.assertIn("Use them before live-site or saved-page follow-up.", self.router)

    def test_input_change_area_keeps_bounded_input_route(self) -> None:
        change_area_surface = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"input"\s+-or\s+\$ChangeArea\s+-eq\s+"google-input"\s*\}\s*\{.*?Write-Route\s+-Name\s+"bounded-input".*?enter-submit-probe\.ps1.*?label-click-probe\.ps1.*?smallest shared headed checks for typing, focus, and Enter submit',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(change_area_surface, "input change area should keep the bounded input route and its typing/focus note")

    def test_manual_html_change_area_keeps_catalog_and_issue3_follow_up(self) -> None:
        manual_html_surface = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"attached-html"\s+-or\s+\$ChangeArea\s+-eq\s+"attached-html-target-bundle"\s+-or\s+\$ChangeArea\s+-eq\s+"google-attached-html"\s+-or\s+\$ChangeArea\s+-eq\s+"manual-html"\s*\}\s*\{.*?Write-Route\s+-Name\s+"attached-pages-catalog-follow-up".*?Write-Route\s+-Name\s+"issue3-attached-html-follow-up".*?validation-router attached-html surface checker first',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            manual_html_surface,
            "manual-html change area should keep both the attached-pages catalog follow-up and the issue #3 attached-html follow-up guidance",
        )

    def test_attached_html_helper_routes_form_heavy_pages_back_to_input_lane(self) -> None:
        self.assertIn('change_area = "input"', self.attached_flow)
        self.assertIn("Form-heavy or application-style page.", self.attached_flow)
        self.assertIn(r'show_headed_validation_suites.ps1 -ChangeArea input', self.attached_flow)
        self.assertIn(r'run_localhost_html_validation_recommended.ps1 -Wait', self.attached_flow)
        self.assertIn(r'change_area = "attached-html"', self.attached_flow)
        self.assertIn(r'show_headed_validation_suites.ps1 -ChangeArea attached-html', self.attached_flow)

    def test_shared_input_probes_keep_explicit_headed_launches(self) -> None:
        for label, source in (
            ("enter-submit probe", self.enter_submit_probe),
            ("label-click probe", self.label_click_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--window_width"', source, f"{label} should keep its explicit window width")
            self.assertIn('"--window_height"', source, f"{label} should keep its explicit window height")
            self.assertIn('"--screenshot_png"', source, f"{label} should keep its screenshot export")


if __name__ == "__main__":
    unittest.main()
