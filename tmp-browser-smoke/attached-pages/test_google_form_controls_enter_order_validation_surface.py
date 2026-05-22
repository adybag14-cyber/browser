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
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
    )
}

function Get-GoogleFormControlsEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the smallest shared Google-style Enter-order checkpoint on the real headed surface.",
        "Run the surface checker first so missing docs, wrappers, or the raw probe fail before you trust the dedicated runner.",
        "Widen back out to the broader shared Enter-order ladder only after this dedicated gate stays green."
    )
    return $notes
}

Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
$references = @(
    @{ Path = "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" },
    @{ Path = "scripts/windows/show_headed_validation_suites.ps1" },
    @{ Path = "scripts/windows/show_google_input_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1" },
    @{ Path = "scripts/windows/run_google_form_controls_enter_order_validation.ps1" },
    @{ Path = "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" },
    @{ Path = "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" },
    @{ Path = "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1" }
)
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        @{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1" }
        @{ name = "trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
        @{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus -InputText 'Q' -Port 8157" }
        @{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        @{ name = "raw-probe"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1 -InputText 'Q' -Port 8157" }
        @{ name = "broader-stack"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1" }
    )
    notes = @(
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated gate before widening back to the broader shared Enter-order ladder.",
        "Port 8157 is shared on purpose with the broader Enter-order helpers, so one override keeps the dedicated gate, the shared click-first fallback, and the wider stack in sync.",
        "Use the raw probe command only when you need the direct script surface; otherwise prefer the dedicated wrapper so the runbook and issue comments stay consistent."
    )
}
""",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": r"""
$guide = [ordered]@{
    quick_diagnosis = @(
        "No title_after_click or no FOCUS marker means the headed click-focus path is still broken before typing starts.",
        "submit_phase = keydown means the page still submitted too early, before keypress reached the form.",
        "submit_phase = keypress with submit_after_keydown = true and submit_after_keypress = true is the exact green end-state for the dedicated gate."
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
$flow = [ordered]@{
    steps = @(
        @{ name = "form-controls-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1" }
        @{ name = "form-controls-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1 -SharedInputText 'Q' -SharedEnterOrderPort 8157" }
        @{ name = "form-controls-trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
    )
    notes = @(
        "Use the dedicated form-controls flow helper when you only need the last shared keypress-before-submit gate without printing the wider shared Enter-order ladder.",
        "Use the form-controls trace guide when you want a quick explanation of whether the remaining failure stayed before click focus, before visible text commit, or before keypress reached submit."
    )
}
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
if ($GoogleEnterOrder) { $probeMode = "google-enter-order" }
if ($ClickFocus) { [void](Invoke-SmokeClientClick -Hwnd $hwnd -X 170 -Y 82) }
""",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "440", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
if ($submitPhase -ne "keypress") { throw "expected submit phase keypress" }
if (-not $submitAfterKeypress) { throw "form submit happened before Enter keypress reached the page" }
""",
    "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1": r"""
$canonicalProbe = Join-Path $PSScriptRoot "google-enter-order-probe.ps1"
& $canonicalProbe @PSBoundParameters
exit $LASTEXITCODE
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-form-controls-enter-order-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleFormControlsEnterOrderValidationSurfaceTest(unittest.TestCase):
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
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.trace_guide = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1"
        )
        cls.runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.shared_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")
        cls.dedicated_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1"
        )
        cls.compat_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1"
        )

    def test_router_keeps_dedicated_google_form_controls_commands(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        expected_commands = (
            r".\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
        )
        for command in expected_commands:
            self.assertIn(command, commands_block)

        surfaces = re.findall(
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertGreaterEqual(
            len(surfaces),
            2,
            "the dedicated route should stay visible from both the default router and the change-area surface",
        )

    def test_router_notes_keep_dedicated_gate_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderNotes")
        self.assertIn("smallest shared", notes_block)
        self.assertIn("surface checker first", notes_block)
        self.assertIn("raw probe fail before you trust the dedicated runner", notes_block)
        self.assertIn("broader shared Enter-order ladder", notes_block)

    def test_surface_checker_keeps_router_probe_and_shared_ladder_references(self) -> None:
        expected_references = (
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1",
        )
        for reference in expected_references:
            self.assertIn(reference, self.surface_check)

    def test_dedicated_flow_keeps_click_first_fallback_and_broader_stack(self) -> None:
        expected_steps = (
            'name = "surface-check"',
            'name = "trace-guide"',
            'name = "shared-click-focus-fallback"',
            'name = "recommended"',
            'name = "raw-probe"',
            'name = "broader-stack"',
        )
        for step in expected_steps:
            self.assertIn(step, self.flow)

        self.assertIn(r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus", self.flow)
        self.assertIn(r".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1", self.flow)
        self.assertIn("Port 8157 is shared on purpose", self.flow)
        self.assertIn("dedicated wrapper so the runbook and issue comments stay consistent", self.flow)

    def test_trace_guide_keeps_keydown_and_keypress_diagnosis(self) -> None:
        self.assertIn("No title_after_click or no FOCUS marker", self.trace_guide)
        self.assertIn("submit_phase = keydown", self.trace_guide)
        self.assertIn("submit_phase = keypress with submit_after_keydown = true and submit_after_keypress = true", self.trace_guide)

    def test_runner_keeps_surface_check_then_dedicated_probe(self) -> None:
        self.assertIn('Write-Host "=== google-form-controls-enter-order-surface ==="', self.runner)
        self.assertIn('& $surfaceCheck @surfaceCheckArgs', self.runner)
        self.assertIn('Write-Host "=== google-form-controls-enter-order ==="', self.runner)
        self.assertIn(r'tmp-browser-smoke\form-controls\google-enter-order-probe.ps1', self.runner)
        self.assertIn('& $runner @arguments', self.runner)

    def test_shared_flow_keeps_form_controls_follow_up_bridge(self) -> None:
        self.assertIn('name = "form-controls-flow"', self.shared_flow)
        self.assertIn('name = "form-controls-enter-order"', self.shared_flow)
        self.assertIn('name = "form-controls-trace-guide"', self.shared_flow)
        self.assertIn("last shared keypress-before-submit gate", self.shared_flow)
        self.assertIn("before click focus, before visible text commit, or before keypress reached submit", self.shared_flow)

    def test_shared_probe_keeps_google_click_focus_mode(self) -> None:
        assert_explicit_headed_launch(self, self.shared_probe, "shared enter-submit probe")
        self.assertIn('$probeMode = "google-enter-order"', self.shared_probe)
        self.assertIn("Invoke-SmokeClientClick", self.shared_probe)

    def test_dedicated_probe_keeps_headed_launch_and_keypress_contract(self) -> None:
        assert_explicit_headed_launch(self, self.dedicated_probe, "dedicated google enter-order probe")
        self.assertIn('$submitPhase -ne "keypress"', self.dedicated_probe)
        self.assertIn("$submitAfterKeypress", self.dedicated_probe)

    def test_compatibility_wrapper_keeps_canonical_probe_bridge(self) -> None:
        self.assertIn('Join-Path $PSScriptRoot "google-enter-order-probe.ps1"', self.compat_probe)
        self.assertIn("& $canonicalProbe @PSBoundParameters", self.compat_probe)
        self.assertIn("exit $LASTEXITCODE", self.compat_probe)


if __name__ == "__main__":
    unittest.main()
