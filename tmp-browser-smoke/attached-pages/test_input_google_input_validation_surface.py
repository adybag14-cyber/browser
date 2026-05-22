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
        r"Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?[\"']browse[\"'].*?[\"']--browser_mode[\"'].*?[\"']headed[\"']",
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

Write-Route -Name "bounded-input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
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
    (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
) -Notes @(
    "Keep the attached-page follow-up ladder visible."
)
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
Write-Host "=== google-form-controls-enter-order-surface ==="
& $surfaceCheck @surfaceCheckArgs

Write-Host "=== google-form-controls-enter-order ==="
& $runner @arguments
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$runner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$broaderStack = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-google-input-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputGoogleInputValidationSurfaceTest(unittest.TestCase):
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
        cls.google_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.google_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )

    def test_bounded_input_route_keeps_shared_probes(self) -> None:
        bounded_input = re.search(
            r'Write-Route\s+-Name\s+"bounded-input"\s+-Commands\s+@\((?P<body>.*?)\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            bounded_input,
            "google-input change area should keep the shared bounded-input route on the enter-submit and label-click probes",
        )
        body = bounded_input.group("body")
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1', body)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\label-click-probe.ps1', body)

    def test_google_input_route_keeps_dedicated_form_controls_and_manual_google(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_trace_guide.ps1", commands_block)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", commands_block)
        self.assertIn("run_google_form_controls_enter_order_validation.ps1", commands_block)

        route_surface = re.search(
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            route_surface,
            "google-input change area should keep the dedicated Google form-controls Enter-order route",
        )

        manual_google = re.search(
            r'Write-Route\s+-Name\s+"manual-google"\s+-Commands\s+@\(\s*"& `"\$BrowserExe`" browse --headed `"https://www\.google\.com/`""\s*\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            manual_google,
            "google-input change area should keep the manual Google headed browse step",
        )

    def test_google_input_route_keeps_issue3_attached_html_follow_up_ladder(self) -> None:
        follow_up = re.search(
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+@\((?P<body>.*?)\)\s*-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            follow_up,
            "google-input change area should keep the issue #3 attached-html follow-up ladder",
        )
        body = follow_up.group("body")
        for helper in (
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(helper, body, f"follow-up ladder should keep {helper}")

    def test_input_probes_keep_explicit_headed_screenshot_launches(self) -> None:
        for label, source in (
            ("enter submit probe", self.enter_submit_probe),
            ("label click probe", self.label_click_probe),
        ):
            assert_explicit_headed_launch(self, source, label)
            self.assertIn('"--screenshot_png"', source, f"{label} should still capture a screenshot")

    def test_google_form_controls_scripts_keep_narrowed_runner_chain(self) -> None:
        self.assertIn("google-form-controls-enter-order-surface", self.google_runner)
        self.assertIn("google-form-controls-enter-order", self.google_runner)

        for helper in (
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "google-enter-order-probe.ps1",
            "enter-submit-probe.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
        ):
            self.assertIn(helper, self.google_flow, f"Google form-controls flow should keep {helper}")


if __name__ == "__main__":
    unittest.main()
