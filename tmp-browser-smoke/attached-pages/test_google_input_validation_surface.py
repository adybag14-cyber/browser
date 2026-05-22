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
function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1"
    )
}

function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
    )
}

function Get-GoogleSharedEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1"
    )
}

Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)
Write-Route -Name "google-recommended" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
)

Write-Route -Name "bounded-input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
Write-Route -Name "manual-google" -Commands @(
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
)
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
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
    next_steps = @(
        "Move on to the smallest live Google manual pass only after the dedicated form-controls gate and the shared click-first fallback stay green together."
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
    notes = @(
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated form-controls gate before widening back to the broader shared Enter-order ladder."
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
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [string]$InputText = "Q"
)

if ($DeferredEnter -and $GoogleEnterOrder) {
  throw "Choose at most one specialized enter-submit mode."
}

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "http://127.0.0.1:8157/google-enter-order.html")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-input-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleInputValidationSurfaceTest(unittest.TestCase):
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
        cls.enter_submit_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )

    def test_router_keeps_google_enter_order_routes_reachable(self) -> None:
        form_controls_commands = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", form_controls_commands)
        self.assertIn("show_google_form_controls_enter_order_trace_guide.ps1", form_controls_commands)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", form_controls_commands)
        self.assertIn("run_google_form_controls_enter_order_validation.ps1", form_controls_commands)

        shared_commands = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        self.assertIn("check_google_shared_enter_order_validation_surface.ps1", shared_commands)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", shared_commands)
        self.assertIn("run_google_shared_enter_order_validation.ps1", shared_commands)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", shared_commands)

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
            r'Write-Route\s+-Name\s+"google-recommended"\s+-Commands\s+@\(',
        )

    def test_google_input_change_area_keeps_narrow_and_follow_up_routes(self) -> None:
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"bounded-input"\s+-Commands\s+@\(',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"manual-google"\s+-Commands\s+@\(',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)',
        )
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1', self.router)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\label-click-probe.ps1', self.router)

    def test_form_controls_flow_keeps_click_focus_and_broader_stack(self) -> None:
        self.assertIn('name = "surface-check"', self.form_controls_flow)
        self.assertIn('name = "shared-click-focus-fallback"', self.form_controls_flow)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus', self.form_controls_flow)
        self.assertIn('name = "recommended"', self.form_controls_flow)
        self.assertIn(r'.\scripts\windows\run_google_form_controls_enter_order_validation.ps1', self.form_controls_flow)
        self.assertIn('name = "broader-stack"', self.form_controls_flow)
        self.assertIn(r'.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1', self.form_controls_flow)

    def test_form_controls_runner_keeps_surface_check_before_probe(self) -> None:
        self.assertIn('check_google_form_controls_enter_order_validation_surface.ps1', self.form_controls_runner)
        self.assertIn(r'tmp-browser-smoke\form-controls\google-enter-order-probe.ps1', self.form_controls_runner)
        self.assertIn('=== google-form-controls-enter-order-surface ===', self.form_controls_runner)
        self.assertIn('=== google-form-controls-enter-order ===', self.form_controls_runner)

    def test_shared_flow_keeps_localhost_and_form_controls_steps(self) -> None:
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

        self.assertIn(r'.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1', self.shared_flow)
        self.assertIn(r'.\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1', self.shared_flow)
        self.assertIn(r'.\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1', self.shared_flow)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus', self.shared_flow)
        self.assertIn("dedicated form-controls gate", self.shared_flow)

    def test_shared_runner_keeps_ordered_surface_and_probe_calls(self) -> None:
        self.assertIn('=== google-shared-enter-order-surface ===', self.shared_runner)
        self.assertIn('check_google_shared_enter_order_validation_surface.ps1', self.shared_runner)
        self.assertIn('run_google_input_validation.ps1', self.shared_runner)
        self.assertIn(r'tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1', self.shared_runner)
        self.assertIn(r'tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1', self.shared_runner)
        self.assertIn(r'tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1', self.shared_runner)
        self.assertIn('=== form-controls-google-enter-order-surface ===', self.shared_runner)
        self.assertIn('check_google_form_controls_enter_order_validation_surface.ps1', self.shared_runner)
        self.assertIn('=== form-controls-google-enter-order ===', self.shared_runner)
        self.assertIn('run_google_form_controls_enter_order_validation.ps1', self.shared_runner)

    def test_enter_submit_probe_keeps_google_click_focus_mode_and_headed_launch(self) -> None:
        self.assertIn('[switch]$GoogleEnterOrder', self.enter_submit_probe)
        self.assertIn('[switch]$ClickFocus', self.enter_submit_probe)
        self.assertIn('Choose at most one specialized enter-submit mode.', self.enter_submit_probe)
        self.assertIn('ClickFocus currently supports only -GoogleEnterOrder.', self.enter_submit_probe)
        assert_explicit_headed_launch(self, self.enter_submit_probe, "enter-submit probe")


if __name__ == "__main__":
    unittest.main()
