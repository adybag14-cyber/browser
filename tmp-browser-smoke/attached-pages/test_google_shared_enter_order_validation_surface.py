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

Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes @(
    "Use this when issue #3 is already narrowed to the reusable shared Enter-order ladder between the smaller bounded input probes and the later live Google pass.",
    "Run the shared surface checker first so missing docs, shared wrappers, or reduced localhost probes fail before you trust the wider Enter-order ladder.",
    "Keep the dedicated form-controls flow and trace guide nearby so the last shared keypress-before-submit gate stays easy to reopen without widening all the way back out."
)

switch ($true) {
    { $ChangeArea -eq "google-shared-enter-order" } {
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
        )
        break
    }
}
""",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/run_google_shared_enter_order_validation.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": "# placeholder\n",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": "# placeholder\n",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","420","--window_height","520","--screenshot_png",$pngPath,$probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-shared-enter-order-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleSharedEnterOrderValidationSurfaceTest(unittest.TestCase):
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

    def test_default_router_keeps_google_shared_enter_order_route(self) -> None:
        self.assertRegex(
            self.router,
            re.compile(r'Write-Route\s+-Name\s+"google-shared-enter-order"\s+-Commands\s+\(Get-GoogleSharedEnterOrderCommands\)'),
        )
        self.assertIn("shared surface checker first", self.router)
        self.assertIn("last shared keypress-before-submit gate", self.router)

    def test_shared_enter_order_command_stack_keeps_surface_and_form_controls_follow_up(self) -> None:
        commands_block = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        for script_name in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
        ):
            self.assertIn(script_name, commands_block)

    def test_google_shared_change_area_keeps_dedicated_form_controls_follow_up(self) -> None:
        shared_block = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"google-shared-enter-order"\s*\}\s*\{(.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(shared_block, "google-shared-enter-order change area should exist")
        block = shared_block.group(1)
        self.assertIn('Write-Route -Name "google-shared-enter-order"', block)
        self.assertIn('Write-Route -Name "dedicated-form-controls-follow-up"', block)
        self.assertIn("last shared form-controls keypress-before-submit gate isolated again", block)

    def test_shared_surface_scripts_exist(self) -> None:
        for relative_path in (
            "scripts/windows/check_google_shared_enter_order_validation_surface.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_shared_enter_order_validation.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
            "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")

    def test_shared_click_focus_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.shared_probe, "shared click-focus probe")
        self.assertIn('"--window_width"', self.shared_probe)
        self.assertIn('"--window_height"', self.shared_probe)
        self.assertIn('"--screenshot_png"', self.shared_probe)


if __name__ == "__main__":
    unittest.main()
