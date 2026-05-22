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


HELPER_SCRIPTS = (
    "check_google_form_controls_enter_order_validation_surface.ps1",
    "show_google_form_controls_enter_order_trace_guide.ps1",
    "show_google_form_controls_enter_order_validation_flow.ps1",
    "run_google_form_controls_enter_order_validation.ps1",
    "check_google_shared_enter_order_validation_surface.ps1",
    "show_google_shared_enter_order_validation_flow.ps1",
    "run_google_shared_enter_order_validation.ps1",
)


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

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
    }

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

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
    }

    return $notes
}

switch ($true) {
    { $SuiteName -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
        break
    }
    { $SuiteName -eq "google-shared-enter-order" } {
        Write-Section "google-shared-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these when the shared Enter-order ladder is already narrowed and you want the last shared form-controls keypress-before-submit gate reopened on its own surface."
        )
        break
    }
    { $ChangeArea -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
        break
    }
    { $ChangeArea -eq "google-shared-enter-order" } {
        Write-Section "google-shared-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
        )
        break
    }
}
""",
}

for helper_name in HELPER_SCRIPTS:
    FIXTURE_FILES[f"scripts/windows/{helper_name}"] = "# helper placeholder\n"


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-order-suite-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderSuiteSurfaceTest(unittest.TestCase):
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

    def test_form_controls_command_stack_keeps_checker_trace_flow_and_runner(self) -> None:
        block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        positions = []
        for helper_name in HELPER_SCRIPTS[:4]:
            self.assertIn(helper_name, block)
            positions.append(block.index(helper_name))
        self.assertEqual(positions, sorted(positions))

    def test_shared_command_stack_keeps_shared_then_dedicated_follow_up_order(self) -> None:
        block = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        positions = []
        for helper_name in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
        ):
            self.assertIn(helper_name, block)
            positions.append(block.index(helper_name))
        self.assertEqual(positions, sorted(positions))

    def test_command_helpers_keep_shared_argument_bundle(self) -> None:
        form_controls_block = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderCommands")
        self.assertEqual(
            4,
            form_controls_block.count("-Arguments $googleFormControlsEnterOrderArguments"),
        )

        shared_block = extract_function_block(self.router, "Get-GoogleSharedEnterOrderCommands")
        self.assertEqual(
            5,
            shared_block.count("-Arguments $googleFormControlsEnterOrderArguments"),
        )

    def test_dedicated_suite_and_change_area_keep_shared_follow_up_route(self) -> None:
        route_matches = re.findall(
            r'Write-Route\s+-Name\s+"shared-enter-order-follow-up"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes',
            self.router,
            re.DOTALL,
        )
        self.assertGreaterEqual(
            len(route_matches),
            2,
            "suite and change-area surfaces should both keep the shared follow-up route",
        )
        for body in route_matches:
            self.assertIn("show_google_shared_enter_order_validation_flow.ps1", body)
            self.assertIn("run_google_shared_enter_order_validation.ps1", body)

    def test_shared_suite_and_change_area_keep_dedicated_follow_up_route(self) -> None:
        route_matches = re.findall(
            r'Write-Route\s+-Name\s+"dedicated-form-controls-follow-up"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)\s+-Notes\s+@\((?P<body>.*?)\)',
            self.router,
            re.DOTALL,
        )
        self.assertGreaterEqual(
            len(route_matches),
            2,
            "suite and change-area surfaces should both keep the dedicated follow-up route",
        )
        self.assertIn("last shared form-controls keypress-before-submit gate", route_matches[0])
        self.assertIn("last shared form-controls keypress-before-submit gate", route_matches[1])

    def test_dedicated_follow_up_notes_keep_distinct_suite_and_change_area_wording(self) -> None:
        self.assertIn(
            "reopened on its own surface.",
            self.router,
        )
        self.assertIn(
            "gate isolated again.",
            self.router,
        )

    def test_suite_notes_keep_dedicated_and_shared_guidance(self) -> None:
        dedicated_notes = extract_function_block(self.router, "Get-GoogleFormControlsEnterOrderNotes")
        self.assertIn("smallest shared Enter-order checkpoint on the real headed surface", dedicated_notes)
        self.assertIn("Run the surface checker first", dedicated_notes)
        self.assertIn("broader shared Enter-order ladder", dedicated_notes)
        self.assertIn("Current browser override: $BrowserExe", dedicated_notes)

        shared_notes = extract_function_block(self.router, "Get-GoogleSharedEnterOrderNotes")
        self.assertIn("reusable shared Enter-order ladder", shared_notes)
        self.assertIn("Run the shared surface checker first", shared_notes)
        self.assertIn("last shared keypress-before-submit gate", shared_notes)
        self.assertIn("Current browser override: $BrowserExe", shared_notes)

    def test_router_keeps_custom_browser_banner_in_each_suite_view(self) -> None:
        self.assertGreaterEqual(self.router.count('Write-Host ("Browser exe: {0}" -f $BrowserExe)'), 4)
        self.assertIn('$SuiteName -eq "google-form-controls-enter-order"', self.router)
        self.assertIn('$SuiteName -eq "google-shared-enter-order"', self.router)
        self.assertIn('$ChangeArea -eq "google-form-controls-enter-order"', self.router)
        self.assertIn('$ChangeArea -eq "google-shared-enter-order"', self.router)

    def test_expected_helper_scripts_exist(self) -> None:
        for helper_name in HELPER_SCRIPTS:
            self.assertTrue(
                (self.repo_root / "scripts/windows" / helper_name).exists(),
                f"expected helper should exist: {helper_name}",
            )


if __name__ == "__main__":
    unittest.main()
