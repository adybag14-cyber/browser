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
function Get-RenderingRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1"
    )
}

Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands)
Write-Route -Name "bounded-rendering" -Commands (Get-RenderingRouteCommands)
""",
    "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:8177/flex-center.html"
""",
    "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","http://127.0.0.1:8180/load-complete-screenshot.html")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-rendering-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class RenderingValidationSurfaceTest(unittest.TestCase):
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
        cls.screenshot_probe = read_text(cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1")

    def test_rendering_route_keeps_lead_layout_probes(self) -> None:
        commands_block = extract_function_block(self.router, "Get-RenderingRouteCommands")
        self.assertIn("tmp-browser-smoke\\layout-smoke\\chrome-layout-flex-center-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\layout-smoke\\chrome-screenshot-load-complete-probe.ps1", commands_block)

        default_surface = re.search(
            r'Write-Route\s+-Name\s+"rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_surface, "default router should surface the rendering route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-rendering"\s+-Commands\s+\(Get-RenderingRouteCommands\)',
            self.router,
        )
        self.assertIsNotNone(change_area_surface, "rendering change area should reuse the rendering route helper")

    def test_rendering_probes_keep_explicit_headed_launches(self) -> None:
        assert_explicit_headed_launch(self, self.flex_probe, "flex-center probe")
        assert_explicit_headed_launch(self, self.screenshot_probe, "load-complete screenshot probe")


if __name__ == "__main__":
    unittest.main()
