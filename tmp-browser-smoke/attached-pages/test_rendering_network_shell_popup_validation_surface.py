import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_route_command_blocks(source: str, route_name: str) -> list[str]:
    pattern = re.compile(
        rf'Write-Route\s+-Name\s+"{re.escape(route_name)}"\s+-Commands\s+@\((?P<body>(?:.|\n)*?)\)\s+-Notes',
        re.MULTILINE,
    )
    matches = pattern.finditer(source)
    blocks = [match.group("body") for match in matches]
    if not blocks:
        raise AssertionError(f"Could not find command blocks for route {route_name}")
    return blocks


def extract_route_notes(source: str, route_name: str) -> str:
    pattern = re.compile(
        rf'Write-Route\s+-Name\s+"{re.escape(route_name)}"\s+-Commands\s+@\((?:.|\n)*?\)\s+-Notes\s+@\((?P<notes>(?:.|\n)*?)\)\s*$',
        re.MULTILINE,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find notes for route {route_name}")
    return match.group("notes")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "rendering" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1"
) -Notes @(
    "Use these before attached-page replay when the change touched shared layout, paint, screenshot timing, or visible headed surface behavior.",
    "The first-line layout-smoke probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
)

Write-Route -Name "network" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stylesheet-smoke\chrome-stylesheet-auth-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1"
) -Notes @(
    "Use these before attached-page replay when the change touched shared subresource loading, authenticated asset fetches, or browser-managed request credentials.",
    "These first-line stylesheet and fetch-credentials probes now auto-resolve the current checkout before widening into deeper network helpers."
)

Write-Route -Name "browser-shell" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-tabs-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\settings\chrome-settings-home-probe.ps1"
) -Notes @(
    "Use these when the change touched tabs, reopen flows, chrome keyboard shortcuts, settings persistence, or other browser-shell surfaces on the real headed window.",
    "These first-line browser-shell probes already auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; use the validation matrix before widening into older deeper helpers."
)

Write-Route -Name "popup" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1"
) -Notes @(
    "Use this when the change touched popup creation, named-target navigation, or popup policy on the real headed window.",
    "Keep deeper popup follow-up on the validation matrix for now because several older popup helpers still carry fixed checkout assumptions."
)
""",
    "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","720","--screenshot_png",$outPng
""",
    "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng
$started = Get-Date
""",
    "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$ready = Wait-LightpandaHttpReady -Url $readyUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl)
$requestLog = Join-Path $root "stylesheet.requests.jsonl"
""",
    "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1": r"""
function Start-FetchBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed",$StartupUrl,"--window_width","960","--window_height","640") -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}
""",
    "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1": r"""
. (Join-Path $PSScriptRoot "FetchCredentialsProbeCommon.ps1")
$browser = Start-FetchBrowser -StartupUrl $pageUrl -Stdout $browserOut -Stderr $browserErr
$titles.final = Wait-TabTitle $browser.Id "Fetch Credentials Ready" 50
""",
    "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1": r"""
. "$PSScriptRoot\TabProbeCommon.ps1"
$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
Show-SmokeWindow $hwnd
$titles.after_close = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
""",
    "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1": r"""
. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"
$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-home"
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/home.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
$defaultZoomSaved = Wait-SettingsFileMatch -Path $settingsFile -Needle "default_zoom_percent`t110" -DelayMilliseconds $PollMilliseconds
$homepageSaved = Wait-SettingsFileMatch -Path $settingsFile -Needle "homepage_url`t$origin/home.html" -DelayMilliseconds $PollMilliseconds
""",
    "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path $PSScriptRoot "..\tabs\TabProbeCommon.ps1")
