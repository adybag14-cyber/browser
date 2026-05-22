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
Write-Route -Name "navigation" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
) -Notes @(
    "These probes exercise headed navigation, back, forward, and reload on localhost fixtures.",
    "Repo root resolves automatically from this script unless -RepoRoot overrides it."
)

Write-Route -Name "wrapped-link" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
) -Notes @(
    "Use these for headed navigation, history, and reload behavior on bounded localhost pages."
)

Write-Route -Name "stop-loading" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
) -Notes @(
    "These probes exercise headed stop/loading recovery and restored input behavior on localhost fixtures.",
    "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
)

Write-Route -Name "stop-loading" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
) -Notes @(
    "Use these for headed stop/loading recovery and restored input behavior on bounded localhost pages.",
    "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
)
""",
    "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$beforePng,"http://127.0.0.1:8147/index.html")
Show-SmokeWindow $hwnd
""",
    "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$png,"http://127.0.0.1:8146/index.html")
Show-SmokeWindow $hwnd
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "240", "--window_height", "480", "--screenshot_png", $beforePng, $indexUrl)
$titleAfterStop = Get-SmokeWindowTitle $hwnd
$liveContextRestored = $true
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "260", "--window_height", "520", "--screenshot_png", $beforePng, $inputUrl)
$titleAfterRestoreInput = "Stop Restore Input AB"
$restoredInputWorked = $true
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-navigation-stop-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class NavigationStopLoadingValidationSurfaceTest(unittest.TestCase):
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
        cls.history_probe = read_text(cls.repo_root / "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1")
        cls.reload_probe = read_text(cls.repo_root / "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1")
        cls.stop_probe = read_text(cls.repo_root / "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1")
        cls.stop_input_probe = read_text(cls.repo_root / "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1")

    def test_navigation_default_route_keeps_history_and_reload_probes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "navigation")[0]
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-history-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-reload-probe.ps1", commands_block)

    def test_navigation_change_area_keeps_wrapped_link_route(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "wrapped-link")[0]
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-history-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-reload-probe.ps1", commands_block)

    def test_navigation_route_notes_keep_localhost_and_repo_root_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "navigation")
        self.assertIn("headed navigation, back, forward, and reload on localhost fixtures", notes_block)
        self.assertIn("Repo root resolves automatically", notes_block)
        self.assertIn("-RepoRoot overrides it", notes_block)

    def test_stop_loading_routes_keep_both_stop_probes(self) -> None:
        route_matches = extract_route_command_blocks(self.router, "stop-loading")
        self.assertGreaterEqual(
            len(route_matches),
            2,
            "default and change-area router surfaces should both keep the two stop-loading probes",
        )
        for commands_block in route_matches:
            self.assertIn("tmp-browser-smoke\\stop-loading\\chrome-stop-probe.ps1", commands_block)
            self.assertIn("tmp-browser-smoke\\stop-loading\\chrome-stop-input-probe.ps1", commands_block)

    def test_stop_loading_notes_keep_recovery_and_auto_resolve_guidance(self) -> None:
        notes_matches = re.findall(
            r'Write-Route\s+-Name\s+"stop-loading"\s+-Commands\s+@\((?:.|\n)*?\)\s+-Notes\s+@\((?P<notes>(?:.|\n)*?)\)',
            self.router,
            re.MULTILINE,
        )
        self.assertGreaterEqual(len(notes_matches), 2, "stop-loading should keep both default and change-area notes blocks")
        self.assertIn("headed stop/loading recovery and restored input behavior", notes_matches[0])
        self.assertIn("on localhost fixtures", notes_matches[0])
        self.assertIn("headed stop/loading recovery and restored input behavior", notes_matches[1])
        self.assertIn("auto-resolve the repo root and zig-out\\bin\\lightpanda.exe", notes_matches[1])
        self.assertIn("widen into older deeper helpers only when you need more coverage", notes_matches[1])

    def test_navigation_and_stop_loading_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("history probe", self.history_probe),
            ("reload probe", self.reload_probe),
            ("stop probe", self.stop_probe),
            ("stop input probe", self.stop_input_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--screenshot_png"', source, f"{label} should keep its screenshot export")

    def test_navigation_probes_keep_repo_root_and_browser_resolution(self) -> None:
        for label, source in (
            ("history probe", self.history_probe),
            ("reload probe", self.reload_probe),
        ):
            self.assertIn("Resolve-LightpandaRepoRoot", source, f"{label} should auto-resolve the repo root")
            self.assertIn("Resolve-LightpandaBrowserExe", source, f"{label} should auto-resolve the browser executable")
            self.assertIn("Show-SmokeWindow", source, f"{label} should still drive the headed window surface")

    def test_stop_loading_probes_keep_recovery_assertions(self) -> None:
        self.assertIn("Resolve-LightpandaRepoRoot", self.stop_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.stop_probe)
        self.assertIn("$titleAfterStop = Get-SmokeWindowTitle $hwnd", self.stop_probe)
        self.assertIn("$liveContextRestored = $true", self.stop_probe)

        self.assertIn("Resolve-LightpandaRepoRoot", self.stop_input_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.stop_input_probe)
        self.assertIn("$titleAfterRestoreInput", self.stop_input_probe)
        self.assertIn("$restoredInputWorked = $true", self.stop_input_probe)


if __name__ == "__main__":
    unittest.main()
