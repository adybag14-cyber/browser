import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r"Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?[\"']browse[\"'].*?[\"']--browser_mode[\"'].*?[\"']headed[\"']",
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "navigation" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
)

Write-Route -Name "stop-loading" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
)

Write-Route -Name "wrapped-link" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
)

Write-Route -Name "stop-loading" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
)
""",
    "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$beforePng,"http://127.0.0.1:8147/index.html")
""",
    "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$png,"http://127.0.0.1:8146/index.html")
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "240", "--window_height", "480", "--screenshot_png", $beforePng, $indexUrl)
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "260", "--window_height", "520", "--screenshot_png", $beforePng, $inputUrl)
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
        default_surface = re.search(
            r'Write-Route\s+-Name\s+"navigation"\s+-Commands\s+@\(\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\wrapped-link\\chrome-history-probe\.ps1",\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\wrapped-link\\chrome-reload-probe\.ps1"\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(default_surface, "default router should keep the navigation route on the history and reload probes")

    def test_navigation_change_area_keeps_wrapped_link_route(self) -> None:
        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"wrapped-link"\s+-Commands\s+@\(\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\wrapped-link\\chrome-history-probe\.ps1",\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\wrapped-link\\chrome-reload-probe\.ps1"\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(change_area_surface, "navigation change area should keep the wrapped-link route on the same two probes")

    def test_stop_loading_routes_keep_both_stop_probes(self) -> None:
        route_matches = re.findall(
            r'Write-Route\s+-Name\s+"stop-loading"\s+-Commands\s+@\(\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\stop-loading\\chrome-stop-probe\.ps1",\s*"powershell -ExecutionPolicy Bypass -File \.\\tmp-browser-smoke\\stop-loading\\chrome-stop-input-probe\.ps1"\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertGreaterEqual(
            len(route_matches),
            2,
            "default and change-area router surfaces should both keep the two stop-loading probes",
        )

    def test_navigation_and_stop_loading_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("history probe", self.history_probe),
            ("reload probe", self.reload_probe),
            ("stop probe", self.stop_probe),
            ("stop input probe", self.stop_input_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--screenshot_png"', source, f"{label} should keep its screenshot export")


if __name__ == "__main__":
    unittest.main()
