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


def extract_route_notes(source: str, route_name: str) -> list[str]:
    pattern = re.compile(
        rf'Write-Route\s+-Name\s+"{re.escape(route_name)}"\s+-Commands\s+@\((?:.|\n)*?\)\s+-Notes\s+@\((?P<notes>(?:.|\n)*?)\)',
        re.MULTILINE,
    )
    matches = pattern.finditer(source)
    notes = [match.group("notes") for match in matches]
    if not notes:
        raise AssertionError(f"Could not find notes for route {route_name}")
    return notes


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$browserExe\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
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
""",
    "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$beforePng = Join-Path $root "chrome-history.before.png"
function Count-Hits([string]$Pattern) { return 0 }
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$beforePng,"http://127.0.0.1:8147/index.html")
Show-SmokeWindow $hwnd
[void](Invoke-SmokeClientClick $hwnd $linkX $linkY)
[void](Invoke-SmokeClientClick $hwnd 25 40)
[void](Invoke-SmokeClientClick $hwnd 57 40)
$linkWorked = $true
$backWorked = $true
$forwardWorked = $true
""",
    "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1": r"""
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$png = Join-Path $root "chrome-reload.before.png"
function Count-IndexHits { return 0 }
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$png,"http://127.0.0.1:8146/index.html")
Show-SmokeWindow $hwnd
[void](Invoke-SmokeClientClick $hwnd 89 40)
$reloadWorked = $true
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-navigation-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class NavigationValidationSurfaceTest(unittest.TestCase):
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

    def test_default_navigation_route_keeps_history_and_reload_probes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "navigation")[0]
        self.assertIn(r"tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1", commands_block)

    def test_navigation_route_notes_keep_localhost_and_repo_root_guidance(self) -> None:
        notes_block = extract_route_notes(self.router, "navigation")[0]
        self.assertIn("headed navigation, back, forward, and reload on localhost fixtures", notes_block)
        self.assertIn("Repo root resolves automatically", notes_block)
        self.assertIn("-RepoRoot overrides it", notes_block)

    def test_navigation_change_area_keeps_wrapped_link_route_and_notes(self) -> None:
        commands_block = extract_route_command_blocks(self.router, "wrapped-link")[0]
        self.assertIn(r"tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1", commands_block)

        notes_block = extract_route_notes(self.router, "wrapped-link")[0]
        self.assertIn("headed navigation, history, and reload behavior on bounded localhost pages", notes_block)

    def test_history_probe_keeps_explicit_headed_launch_and_navigation_clicks(self) -> None:
        assert_explicit_headed_launch(self, self.history_probe, "history probe")
        self.assertIn(r'"--screenshot_png"', self.history_probe)
        self.assertIn("Resolve-LightpandaRepoRoot", self.history_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.history_probe)
        self.assertIn("Count-Hits", self.history_probe)
        self.assertIn("Invoke-SmokeClientClick $hwnd $linkX $linkY", self.history_probe)
        self.assertIn("Invoke-SmokeClientClick $hwnd 25 40", self.history_probe)
        self.assertIn("Invoke-SmokeClientClick $hwnd 57 40", self.history_probe)
        self.assertIn("$linkWorked", self.history_probe)
        self.assertIn("$backWorked", self.history_probe)
        self.assertIn("$forwardWorked", self.history_probe)
        self.assertIn("Show-SmokeWindow", self.history_probe)

    def test_reload_probe_keeps_explicit_headed_launch_and_reload_assertion(self) -> None:
        assert_explicit_headed_launch(self, self.reload_probe, "reload probe")
        self.assertIn(r'"--screenshot_png"', self.reload_probe)
        self.assertIn("Resolve-LightpandaRepoRoot", self.reload_probe)
        self.assertIn("Resolve-LightpandaBrowserExe", self.reload_probe)
        self.assertIn("Count-IndexHits", self.reload_probe)
        self.assertIn("Invoke-SmokeClientClick $hwnd 89 40", self.reload_probe)
        self.assertIn("$reloadWorked", self.reload_probe)
        self.assertIn("Show-SmokeWindow", self.reload_probe)


if __name__ == "__main__":
    unittest.main()
