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

function Get-GoogleSharedEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1"
    )
}

function Get-GoogleFormControlsEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the smallest shared Enter-order checkpoint on the real headed surface.",
        "Run the surface checker first so missing docs, wrappers, or the raw probe fail before you trust the dedicated runner.",
        "Widen back out to the broader shared Enter-order ladder only after this dedicated gate stays green."
    )
}

Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)

switch ($true) {
    { $ChangeArea -eq "google-form-controls-enter-order" } {
        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
        break
    }
}
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": "# placeholder\n",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/run_google_shared_enter_order_validation.ps1": "# placeholder\n",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": "# placeholder\n",
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
        cls.shared_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")

    def test_default_router_keeps_dedicated_google_form_controls_route(self) -> None:
        self.assertRegex(
            self.router,
            re.compile(
                r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)'
            ),
        )
        notes_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderNotes")
        self.assertIn("smallest shared Enter-order checkpoint", notes_block)
        self.assertIn("surface checker first", notes_block)
        self.assertIn("broader shared Enter-order ladder", notes_block)

    def test_dedicated_command_stack_keeps_surface_check_trace_flow_and_runner(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        for script_name in (
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
        ):
            self.assertIn(script_name, commands_block)

    def test_change_area_keeps_shared_enter_order_follow_up(self) -> None:
        dedicated_block = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"google-form-controls-enter-order"\s*\}\s*\{(.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(dedicated_block, "google-form-controls-enter-order change area should exist")
        block = dedicated_block.group(1)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', block)
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up"', block)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", block)
        self.assertIn("run_google_shared_enter_order_validation.ps1", block)
        self.assertIn("broader shared Enter-order ladder back on one surface", block)

    def test_surface_scripts_exist(self) -> None:
        for relative_path in (
            "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1",
            "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "scripts/windows/check_google_shared_enter_order_validation_surface.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_shared_enter_order_validation.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")

    def test_shared_click_focus_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.shared_probe, "shared click-focus probe")
        self.assertIn('"--window_width"', self.shared_probe)
        self.assertIn('"--window_height"', self.shared_probe)
        self.assertIn('"--screenshot_png"', self.shared_probe)


if __name__ == "__main__":
    unittest.main()
