import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Show-DefaultRoutes {
    Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
    Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
}

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
    { $ChangeArea -eq "google-shared-enter-order" } {
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these after the shared Enter-order ladder when you want the last shared form-controls keypress-before-submit gate isolated again."
        )
        break
    }
}
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
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck" }
        [ordered]@{ name = "trace-guide"; command = "powershell -ExecutionPolicy Bypass -File $traceGuide" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File $sharedClickFocusProbe -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File $runner" }
        [ordered]@{ name = "raw-probe"; command = "powershell -ExecutionPolicy Bypass -File $rawProbe" }
        [ordered]@{ name = "broader-stack"; command = "powershell -ExecutionPolicy Bypass -File $broaderStack" }
    )
    notes = @(
        "Use the trace guide when you need a quick read on whether the failure stayed before focus, before typed text became visible, or before keypress reached submit.",
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated gate before widening back to the broader shared Enter-order ladder."
    )
}
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

$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File $runner" }
        [ordered]@{ name = "shared-only"; command = "powershell -ExecutionPolicy Bypass -File $sharedRunner" }
        [ordered]@{ name = "google-title-localhost"; command = "powershell -ExecutionPolicy Bypass -File $googleTitleProbe" }
        [ordered]@{ name = "reduced-home-keypress"; command = "powershell -ExecutionPolicy Bypass -File $reducedHomeProbe" }
        [ordered]@{ name = "localhost-enter-order"; command = "powershell -ExecutionPolicy Bypass -File $localhostProbe" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File $sharedClickFocusProbe -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "form-controls-flow"; command = "powershell -ExecutionPolicy Bypass -File $formControlsFlow" }
        [ordered]@{ name = "form-controls-enter-order"; command = "powershell -ExecutionPolicy Bypass -File $formControlsRunner" }
        [ordered]@{ name = "form-controls-trace-guide"; command = "powershell -ExecutionPolicy Bypass -File $formControlsTraceGuide" }
    )
    next_steps = @(
        "Use powershell -ExecutionPolicy Bypass -File $suiteRouterNextSteps when you want the higher-level issue #3 next-step matrix reopened.",
        "Use powershell -ExecutionPolicy Bypass -File $replayRoute when you want the broader issue #3 replay bridge reopened.",
        "Use powershell -ExecutionPolicy Bypass -File $recommendedValidation when you want this stack folded back into the broader localhost-first issue #3 flow."
    )
    notes = @(
        "Use the dedicated form-controls flow helper when you only need the last shared keypress-before-submit gate without printing the wider shared Enter-order ladder.",
        "Use the form-controls trace guide when you want a quick explanation of whether the remaining failure stayed before click focus, before visible text commit, or before keypress reached submit."
    )
}
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md
docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md
scripts/windows/show_headed_validation_suites.ps1
scripts/windows/show_google_input_validation_flow.ps1
scripts/windows/show_google_shared_enter_order_validation_flow.ps1
scripts/windows/run_google_form_controls_enter_order_validation.ps1
tmp-browser-smoke/form-controls/enter-submit-probe.ps1
tmp-browser-smoke/form-controls/google-enter-order-probe.ps1
""",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": r"""
docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md
docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md
scripts/windows/show_headed_validation_suites.ps1
scripts/windows/show_google_shared_enter_order_validation_flow.ps1
scripts/windows/run_google_shared_enter_order_validation.ps1
scripts/windows/run_google_input_validation.ps1
tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1
tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1
tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1
tmp-browser-smoke/form-controls/google-enter-order-probe.ps1
tmp-browser-smoke/form-controls/enter-submit-probe.ps1
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-order-suite-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderValidationSuiteSurfaceTest(unittest.TestCase):
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
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.form_controls_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.shared_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_shared_enter_order_validation_surface.ps1"
        )

    def test_default_router_keeps_both_enter_order_routes_visible(self) -> None:
        self.assertIn(
            'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            self.router,
        )
        self.assertIn(
            'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)',
            self.router,
        )

    def test_form_controls_change_area_keeps_shared_follow_up(self) -> None:
        section_match = re.search(
            r'\{ \$ChangeArea -eq "google-form-controls-enter-order" \} \{(?P<body>.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(section_match, "router should keep the dedicated form-controls change-area branch")
        body = section_match.group("body")
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up"', body)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", body)
        self.assertIn("run_google_shared_enter_order_validation.ps1", body)

    def test_shared_change_area_keeps_dedicated_follow_up(self) -> None:
        section_match = re.search(
            r'\{ \$ChangeArea -eq "google-shared-enter-order" \} \{(?P<body>.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(section_match, "router should keep the shared enter-order change-area branch")
        body = section_match.group("body")
        self.assertIn('Write-Route -Name "dedicated-form-controls-follow-up"', body)
        self.assertIn("(Get-GoogleFormControlsEnterOrderCommands)", body)

    def test_dedicated_flow_keeps_checker_trace_probe_and_broader_stack(self) -> None:
        for marker in (
            "surface-check",
            "trace-guide",
            "shared-click-focus-fallback",
            "recommended",
            "raw-probe",
            "broader-stack",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1",
            r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
        ):
            self.assertIn(marker, self.form_controls_flow)

    def test_shared_flow_keeps_localhost_probe_and_form_controls_ladder(self) -> None:
        for marker in (
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
            "run_google_shared_enter_order_validation.ps1",
            "run_google_input_validation.ps1",
            r"tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r"tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r"tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            "show_google_issue3_suite_router_next_steps.ps1",
            "show_google_issue3_replay_route.ps1",
            "run_google_issue3_recommended_validation.ps1",
        ):
            self.assertIn(marker, self.shared_flow)

    def test_surface_checkers_keep_docs_router_and_probe_references(self) -> None:
        for marker in (
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
        ):
            self.assertIn(marker, self.form_controls_surface)

        for marker in (
            "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md",
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_shared_enter_order_validation.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1",
            "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        ):
            self.assertIn(marker, self.shared_surface)


if __name__ == "__main__":
    unittest.main()
