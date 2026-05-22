import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_function_block(source: str, function_name: str) -> str:
    pattern = re.compile(
        rf"function\s+{re.escape(function_name)}\s*\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find function block for {function_name}")
    return match.group(0)


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$browserExe\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-BrowserShellRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\tabs\chrome-tabs-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\settings\chrome-settings-home-probe.ps1"
    )
}

function Get-BrowserShellRouteNotes {
    return @(
        "Use these when the change touched tabs, reopen flows, chrome keyboard shortcuts, settings persistence, or other browser-shell surfaces on the real headed window.",
        "These first-line browser-shell probes already auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; use the validation matrix before widening into older deeper helpers."
    )
}

function Get-PopupRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\popup\chrome-popup-anchor-probe.ps1"
    )
}

function Get-PopupRouteNotes {
    return @(
        "Use this when the change touched popup creation, named-target navigation, or popup policy on the real headed window.",
        "Keep deeper popup follow-up on the validation matrix for now because several older popup helpers still carry fixed checkout assumptions."
    )
}

Write-Route -Name "browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
Write-Route -Name "popup" -Commands (Get-PopupRouteCommands) -Notes (Get-PopupRouteNotes)
Write-Route -Name "bounded-browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
Write-Route -Name "bounded-popup" -Commands (Get-PopupRouteCommands) -Notes (Get-PopupRouteNotes)
""",
    "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:8151/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng
""",
    "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1": r"""
$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-home"
Reset-TabProbeProfile $profileRoot
Set-TabProbeProfileEnvironment $profileRoot
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","http://127.0.0.1:8155/home.html")
Send-SmokeCtrlComma
Send-SmokeAltHome
""",
    "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1": r"""
$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-anchor"
Reset-TabProbeProfile $profileRoot
Set-TabProbeProfileEnvironment $profileRoot
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","http://127.0.0.1:8158/anchor-index.html")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-browser-shell-popup-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class BrowserShellPopupValidationSurfaceTest(unittest.TestCase):
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
        cls.tabs_probe = read_text(cls.repo_root / "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1")
        cls.settings_probe = read_text(cls.repo_root / "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1")
        cls.popup_probe = read_text(cls.repo_root / "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1")

    def test_browser_shell_route_keeps_tabs_and_settings_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-BrowserShellRouteCommands")
        self.assertIn("tmp-browser-smoke\\tabs\\chrome-tabs-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\settings\\chrome-settings-home-probe.ps1", commands_block)

        default_surface = re.search(
            r'Write-Route\s+-Name\s+"browser-shell"\s+-Commands\s+\(Get-BrowserShellRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should surface the browser-shell route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-browser-shell"\s+-Commands\s+\(Get-BrowserShellRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(change_area_surface, "browser-shell change area should reuse the browser-shell route helper")

    def test_popup_route_keeps_anchor_probe(self) -> None:
        commands_block = extract_function_block(self.router, "Get-PopupRouteCommands")
        self.assertIn("tmp-browser-smoke\\popup\\chrome-popup-anchor-probe.ps1", commands_block)

        default_surface = re.search(
            r'Write-Route\s+-Name\s+"popup"\s+-Commands\s+\(Get-PopupRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should surface the popup route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-popup"\s+-Commands\s+\(Get-PopupRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(change_area_surface, "popup change area should reuse the popup route helper")

    def test_browser_shell_notes_keep_tabs_settings_and_headed_window_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-BrowserShellRouteNotes")
        self.assertIn("tabs, reopen flows, chrome keyboard shortcuts, settings persistence", notes_block)
        self.assertIn("real headed window", notes_block)
        self.assertIn("auto-resolve the repo root and zig-out\\bin\\lightpanda.exe", notes_block)
        self.assertIn("validation matrix", notes_block)

    def test_popup_notes_keep_named_target_and_follow_up_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-PopupRouteNotes")
        self.assertIn("popup creation, named-target navigation, or popup policy", notes_block)
        self.assertIn("real headed window", notes_block)
        self.assertIn("validation matrix", notes_block)
        self.assertIn("fixed checkout assumptions", notes_block)

    def test_browser_shell_probes_keep_explicit_headed_launches(self) -> None:
        assert_explicit_headed_launch(self, self.tabs_probe, "tabs probe")
        assert_explicit_headed_launch(self, self.settings_probe, "settings home probe")

    def test_tabs_probe_keeps_screenshot_capture(self) -> None:
        self.assertIn('"--screenshot_png"', self.tabs_probe)
        self.assertIn('"--window_width"', self.tabs_probe)
        self.assertIn('"--window_height"', self.tabs_probe)

    def test_settings_probe_keeps_profile_and_settings_shortcut_flow(self) -> None:
        self.assertIn('ProfileName "profile-home"', self.settings_probe)
        self.assertIn("Reset-TabProbeProfile", self.settings_probe)
        self.assertIn("Set-TabProbeProfileEnvironment", self.settings_probe)
        self.assertIn("Send-SmokeCtrlComma", self.settings_probe)
        self.assertIn("Send-SmokeAltHome", self.settings_probe)

    def test_popup_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.popup_probe, "popup anchor probe")

    def test_popup_probe_keeps_profile_reset_flow(self) -> None:
        self.assertIn('ProfileName "profile-anchor"', self.popup_probe)
        self.assertIn("Reset-TabProbeProfile", self.popup_probe)
        self.assertIn("Set-TabProbeProfileEnvironment", self.popup_probe)
        self.assertIn('"--window_width"', self.popup_probe)
        self.assertIn('"--window_height"', self.popup_probe)


if __name__ == "__main__":
    unittest.main()
