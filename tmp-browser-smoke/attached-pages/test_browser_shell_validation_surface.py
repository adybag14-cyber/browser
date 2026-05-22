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


def extract_named_route_block(source: str, route_name: str) -> str:
    pattern = re.compile(
        rf'Write-Route\s+-Name\s+"{re.escape(route_name)}"\s+-Commands\s+(?P<body>\(.*?\)|@\((?:.|\n)*?\))\s+-Notes',
        re.MULTILINE,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find route block for {route_name}")
    return match.group("body")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
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

function Show-DefaultRoutes {
    Write-Route -Name "browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
}

switch ($true) {
    { $ChangeArea -eq "browser-shell" } {
        Write-Section "browser-shell"
        Write-Route -Name "bounded-browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
        break
    }
    default {
        Show-DefaultRoutes
        break
    }
}
""",
    "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:8151/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
$newTabWorked = $false
$addressNavigateWorked = $false
$keyboardBackWorked = $false
$keyboardForwardWorked = $false
$clickSwitchWorked = $false
$closeWorked = $false
Send-SmokeCtrlShiftTab
Send-SmokeCtrlTab
Invoke-SmokeClientClick $hwnd $closePoint.X $closePoint.Y
""",
    "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","http://127.0.0.1:8155/home.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
$settingsFile = Join-Path $profileRoot "lightpanda\browse-settings-v1.txt"
$defaultZoomSaved = $false
$homepageSaved = $false
$homeWorked = $false
Send-SmokeCtrlComma
Send-SmokeAltHome
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-browser-shell-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class BrowserShellValidationSurfaceTest(unittest.TestCase):
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
        cls.settings_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1"
        )

    def test_browser_shell_route_commands_keep_tabs_and_settings_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-BrowserShellRouteCommands")
        self.assertIn(r".\tmp-browser-smoke\tabs\chrome-tabs-probe.ps1", commands_block)
        self.assertIn(r".\tmp-browser-smoke\settings\chrome-settings-home-probe.ps1", commands_block)

    def test_browser_shell_route_notes_keep_scope_and_auto_resolve_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-BrowserShellRouteNotes")
        self.assertIn("tabs, reopen flows, chrome keyboard shortcuts, settings persistence", notes_block)
        self.assertIn("real headed window", notes_block)
        self.assertIn("auto-resolve the repo root", notes_block)
        self.assertIn(r"zig-out\bin\lightpanda.exe", notes_block)

    def test_default_router_keeps_browser_shell_route(self) -> None:
        route_body = extract_named_route_block(self.router, "browser-shell")
        self.assertIn("Get-BrowserShellRouteCommands", route_body)
        self.assertIn("Get-BrowserShellRouteNotes", self.router)

    def test_browser_shell_change_area_keeps_bounded_route(self) -> None:
        block_match = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"browser-shell"\s*\}\s*\{(?P<body>.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(block_match, "browser-shell change area should exist")
        body = block_match.group("body")
        self.assertIn('Write-Section "browser-shell"', body)
        self.assertIn('Write-Route -Name "bounded-browser-shell"', body)
        self.assertIn("Get-BrowserShellRouteCommands", body)
        self.assertIn("Get-BrowserShellRouteNotes", body)

    def test_probe_files_exist_in_repo(self) -> None:
        for relative_path in (
            "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1",
            "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")

    def test_tabs_probe_keeps_explicit_headed_launch_and_tab_actions(self) -> None:
        assert_explicit_headed_launch(self, self.tabs_probe, "tabs probe")
        for fragment in (
            "$newTabWorked",
            "$addressNavigateWorked",
            "$keyboardBackWorked",
            "$keyboardForwardWorked",
            "$clickSwitchWorked",
            "$closeWorked",
            "Send-SmokeCtrlShiftTab",
            "Send-SmokeCtrlTab",
            "Invoke-SmokeClientClick $hwnd $closePoint.X $closePoint.Y",
        ):
            self.assertIn(fragment, self.tabs_probe)

    def test_settings_probe_keeps_explicit_headed_launch_and_home_persistence_checks(self) -> None:
        assert_explicit_headed_launch(self, self.settings_probe, "settings home probe")
        for fragment in (
            r"lightpanda\browse-settings-v1.txt",
            "$defaultZoomSaved",
            "$homepageSaved",
            "$homeWorked",
            "Send-SmokeCtrlComma",
            "Send-SmokeAltHome",
        ):
            self.assertIn(fragment, self.settings_probe)


if __name__ == "__main__":
    unittest.main()
