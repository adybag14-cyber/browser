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

    def test_raw_google_enter_order_probe_keeps_explicit_headed_screenshot_launch(self) -> None:
        assert_explicit_headed_launch(self, self.raw_probe, "google enter-order probe")
        self.assertIn('"--screenshot_png"', self.raw_probe)


if __name__ == "__main__":
    unittest.main()
