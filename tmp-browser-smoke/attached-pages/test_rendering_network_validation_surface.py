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
function Get-RenderingRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1"
    )
}

function Get-NetworkRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stylesheet-smoke\chrome-stylesheet-auth-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1"
    )
}

Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands)
Write-Route -Name "network" -Commands (Get-NetworkRouteCommands)
Write-Route -Name "bounded-rendering" -Commands (Get-RenderingRouteCommands)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
Write-Route -Name "bounded-network" -Commands (Get-NetworkRouteCommands)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
""",
    "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","720","--screenshot_png",$outPng
""",
    "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng
""",
    "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl -PassThru
""",
    "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1": r"""
function Start-FetchBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList "browse",$StartupUrl,"--window_width","960","--window_height","640" -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-rendering-network-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class RenderingNetworkValidationSurfaceTest(unittest.TestCase):
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
        cls.layout_probe = read_text(cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1")
        cls.load_complete_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1"
        )
        cls.stylesheet_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1"
        )
        cls.fetch_common = read_text(
            cls.repo_root / "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1"
        )

    def test_rendering_route_keeps_layout_and_screenshot_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-RenderingRouteCommands")
        self.assertIn("tmp-browser-smoke\\layout-smoke\\chrome-layout-flex-center-probe.ps1", commands_block)
        self.assertIn(
            "tmp-browser-smoke\\layout-smoke\\chrome-screenshot-load-complete-probe.ps1",
            commands_block,
        )

        default_surface = re.search(
            r'Write-Route\s+-Name\s+"rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should surface the rendering route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            change_area_surface,
            "rendering change area should reuse the rendering route helper",
        )

    def test_network_route_keeps_stylesheet_and_fetch_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-NetworkRouteCommands")
        self.assertIn("tmp-browser-smoke\\stylesheet-smoke\\chrome-stylesheet-auth-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\fetch-credentials\\chrome-fetch-credentials-probe.ps1", commands_block)

        default_surface = re.search(
            r'Write-Route\s+-Name\s+"network"\s+-Commands\s+\(Get-NetworkRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should surface the network route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-network"\s+-Commands\s+\(Get-NetworkRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(change_area_surface, "network change area should reuse the network route helper")

    def test_rendering_and_network_routes_keep_attached_html_follow_up(self) -> None:
        attached_follow_up = re.findall(
            r'Write-Route\s+-Name\s+"attached-pages-catalog-follow-up"\s+-Commands\s+\(Get-AttachedHtmlRouteCommands.*?\)',
            self.router,
        )
        self.assertGreaterEqual(
            len(attached_follow_up),
            2,
            "rendering and network change areas should both keep the attached-pages catalog follow-up route",
        )

        issue3_follow_up = re.findall(
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)',
            self.router,
        )
        self.assertGreaterEqual(
            len(issue3_follow_up),
            2,
            "rendering and network change areas should both keep the issue #3 attached-html follow-up route",
        )

    def test_rendering_probes_keep_browse_screenshot_launch_shape(self) -> None:
        for label, source in (
            ("layout flex center probe", self.layout_probe),
            ("load-complete screenshot probe", self.load_complete_probe),
        ):
            self.assertIn('"browse"', source, f"{label} should still launch browse")
            self.assertIn('"--screenshot_png"', source, f"{label} should still capture a headed screenshot")

    def test_network_probes_keep_browse_launch_entrypoints(self) -> None:
        self.assertRegex(
            self.stylesheet_probe,
            re.compile(r'Start-Process\s+-FilePath\s+\$browserExe\s+-ArgumentList\s+"browse",\$pageUrl'),
            "stylesheet auth probe should still launch browse against the auth fixture",
        )

        fetch_browser = extract_function_block(self.fetch_common, "Start-FetchBrowser")
        self.assertIn('"browse"', fetch_browser, "fetch credentials helper should still launch browse")
        self.assertIn('"--window_width"', fetch_browser, "fetch credentials helper should keep the fixed window sizing")
        self.assertIn('"--window_height"', fetch_browser, "fetch credentials helper should keep the fixed window sizing")


if __name__ == "__main__":
    unittest.main()
