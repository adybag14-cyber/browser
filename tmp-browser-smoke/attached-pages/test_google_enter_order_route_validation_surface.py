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


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "shared-enter-order-follow-up" -Commands @(
    (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
    (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
    "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
)
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$runner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$broaderStack = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "raw-probe"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1" }
        [ordered]@{ name = "broader-stack"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1" }
    )
}
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"
Write-Host "=== google-form-controls-enter-order-surface ==="
& $surfaceCheck @surfaceCheckArgs
Write-Host "=== google-form-controls-enter-order ==="
& $runner @arguments
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
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1" }
        [ordered]@{ name = "shared-only"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared" }
        [ordered]@{ name = "google-title-localhost"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1" }
        [ordered]@{ name = "reduced-home-keypress"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1" }
        [ordered]@{ name = "localhost-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "form-controls-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1" }
        [ordered]@{ name = "form-controls-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "form-controls-trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
    )
}
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
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-order-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderRouteValidationSurfaceTest(unittest.TestCase):
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
        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.form_controls_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.shared_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1"
        )

    def test_suite_router_keeps_google_enter_order_routes_visible(self) -> None:
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"google-shared-enter-order"\s+-Commands\s+\(Get-GoogleSharedEnterOrderCommands\)',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"shared-enter-order-follow-up"\s+-Commands\s+@\(',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"dedicated-form-controls-follow-up"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
        )

    def test_form_controls_flow_keeps_surface_trace_and_broader_stack(self) -> None:
        for snippet in (
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1",
            r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
        ):
            self.assertIn(snippet, self.form_controls_flow)

        for step_name in (
            "surface-check",
            "trace-guide",
            "shared-click-focus-fallback",
            "recommended",
            "raw-probe",
            "broader-stack",
        ):
            self.assertIn(f'name = "{step_name}"', self.form_controls_flow)

    def test_form_controls_runner_keeps_surface_check_then_probe(self) -> None:
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", self.form_controls_runner)
        self.assertIn(r'tmp-browser-smoke\form-controls\google-enter-order-probe.ps1', self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order-surface ===", self.form_controls_runner)
        self.assertIn("& $surfaceCheck @surfaceCheckArgs", self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order ===", self.form_controls_runner)
        self.assertIn("& $runner @arguments", self.form_controls_runner)

    def test_shared_flow_keeps_localhost_and_form_controls_chain(self) -> None:
        for snippet in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "run_google_input_validation.ps1",
            r"tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r"tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r"tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
        ):
            self.assertIn(snippet, self.shared_flow)

        for step_name in (
            "surface-check",
            "recommended",
            "shared-only",
            "google-title-localhost",
            "reduced-home-keypress",
            "localhost-enter-order",
            "shared-click-focus-fallback",
            "form-controls-flow",
            "form-controls-enter-order",
            "form-controls-trace-guide",
        ):
            self.assertIn(f'name = "{step_name}"', self.shared_flow)

    def test_shared_runner_keeps_shared_then_localhost_then_form_controls_sequence(self) -> None:
        markers = (
            "check_google_shared_enter_order_validation_surface.ps1",
            "run_google_input_validation.ps1",
            r'tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1',
            r'tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1',
            r'tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1',
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
        )
        for marker in markers:
            self.assertIn(marker, self.shared_runner)

        expected_calls = (
            "& $surfaceCheck @surfaceCheckArgs",
            "& $sharedRunner @sharedArgs",
            "& $googleTitleProbe @titleProbeArgs",
            "& $reducedHomeKeypressProbe @reducedHomeKeypressArgs",
            "& $localhostEnterOrderProbe @localhostEnterOrderArgs",
            "& $formControlsEnterOrderSurfaceCheck @formControlsEnterOrderSurfaceCheckArgs",
            "& $formControlsEnterOrderRunner @formControlsEnterOrderArgs",
        )
        for call in expected_calls:
            self.assertIn(call, self.shared_runner)


if __name__ == "__main__":
    unittest.main()