$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-anchor"
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/anchor-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
Show-SmokeWindow $hwnd
$titles.result = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Anchor Result" -Attempts 40 -PollMilliseconds $PollMilliseconds
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-render-network-shell-popup-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class RenderingNetworkShellPopupValidationSurfaceTest(unittest.TestCase):
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
        cls.load_complete_probe = read_text(cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1")
        cls.stylesheet_probe = read_text(cls.repo_root / "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1")
        cls.fetch_common = read_text(cls.repo_root / "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1")
        cls.fetch_probe = read_text(cls.repo_root / "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1")
        cls.tabs_probe = read_text(cls.repo_root / "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1")
        cls.settings_probe = read_text(cls.repo_root / "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1")
        cls.popup_probe = read_text(cls.repo_root / "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1")

    def test_rendering_route_keeps_layout_and_screenshot_probes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "rendering")[0]
        self.assertIn(r"tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1", commands_block)

    def test_rendering_notes_keep_layout_and_auto_resolve_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "rendering")
        self.assertIn("shared layout, paint, screenshot timing, or visible headed surface behavior", notes_block)
        self.assertIn(r"auto-resolve the repo root and zig-out\bin\lightpanda.exe", notes_block)
        self.assertIn("widen into older deeper helpers only when you need more coverage", notes_block)

    def test_rendering_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("layout flex probe", self.layout_probe),
            ("load-complete screenshot probe", self.load_complete_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn("Resolve-LightpandaRepoRoot", source, f"{label} should auto-resolve the repo root")
            self.assertIn("Resolve-LightpandaBrowserExe", source, f"{label} should auto-resolve the browser executable")
            self.assertIn('"--screenshot_png"', source, f"{label} should keep screenshot export wiring")

    def test_network_route_keeps_stylesheet_and_fetch_credentials_probes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "network")[0]
        self.assertIn(r"tmp-browser-smoke\stylesheet-smoke\chrome-stylesheet-auth-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1", commands_block)

    def test_network_notes_keep_subresource_and_checkout_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "network")
        self.assertIn("shared subresource loading, authenticated asset fetches, or browser-managed request credentials", notes_block)
        self.assertIn("auto-resolve the current checkout", notes_block)
        self.assertIn("before widening into deeper network helpers", notes_block)

    def test_network_probes_keep_explicit_headed_launches_and_ready_state(self) -> None:
        assert_explicit_headed_launch(self, self.stylesheet_probe, "stylesheet auth probe")
        self.assertIn("Resolve-LightpandaRepoRoot", self.stylesheet_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.stylesheet_probe)
        self.assertIn("Wait-LightpandaHttpReady", self.stylesheet_probe)
        self.assertIn("stylesheet.requests.jsonl", self.stylesheet_probe)

        assert_explicit_headed_launch(self, self.fetch_common, "fetch credentials common browser launch")
        self.assertIn("Start-FetchBrowser", self.fetch_probe)
        self.assertIn("Fetch Credentials Ready", self.fetch_probe)

    def test_browser_shell_route_keeps_tabs_and_settings_probes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "browser-shell")[0]
        self.assertIn(r"tmp-browser-smoke\tabs\chrome-tabs-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\settings\chrome-settings-home-probe.ps1", commands_block)

    def test_browser_shell_notes_keep_shell_and_auto_resolve_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "browser-shell")
        self.assertIn("tabs, reopen flows, chrome keyboard shortcuts, settings persistence", notes_block)
        self.assertIn(r"auto-resolve the repo root and zig-out\bin\lightpanda.exe", notes_block)
        self.assertIn("use the validation matrix before widening into older deeper helpers", notes_block)

    def test_browser_shell_probes_keep_explicit_headed_window_and_profile_contracts(self) -> None:
        for label, source in (
            ("tabs probe", self.tabs_probe),
            ("settings home probe", self.settings_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn("Resolve-TabProbeConfig", source, f"{label} should derive its headed tab probe config")
        self.assertIn("Show-SmokeWindow", self.tabs_probe)
        self.assertIn("Tab One", self.tabs_probe)
        self.assertIn("default_zoom_percent`t110", self.settings_probe)
        self.assertIn("homepage_url`t$origin/home.html", self.settings_probe)

    def test_popup_route_keeps_popup_anchor_probe(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "popup")[0]
        self.assertIn(r"tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1", commands_block)

    def test_popup_notes_keep_policy_and_validation_matrix_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "popup")
        self.assertIn("popup creation, named-target navigation, or popup policy", notes_block)
        self.assertIn("validation matrix", notes_block)
        self.assertIn("fixed checkout assumptions", notes_block)

    def test_popup_probe_keeps_explicit_headed_launch_and_result_title(self) -> None:
        assert_explicit_headed_launch(self, self.popup_probe, "popup anchor probe")
        self.assertIn("Resolve-TabProbeConfig", self.popup_probe)
        self.assertIn("Show-SmokeWindow", self.popup_probe)
        self.assertIn("Popup Anchor Result", self.popup_probe)


if __name__ == "__main__":
    unittest.main()
