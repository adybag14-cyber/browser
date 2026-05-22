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


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$[A-Za-z:]+(?:Exe|BrowserExe)\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-AttachedHtmlRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1"
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1"
    )
}

function Get-RenderingRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1"
    )
}

function Get-RenderingRouteNotes {
    return @(
        "Use these before attached-page replay when the change touched shared layout, paint, screenshot timing, or visible headed surface behavior.",
        "The first-line layout-smoke probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
    )
}

function Get-NetworkRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stylesheet-smoke\chrome-stylesheet-auth-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1"
    )
}

function Get-NetworkRouteNotes {
    return @(
        "Use these before attached-page replay when the change touched shared subresource loading, authenticated asset fetches, or browser-managed request credentials.",
        "These first-line stylesheet and fetch-credentials probes now auto-resolve the current checkout before widening into deeper network helpers."
    )
}

Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
Write-Route -Name "network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)
Write-Route -Name "bounded-rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
Write-Route -Name "bounded-network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
""",
    "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1": r"""
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$python = Resolve-LightpandaPythonCommand
$server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port))
Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
Reset-ProfileRoot $profileRoot
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","720","--screenshot_png",$outPng
Wait-Screenshot $outPng
Find-ColorBounds $outPng { param($c) $c.R -ge 180 }
Stop-LightpandaOwnedProbeProcess $browser
Stop-LightpandaOwnedProbeProcess $server
""",
    "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1": r"""
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$python = Resolve-LightpandaPythonCommand
$server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port))
Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
Reset-ProfileRoot $profileRoot
$started = Get-Date
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng
Wait-Screenshot $outPng
$elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
$result.load_complete_screenshot_worked = $result.slow_image_visible -and $result.waited_for_load
Stop-LightpandaOwnedProbeProcess $browser
Stop-LightpandaOwnedProbeProcess $server
""",
    "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1": r"""
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
Seed-BrowserProfile $appDataRoot
$ready = Wait-LightpandaHttpReady -Url $readyUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl)
$entries = Get-Content -LiteralPath $requestLog | ForEach-Object { $_ | ConvertFrom-Json }
$cssEntries = @($entries | Where-Object { $_.path -eq "/private.css" })
$loadedEntries = @($entries | Where-Object { $_.path -eq "/loaded" })
$loaded = $true
$result = [ordered]@{
  stylesheet_allowed = [bool]$cssEntry.allowed
  stylesheet_authorization = [string]$cssEntry.authorization
  stylesheet_accept = [string]$cssEntry.accept
  loaded_applied = [string]$loadedEntry.applied
  browser_meta = $browserMeta
  server_meta = $serverMeta
}
""",
    "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1": r"""
$script:Repo = Resolve-LightpandaRepoRoot $script:Root
$script:BrowserExe = Resolve-LightpandaBrowserExe $script:Repo $null

function Start-FetchBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed",$StartupUrl,"--window_width","960","--window_height","640") -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}
""",
    "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1": r"""
