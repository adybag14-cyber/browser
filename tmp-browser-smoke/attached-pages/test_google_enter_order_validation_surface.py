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
        r'Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?["\']browse["\'].*?["\']--browser_mode["\'].*?["\']headed["\']',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
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
)
Write-Route -Name "shared-enter-order-follow-up" -Commands @(
    (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
    (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
) -Notes @(
    "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
)
Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
    "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
)
""",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared-enter-order"
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$runner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$broaderStack = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
"Use the trace guide when you need a quick read on whether the failure stayed before focus, before typed text became visible, or before keypress reached submit."
"Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated gate before widening back to the broader shared Enter-order ladder."
"The printed next-step commands now preserve the current repo root, browser path, host, shared input text, shared Enter-order port, and timing settings where those later helpers support them."
"Move on to the smallest live Google manual pass only after the dedicated form-controls gate and the shared click-first fallback stay green together."
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_shared_enter_order_validation_surface.ps1'
$runner = '.\scripts\windows\run_google_shared_enter_order_validation.ps1'
$sharedRunner = '.\scripts\windows\run_google_input_validation.ps1'
$googleTitleProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1'
$reducedHomeProbe = '.\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1'
$localhostProbe = '.\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$formControlsRunner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$formControlsFlow = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$formControlsTraceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$recommendedValidation = '.\scripts\windows\run_google_issue3_recommended_validation.ps1'
$suiteRouterNextSteps = '.\scripts\windows\show_google_issue3_suite_router_next_steps.ps1'
$replayRoute = '.\scripts\windows\show_google_issue3_replay_route.ps1'
$traceFlow = '.\scripts\windows\show_google_trace_validation_flow.ps1'
"When SummaryPath or InputPath are supplied, the suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached instead of dropping back to generic route defaults."
"The higher-level issue #3 route helpers reopened from this flow now also keep the current browser override and host context where those downstream helpers support them."
"Move on to the smallest live Google manual pass only after the localhost title probe, reduced-home keypress probe, shared click-first fallback, and both Enter-order probes stay green together."
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"
Write-Host "=== google-form-controls-enter-order-surface ==="
& $surfaceCheck @surfaceCheckArgs
Write-Host "=== google-form-controls-enter-order ==="
& $runner @arguments
""",
    "scripts/windows/run_google_shared_enter_order_validation.ps1": r"""
$surfaceCheck = Join-Path $scriptRoot "check_google_shared_enter_order_validation_surface.ps1"
$sharedRunner = Join-Path $scriptRoot "run_google_input_validation.ps1"
$googleTitleProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1"
$reducedHomeKeypressProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1"
$localhostEnterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1"
$formControlsEnterOrderSurfaceCheck = Join-Path $scriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderRunner = Join-Path $scriptRoot "run_google_form_controls_enter_order_validation.ps1"
Write-Host "=== google-shared-enter-order-surface ==="
& $surfaceCheck @surfaceCheckArgs
& $sharedRunner @sharedArgs
Write-Host "=== google-title-localhost ==="
& $googleTitleProbe @titleProbeArgs
Write-Host "=== google-home-keypress-submit ==="
& $reducedHomeKeypressProbe @reducedHomeKeypressArgs
Write-Host "=== google-enter-order-localhost ==="
& $localhostEnterOrderProbe @localhostEnterOrderArgs
Write-Host "=== form-controls-google-enter-order-surface ==="
& $formControlsEnterOrderSurfaceCheck @formControlsEnterOrderSurfaceCheckArgs
Write-Host "=== form-controls-google-enter-order ==="
& $formControlsEnterOrderRunner @formControlsEnterOrderArgs
""",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "440", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-order-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.suite_router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")
        cls.google_input_flow = read_text(cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1")
        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.shared_flow = read_text(cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1")
        cls.form_controls_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.shared_runner = read_text(cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1")
        cls.raw_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1")

    def test_suite_router_keeps_dedicated_google_enter_order_routes_visible(self) -> None:
        self.assertIn(
            'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            self.suite_router,
        )
        self.assertIn(
            'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)',
            self.suite_router,
        )

    def test_google_input_flow_keeps_form_controls_and_shared_enter_order_steps(self) -> None:
        normalized = normalized_backslashes(self.google_input_flow)
        for command in (
            r".\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            r".\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order",
        ):
            self.assertIn(command, normalized)

    def test_suite_router_keeps_google_input_change_area_follow_up_surfaces(self) -> None:
        self.assertIn(
            'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            self.suite_router,
        )
        self.assertIn('Write-Route -Name "manual-google" -Commands @(', self.suite_router)
        for command in (
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(command, self.suite_router)

    def test_suite_router_keeps_cross_handoff_between_dedicated_and_shared_routes(self) -> None:
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up" -Commands @(', self.suite_router)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", self.suite_router)
        self.assertIn("run_google_shared_enter_order_validation.ps1", self.suite_router)
        self.assertIn(
            'Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            self.suite_router,
        )

    def test_form_controls_flow_keeps_smallest_google_enter_order_ladder(self) -> None:
        for command in (
            r".\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            r".\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1",
            r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            r".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
        ):
            self.assertIn(command, self.form_controls_flow)

    def test_form_controls_flow_keeps_trace_and_context_guidance(self) -> None:
        for snippet in (
            "before focus, before typed text became visible, or before keypress reached submit",
            "shared click-first fallback",
            "current repo root, browser path, host, shared input text, shared Enter-order port, and timing settings",
            "Move on to the smallest live Google manual pass only after the dedicated form-controls gate and the shared click-first fallback stay green together.",
        ):
            self.assertIn(snippet, self.form_controls_flow)

    def test_shared_enter_order_flow_keeps_broader_and_dedicated_follow_up(self) -> None:
        for command in (
            r".\scripts\windows\check_google_shared_enter_order_validation_surface.ps1",
            r".\scripts\windows\run_google_shared_enter_order_validation.ps1",
            r".\scripts\windows\run_google_input_validation.ps1",
            r".\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r".\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r".\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
        ):
            self.assertIn(command, self.shared_flow)

    def test_shared_enter_order_flow_keeps_context_preserving_next_steps(self) -> None:
        for command in (
            r".\scripts\windows\run_google_issue3_recommended_validation.ps1",
            r".\scripts\windows\show_google_issue3_suite_router_next_steps.ps1",
            r".\scripts\windows\show_google_issue3_replay_route.ps1",
            r".\scripts\windows\show_google_trace_validation_flow.ps1",
        ):
            self.assertIn(command, self.shared_flow)

        for snippet in (
            "suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached",
            "current browser override and host context",
            "Move on to the smallest live Google manual pass only after the localhost title probe, reduced-home keypress probe, shared click-first fallback, and both Enter-order probes stay green together.",
        ):
            self.assertIn(snippet, self.shared_flow)

    def test_google_enter_order_runners_keep_surface_checks_and_probe_chain(self) -> None:
        for command in (
            r"check_google_form_controls_enter_order_validation_surface.ps1",
            r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1",
            "google-form-controls-enter-order-surface",
            "google-form-controls-enter-order",
        ):
            self.assertIn(command, self.form_controls_runner)

        for command in (
            r"check_google_shared_enter_order_validation_surface.ps1",
            r"run_google_input_validation.ps1",
            r"tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r"tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r"tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            r"check_google_form_controls_enter_order_validation_surface.ps1",
            r"run_google_form_controls_enter_order_validation.ps1",
            "google-shared-enter-order-surface",
            "form-controls-google-enter-order",
        ):
            self.assertIn(command, self.shared_runner)

    def test_shared_runner_keeps_expected_probe_order(self) -> None:
        markers = [
            'Write-Host "=== google-shared-enter-order-surface ==="',
            'Write-Host "=== google-title-localhost ==="',
            'Write-Host "=== google-home-keypress-submit ==="',
            'Write-Host "=== google-enter-order-localhost ==="',
            'Write-Host "=== form-controls-google-enter-order-surface ==="',
            'Write-Host "=== form-controls-google-enter-order ==="',
        ]
        offsets = [self.shared_runner.index(marker) for marker in markers]
        self.assertEqual(offsets, sorted(offsets))

    def test_raw_google_enter_order_probe_keeps_explicit_headed_screenshot_launch(self) -> None:
        assert_explicit_headed_launch(self, self.raw_probe, "google enter-order probe")
        self.assertIn('"--screenshot_png"', self.raw_probe)


if __name__ == "__main__":
    unittest.main()
