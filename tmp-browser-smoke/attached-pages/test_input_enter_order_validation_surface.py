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
function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_form_controls_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_form_controls_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-GoogleFormControlsEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the smallest shared Enter-order checkpoint on the real headed surface.",
        "Run the surface checker first so missing docs, wrappers, or the raw probe fail before you trust the dedicated runner.",
        "Widen back out to the broader shared Enter-order ladder only after this dedicated gate stays green."
    )
    return $notes
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

function Get-GoogleSharedEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the reusable shared Enter-order ladder between the smaller bounded input probes and the later live Google pass.",
        "Run the shared surface checker first so missing docs, shared wrappers, or reduced localhost probes fail before you trust the wider Enter-order ladder.",
        "Keep the dedicated form-controls flow and trace guide nearby so the last shared keypress-before-submit gate stays easy to reopen without widening all the way back out."
    )
    return $notes
}

Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
Write-Route -Name "bounded-input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "shared-enter-order-follow-up" -Commands @(
    (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
    (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
) -Notes @(
    "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
    "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
)
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md
scripts/windows/show_google_input_validation_flow.ps1
scripts/windows/show_google_shared_enter_order_validation_flow.ps1
scripts/windows/run_form_controls_validation.ps1
scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1
scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1
scripts/windows/run_google_form_controls_enter_order_validation.ps1
tmp-browser-smoke/form-controls/google-enter-order-probe.ps1
tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1
""",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": r"""
docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md
scripts/windows/show_headed_validation_suites.ps1
scripts/windows/show_google_shared_enter_order_validation_flow.ps1
scripts/windows/run_google_shared_enter_order_validation.ps1
scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1
scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1
scripts/windows/run_google_form_controls_enter_order_validation.ps1
tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1
tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1
tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1
tmp-browser-smoke/form-controls/google-enter-order-probe.ps1
tmp-browser-smoke/form-controls/enter-submit-probe.ps1
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
Next: if the shared surface check, shared gates, localhost title probe, reduced-home keypress-before-submit probe, localhost Enter-order wrapper, dedicated shared form-controls surface check, and dedicated shared form-controls Google enter-order runner stay green, move on to the smallest live Google manual pass.
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
[surface-check]
check_google_form_controls_enter_order_validation_surface.ps1
[trace-guide]
show_google_form_controls_enter_order_trace_guide.ps1
[shared-click-focus-fallback]
enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
[recommended]
run_google_form_controls_enter_order_validation.ps1
[raw-probe]
google-enter-order-probe.ps1
[broader-stack]
show_google_shared_enter_order_validation_flow.ps1
Use the trace guide when you need a quick read on whether the failure stayed before focus, before typed text became visible, or before keypress reached submit.
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
[surface-check]
check_google_shared_enter_order_validation_surface.ps1
[recommended]
run_google_shared_enter_order_validation.ps1
[shared-only]
run_google_input_validation.ps1
[google-title-localhost]
chrome-google-title-probe.ps1
[reduced-home-keypress]
chrome-google-home-keypress-submit-probe.ps1
[localhost-enter-order]
google-enter-order-localhost-probe.ps1
[shared-click-focus-fallback]
enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
[form-controls-flow]
show_google_form_controls_enter_order_validation_flow.ps1
[form-controls-enter-order]
run_google_form_controls_enter_order_validation.ps1
[form-controls-trace-guide]
show_google_form_controls_enter_order_trace_guide.ps1
Move on to the smallest live Google manual pass only after the localhost title probe, reduced-home keypress probe, shared click-first fallback, and both Enter-order probes stay green together.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-enter-order-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputEnterOrderValidationSurfaceTest(unittest.TestCase):
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
        cls.form_controls_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.shared_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_shared_enter_order_validation_surface.ps1"
        )
        cls.form_controls_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.shared_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1"
        )
        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )

    def test_bounded_input_route_keeps_shared_input_probes(self) -> None:
        default_route = re.search(
            r'Write-Route\s+-Name\s+"input"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(default_route, "default router should surface the bounded input route")
        self.assertIn(r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1", default_route.group("body"))
        self.assertIn(r"tmp-browser-smoke\form-controls\label-click-probe.ps1", default_route.group("body"))

        change_area_route = re.search(
            r'Write-Route\s+-Name\s+"bounded-input"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(change_area_route, "input change area should keep the bounded input route")
        self.assertIn(r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1", change_area_route.group("body"))
        self.assertIn(r"tmp-browser-smoke\form-controls\label-click-probe.ps1", change_area_route.group("body"))

    def test_form_controls_enter_order_route_keeps_checker_trace_flow_and_runner(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        for snippet in (
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
        ):
            self.assertIn(snippet, commands_block)

        default_route = re.search(
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_route, "default router should surface the dedicated form-controls Enter-order route")

        follow_up_route = re.search(
            r'Write-Route\s+-Name\s+"shared-enter-order-follow-up"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(
            follow_up_route,
            "dedicated form-controls route should keep the broader shared Enter-order follow-up",
        )
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", follow_up_route.group("body"))
        self.assertIn("run_google_shared_enter_order_validation.ps1", follow_up_route.group("body"))

    def test_shared_enter_order_route_keeps_checker_flow_runner_and_dedicated_follow_up(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        for snippet in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
        ):
            self.assertIn(snippet, commands_block)

        default_route = re.search(
            r'Write-Route\s+-Name\s+"google-shared-enter-order"\s+-Commands\s+\(Get-GoogleSharedEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(default_route, "default router should surface the shared Enter-order route")

        follow_up_route = re.search(
            r'Write-Route\s+-Name\s+"dedicated-form-controls-follow-up"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            follow_up_route,
            "shared Enter-order route should keep the dedicated form-controls follow-up",
        )

    def test_router_notes_keep_real_headed_surface_and_escalation_guidance(self) -> None:
        form_controls_notes = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderNotes")
        self.assertIn("smallest shared Enter-order checkpoint", form_controls_notes)
        self.assertIn("real headed surface", form_controls_notes)
        self.assertIn("surface checker first", form_controls_notes)
        self.assertIn("broader shared Enter-order ladder", form_controls_notes)

        shared_notes = extract_function_block(self.router, "Get-GoogleSharedEnterOrderNotes")
        self.assertIn("reusable shared Enter-order ladder", shared_notes)
        self.assertIn("later live Google pass", shared_notes)
        self.assertIn("shared surface checker first", shared_notes)
        self.assertIn("last shared keypress-before-submit gate", shared_notes)

    def test_surface_checkers_keep_expected_cross_links(self) -> None:
        for snippet in (
            "show_google_input_validation_flow.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "google-enter-order-probe.ps1",
            "chrome-google-enter-order-probe.ps1",
        ):
            self.assertIn(snippet, self.form_controls_surface)

        for snippet in (
            "show_headed_validation_suites.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "chrome-google-title-probe.ps1",
            "chrome-google-home-keypress-submit-probe.ps1",
            "google-enter-order-localhost-probe.ps1",
            r"tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        ):
            self.assertIn(snippet, self.shared_surface)

    def test_runners_keep_surface_checks_and_expected_probe_ladders(self) -> None:
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", self.form_controls_runner)
        self.assertIn(r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1", self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order-surface ===", self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order ===", self.form_controls_runner)

        for snippet in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "run_google_input_validation.ps1",
            r"tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r"tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r"tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "smallest live Google manual pass",
        ):
            self.assertIn(snippet, self.shared_runner)

    def test_flow_helpers_keep_click_first_and_trace_guidance(self) -> None:
        for snippet in (
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            "run_google_form_controls_enter_order_validation.ps1",
            "google-enter-order-probe.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "before keypress reached submit",
        ):
            self.assertIn(snippet, self.form_controls_flow)

        for snippet in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "run_google_input_validation.ps1",
            "chrome-google-title-probe.ps1",
            "chrome-google-home-keypress-submit-probe.ps1",
            "google-enter-order-localhost-probe.ps1",
            "enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "smallest live Google manual pass",
        ):
            self.assertIn(snippet, self.shared_flow)


if __name__ == "__main__":
    unittest.main()