. (Join-Path $PSScriptRoot "FetchCredentialsProbeCommon.ps1")
$pageServer = Start-FetchServer -Port $pagePort -PeerPort $crossPort -Stdout $pageServerOut -Stderr $pageServerErr
$crossServer = Start-FetchServer -Port $crossPort -PeerPort $pagePort -Stdout $crossServerOut -Stderr $crossServerErr
$ready = (Wait-FetchServer -Port $pagePort) -and (Wait-FetchServer -Port $crossPort)
$browser = Start-FetchBrowser -StartupUrl $pageUrl -Stdout $browserOut -Stderr $browserErr
$hwnd = Wait-TabWindowHandle $browser.Id
Show-SmokeWindow $hwnd
$titles.final = Wait-TabTitle $browser.Id "Fetch Credentials Ready" 50
$result = [ordered]@{
  page_server_meta = Format-FetchProbeProcessMeta $pageServerMeta
  cross_server_meta = Format-FetchProbeProcessMeta $crossServerMeta
  browser_meta = Format-FetchProbeProcessMeta $browserMeta
  browser_gone = $browserGone
}
Write-FetchProbeResult $result
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
        cls.flex_probe = read_text(cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1")
        cls.screenshot_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1"
        )
        cls.stylesheet_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1"
        )
        cls.fetch_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1"
        )
        cls.fetch_common = read_text(
            cls.repo_root / "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1"
        )

    def test_rendering_route_keeps_layout_smoke_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-RenderingRouteCommands")
        self.assertIn("tmp-browser-smoke\\layout-smoke\\chrome-layout-flex-center-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\layout-smoke\\chrome-screenshot-load-complete-probe.ps1", commands_block)
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"bounded-rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
        )

    def test_network_route_keeps_stylesheet_and_fetch_credentials_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-NetworkRouteCommands")
        self.assertIn("tmp-browser-smoke\\stylesheet-smoke\\chrome-stylesheet-auth-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\fetch-credentials\\chrome-fetch-credentials-probe.ps1", commands_block)
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"network"\s+-Commands\s+\(Get-NetworkRouteCommands\)',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"bounded-network"\s+-Commands\s+\(Get-NetworkRouteCommands\)',
        )

    def test_rendering_notes_keep_headed_surface_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-RenderingRouteNotes")
        self.assertIn("shared layout, paint, screenshot timing, or visible headed surface behavior", notes_block)
        self.assertIn("auto-resolve the repo root and zig-out\\bin\\lightpanda.exe", notes_block)
        self.assertIn("older deeper helpers", notes_block)

    def test_network_notes_keep_subresource_and_credentials_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-NetworkRouteNotes")
        self.assertIn("shared subresource loading, authenticated asset fetches, or browser-managed request credentials", notes_block)
        self.assertIn("auto-resolve the current checkout", notes_block)
        self.assertIn("deeper network helpers", notes_block)

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

    def test_rendering_probes_keep_auto_resolution_and_headed_launch(self) -> None:
        self.assertIn("Resolve-LightpandaRepoRoot", self.flex_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.flex_probe)
        self.assertIn("Resolve-LightpandaPythonCommand", self.flex_probe)
        self.assertIn("Wait-LightpandaHttpReady", self.flex_probe)
        self.assertIn("Reset-ProfileRoot", self.flex_probe)
        assert_explicit_headed_launch(self, self.flex_probe, "layout flex-center probe")

        self.assertIn("Resolve-LightpandaRepoRoot", self.screenshot_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.screenshot_probe)
        self.assertIn("Resolve-LightpandaPythonCommand", self.screenshot_probe)
        self.assertIn("Wait-LightpandaHttpReady", self.screenshot_probe)
        self.assertIn("Reset-ProfileRoot", self.screenshot_probe)
        assert_explicit_headed_launch(self, self.screenshot_probe, "layout load-complete screenshot probe")

    def test_rendering_probes_keep_screenshot_and_layout_assertions(self) -> None:
        self.assertIn('"--screenshot_png"', self.flex_probe)
        self.assertIn("Wait-Screenshot", self.flex_probe)
        self.assertIn("Find-ColorBounds", self.flex_probe)
        self.assertIn("Stop-LightpandaOwnedProbeProcess $browser", self.flex_probe)
        self.assertIn("Stop-LightpandaOwnedProbeProcess $server", self.flex_probe)

        self.assertIn('"--screenshot_png"', self.screenshot_probe)
        self.assertIn("Wait-Screenshot", self.screenshot_probe)
        self.assertIn("$elapsedMs", self.screenshot_probe)
        self.assertIn("load_complete_screenshot_worked", self.screenshot_probe)
        self.assertIn("Stop-LightpandaOwnedProbeProcess $browser", self.screenshot_probe)
        self.assertIn("Stop-LightpandaOwnedProbeProcess $server", self.screenshot_probe)

    def test_stylesheet_probe_keeps_headed_launch_and_ready_gate(self) -> None:
        self.assertIn("Resolve-LightpandaRepoRoot", self.stylesheet_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.stylesheet_probe)
        self.assertIn("Wait-LightpandaHttpReady", self.stylesheet_probe)
        assert_explicit_headed_launch(self, self.stylesheet_probe, "stylesheet auth probe")

    def test_stylesheet_probe_keeps_request_log_and_result_markers(self) -> None:
        self.assertIn("Get-Content -LiteralPath $requestLog", self.stylesheet_probe)
        self.assertIn('$_ .path -eq "/private.css"'.replace(" ", ""), self.stylesheet_probe.replace(" ", ""))
        self.assertIn('$_ .path -eq "/loaded"'.replace(" ", ""), self.stylesheet_probe.replace(" ", ""))
        self.assertIn("stylesheet_authorization", self.stylesheet_probe)
        self.assertIn("stylesheet_accept", self.stylesheet_probe)
        self.assertIn("loaded_applied", self.stylesheet_probe)
        self.assertIn("browser_meta", self.stylesheet_probe)
        self.assertIn("server_meta", self.stylesheet_probe)

    def test_fetch_credentials_probe_keeps_auto_resolution_and_headed_launch(self) -> None:
        self.assertIn("Resolve-LightpandaRepoRoot", self.fetch_common)
        self.assertIn("Resolve-LightpandaBrowserExe", self.fetch_common)
        self.assertIn("-WorkingDirectory $script:Repo", self.fetch_common)
        self.assertIn("-RedirectStandardOutput $Stdout", self.fetch_common)
        self.assertIn("-RedirectStandardError $Stderr", self.fetch_common)
        assert_explicit_headed_launch(self, self.fetch_common, "fetch credentials common browser launcher")

    def test_fetch_credentials_probe_keeps_dual_server_and_ready_title_flow(self) -> None:
        self.assertIn("Start-FetchServer -Port $pagePort", self.fetch_probe)
        self.assertIn("Start-FetchServer -Port $crossPort", self.fetch_probe)
        self.assertIn("Wait-FetchServer -Port $pagePort", self.fetch_probe)
        self.assertIn("Wait-TabWindowHandle $browser.Id", self.fetch_probe)
        self.assertIn("Show-SmokeWindow $hwnd", self.fetch_probe)
        self.assertIn('Wait-TabTitle $browser.Id "Fetch Credentials Ready" 50', self.fetch_probe)
        self.assertIn("Format-FetchProbeProcessMeta $pageServerMeta", self.fetch_probe)
        self.assertIn("Format-FetchProbeProcessMeta $crossServerMeta", self.fetch_probe)
        self.assertIn("Format-FetchProbeProcessMeta $browserMeta", self.fetch_probe)
        self.assertIn("Write-FetchProbeResult", self.fetch_probe)


if __name__ == "__main__":
    unittest.main()
