import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized_backslashes(source: str) -> str:
    return source.replace("\\\\", "\\")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$(?:(?:script:)?browserExe|BrowserExe)\s+-ArgumentList\s+@\("browse",\s*"--browser_mode",\s*"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
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
    (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
) -Notes @(
    "Use the broader attached-page localhost flow when the next step should stay generic before the route narrows into the shorter issue #3 helpers."
)
""",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$localhostCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase localhost"
$homeCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared-enter-order"
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
notes = @(
    "Use shared before a live Google manual check when label activation, input, or submit behavior still looks suspicious.",
    "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the dedicated form-controls gate or the manual Google pass.",
    "Use the form-controls-enter-order step when you want the smallest later-stage shared keypress-before-submit proof before attached-page, manual, or live Google replay."
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
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-bounded-input-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class BoundedInputValidationSurfaceTest(unittest.TestCase):
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
        cls.google_input_flow = read_text(cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1")
        cls.enter_submit_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")
        cls.label_click_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1")

    def test_router_keeps_plain_input_route(self) -> None:
        route_match = re.search(
            r'Write-Route\s+-Name\s+"input"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes\s+@\((?P<notes>.*?)\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(route_match, "router should keep the top-level input route")
        body = normalized_backslashes(route_match.group("body"))
        notes = route_match.group("notes")

        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1', body)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\label-click-probe.ps1', body)
        self.assertIn("bounded input checks already committed on this branch", notes)
        self.assertIn("Use them before live-site or saved-page follow-up.", notes)

    def test_google_input_change_area_keeps_follow_up_routes(self) -> None:
        self.assertIn('Write-Route -Name "bounded-input" -Commands @(', self.router)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', self.router)
        self.assertIn('Write-Route -Name "manual-google" -Commands @(', self.router)
        for command in (
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(command, self.router)

    def test_google_input_flow_keeps_shared_and_dedicated_steps(self) -> None:
        normalized = normalized_backslashes(self.google_input_flow)
        for command in (
            r'.\scripts\windows\run_google_input_validation.ps1 -Phase localhost',
            r'.\scripts\windows\run_google_input_validation.ps1 -Phase home',
            r'.\scripts\windows\run_google_input_validation.ps1 -Phase shared',
            r'.\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order',
            r'.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1',
            r'.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1',
            r'.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1',
            r'.\scripts\windows\run_google_form_controls_enter_order_validation.ps1',
        ):
            self.assertIn(command, normalized)

        for note in (
            "Use shared before a live Google manual check",
            "Use shared-enter-order when the shared gates are green",
            "smallest later-stage shared keypress-before-submit proof",
        ):
            self.assertIn(note, self.google_input_flow)

    def test_bounded_input_probes_keep_explicit_headed_screenshot_launch(self) -> None:
        assert_explicit_headed_launch(self, self.enter_submit_probe, "enter-submit probe")
        assert_explicit_headed_launch(self, self.label_click_probe, "label-click probe")
        self.assertIn('"--screenshot_png"', self.enter_submit_probe)
        self.assertIn('"--screenshot_png"', self.label_click_probe)


if __name__ == "__main__":
    unittest.main()
