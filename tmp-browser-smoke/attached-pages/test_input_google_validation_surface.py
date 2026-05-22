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
        (Format-HelperCommand -ScriptName 'check_google_form_controls_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_form_controls_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-GoogleSharedEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_shared_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

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

Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
    (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments)
)

Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes @(
    "Use this when issue #3 is already narrowed to the reusable shared Enter-order ladder between the smaller bounded input probes and the later live Google pass."
)
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-google-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputGoogleValidationSurfaceTest(unittest.TestCase):
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
        cls.enter_submit_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )
        cls.label_click_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1"
        )

    def test_default_and_google_input_routes_keep_bounded_input_probes(self) -> None:
        default_surface = re.search(
            r'Write-Route\s+-Name\s+"input"\s+-Commands\s+@\(\s*"powershell -ExecutionPolicy Bypass -File \\.\\tmp-browser-smoke\\form-controls\\enter-submit-probe\.ps1",\s*"powershell -ExecutionPolicy Bypass -File \\.\\tmp-browser-smoke\\form-controls\\label-click-probe\.ps1"\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(default_surface, "default router should keep the bounded input route")

        change_area_surface = re.search(
            r'Write-Route\s+-Name\s+"bounded-input"\s+-Commands\s+@\(\s*"powershell -ExecutionPolicy Bypass -File \\.\\tmp-browser-smoke\\form-controls\\enter-submit-probe\.ps1",\s*"powershell -ExecutionPolicy Bypass -File \\.\\tmp-browser-smoke\\form-controls\\label-click-probe\.ps1"\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            change_area_surface,
            "google-input change area should keep the same bounded input probes",
        )

    def test_google_form_controls_route_keeps_dedicated_helper_stack(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_trace_guide.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", commands_block)
        self.assertIn("run_google_form_controls_enter_order_validation.ps1", commands_block)

        router_surface = re.search(
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            router_surface,
            "google-input change area should keep the dedicated form-controls Enter-order route",
        )

    def test_google_shared_route_keeps_shared_and_dedicated_follow_up(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        self.assertIn("check_google_shared_enter_order_validation_surface.ps1", commands_block)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", commands_block)
        self.assertIn("run_google_shared_enter_order_validation.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_trace_guide.ps1", commands_block)

        router_surface = re.search(
            r'Write-Route\s+-Name\s+"google-shared-enter-order"\s+-Commands\s+\(Get-GoogleSharedEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            router_surface,
            "suite router should keep the shared Enter-order route reachable",
        )

    def test_google_input_route_keeps_manual_google_and_issue3_follow_up(self) -> None:
        manual_google = re.search(
            r'Write-Route\s+-Name\s+"manual-google"\s+-Commands\s+@\(\s*"& `"\$BrowserExe`" browse --headed `"https://www\.google\.com/`""\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            manual_google,
            "google-input change area should still surface the manual Google headed launch",
        )

        issue3_follow_up = re.search(
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+@\(',
            self.router,
        )
        self.assertIsNotNone(
            issue3_follow_up,
            "google-input change area should keep the issue #3 attached-html follow-up route",
        )

    def test_bounded_input_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("enter submit probe", self.enter_submit_probe),
            ("label click probe", self.label_click_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--screenshot_png"', source, f"{label} should keep screenshot capture")


if __name__ == "__main__":
    unittest.main()
