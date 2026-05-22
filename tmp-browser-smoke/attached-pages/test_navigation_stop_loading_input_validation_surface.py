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
        r'Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1"
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1"
    )
}

Write-Route -Name "navigation" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
) -Notes @(
    "These probes exercise headed navigation, back, forward, and reload on localhost fixtures.",
    "Repo root resolves automatically from this script unless -RepoRoot overrides it."
)

Write-Route -Name "stop-loading" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
) -Notes @(
    "These probes exercise headed stop/loading recovery and restored input behavior on localhost fixtures.",
    "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
)

Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
)

Write-Route -Name "bounded-input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
)

Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
    "Use this after the shared input probes are green when the next question is whether submit still waits until keypress on the Google-style form-controls path."
)

Write-Route -Name "manual-google" -Commands @(
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
) -Notes @(
    "Use this after the bounded input probes are green."
)

Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes @(
    "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
)

switch ($true) {
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use this after the shared input probes are green when the next question is whether submit still waits until keypress on the Google-style form-controls path."
        )

        Write-Route -Name "manual-google" -Commands @(
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        ) -Notes @(
            "Use this after the bounded input probes are green."
        )

        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes @(
            "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
        )
        break
    }
    { $ChangeArea -eq "navigation" } {
        Write-Route -Name "wrapped-link" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
        ) -Notes @(
            "Use these for headed navigation, history, and reload behavior on bounded localhost pages."
        )
        break
    }
    { $ChangeArea -eq "stop-loading" } {
        Write-Route -Name "stop-loading" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
        ) -Notes @(
            "Use these for headed stop/loading recovery and restored input behavior on bounded localhost pages.",
            "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
        )
        break
    }
}
""",
    "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$beforePng,"http://127.0.0.1:8147/index.html")
""",
    "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$png,"http://127.0.0.1:8146/index.html")
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","240","--window_height","480","--screenshot_png",$beforePng,$indexUrl)
""",
    "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","260","--window_height","520","--screenshot_png",$beforePng,$inputUrl)
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-navigation-stop-input-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class NavigationStopLoadingInputValidationSurfaceTest(unittest.TestCase):
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
        cls.stop_input_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1"
        )
        cls.enter_submit_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )
        cls.label_click_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1"
        )

    def test_default_router_surfaces_navigation_stop_loading_and_input_routes(self) -> None:
        for route_name, route_commands in (
            ("navigation", r'Write-Route\s+-Name\s+"navigation"\s+-Commands\s+@\('),
            ("stop-loading", r'Write-Route\s+-Name\s+"stop-loading"\s+-Commands\s+@\('),
            ("input", r'Write-Route\s+-Name\s+"input"\s+-Commands\s+@\('),
        ):
            match = re.search(route_commands, self.router)
            self.assertIsNotNone(match, f"default router should surface the {route_name} route")

    def test_navigation_change_area_keeps_history_and_reload_probes(self) -> None:
        navigation_block = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"navigation"\s*\}\s*\{.*?Write-Route\s+-Name\s+"wrapped-link"\s+-Commands\s+@\((.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(navigation_block, "navigation change area should surface the wrapped-link route")
        commands_block = navigation_block.group(1)
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-history-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\wrapped-link\\chrome-reload-probe.ps1", commands_block)
        self.assertIn("headed navigation, history, and reload behavior on bounded localhost pages.", self.router)

    def test_stop_loading_change_area_keeps_stop_probes_and_auto_resolve_note(self) -> None:
        stop_block = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"stop-loading"\s*\}\s*\{.*?Write-Route\s+-Name\s+"stop-loading"\s+-Commands\s+@\((.*?)\)\s+-Notes\s+@\((.*?)\)\s*.*?break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(stop_block, "stop-loading change area should surface the stop-loading route")
        commands_block = stop_block.group(1)
        notes_block = stop_block.group(2)
        self.assertIn("tmp-browser-smoke\\stop-loading\\chrome-stop-probe.ps1", commands_block)
        self.assertIn("tmp-browser-smoke\\stop-loading\\chrome-stop-input-probe.ps1", commands_block)
        self.assertIn("restored input behavior", notes_block)
        self.assertIn("auto-resolve the repo root and zig-out\\bin\\lightpanda.exe", notes_block)

    def test_input_change_area_keeps_bounded_input_and_google_follow_up(self) -> None:
        input_block = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"input"\s+-or\s+\$ChangeArea\s+-eq\s+"google-input"\s*\}\s*\{(.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(input_block, "input change area should exist")
        block = input_block.group(1)
        self.assertIn('Write-Route -Name "bounded-input"', block)
        self.assertIn("tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1", block)
        self.assertIn("tmp-browser-smoke\\form-controls\\label-click-probe.ps1", block)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', block)
        self.assertIn('Write-Route -Name "manual-google"', block)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', block)

    def test_navigation_and_stop_loading_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("history probe", self.history_probe),
            ("reload probe", self.reload_probe),
            ("stop-loading probe", self.stop_probe),
            ("stop-loading input probe", self.stop_input_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--screenshot_png"', source, f"{label} should still capture a screenshot")

    def test_input_probes_keep_explicit_headed_launches(self) -> None:
        for label, source in (
            ("enter-submit probe", self.enter_submit_probe),
            ("label-click probe", self.label_click_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--window_width"', source, f"{label} should keep explicit window sizing")
            self.assertIn('"--window_height"', source, f"{label} should keep explicit window sizing")


if __name__ == "__main__":
    unittest.main()