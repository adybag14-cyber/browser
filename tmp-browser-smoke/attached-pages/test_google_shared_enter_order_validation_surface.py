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
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": r"""
New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the shared Enter-order ladder."
New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the final shared form-controls gate."
New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the shared Enter-order helpers."
New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared headed validation suite router that should keep the google-shared-enter-order slice reachable from the broader catalog."
New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the shared Enter-order slice."
New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "One-command shared Enter-order runner."
New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated fail-fast checker for the final shared form-controls gate."
New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the final shared form-controls gate."
New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."
New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared baseline runner used before the stricter Enter-order probes."
New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Reduced localhost Google title probe used before the Enter-order wrapper."
New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."
New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Localhost Enter-order wrapper used before broader replay."
New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."
New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable click-first shared probe that mirrors the Google-shaped Enter path before the dedicated form-controls gate."
New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Shared form-controls suite note for the final bounded gate."
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
$suiteRouterNextSteps = '.\scripts\windows\show_google_issue3_suite_router_next_steps.ps1'
$replayRoute = '.\scripts\windows\show_google_issue3_replay_route.ps1'
$traceFlow = '.\scripts\windows\show_google_trace_validation_flow.ps1'
$flow = [ordered]@{
    steps = @(
        [ordered]@{
            name = "form-controls-flow"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1"
        }
    )
    next_steps = @(
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1 when you want the higher-level issue #3 next-step matrix reopened with the same repo-root, saved summary, pinned input paths, browser override, host, and shared input context before choosing between replay shortcuts, the attached bundle branch, or the safe-route wrapper chain.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1 when you want the broader issue #3 replay bridge reopened with the same repo-root, saved summary, and pinned input-path context before you widen back out from the shared Enter-order slice.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1 when you want the later live-trace handoff reopened with the same repo-root, browser, host, shared input, and bounded wait settings before the next real Google capture."
    )
    notes = @(
        "The printed next-step commands now preserve the current repo root, custom browser path, host, shared input, Enter mutation, and timing settings where those later helpers support them, including the live-trace handoff.",
        "When SummaryPath or InputPath are supplied, the suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached instead of dropping back to generic route defaults."
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

Write-Host ""
& $sharedRunner @sharedArgs

Write-Host ""
Write-Host "=== google-title-localhost ==="
Write-Host ("Script: {0}" -f $googleTitleProbe)
& $googleTitleProbe @titleProbeArgs

Write-Host ""
Write-Host "=== google-home-keypress-submit ==="
Write-Host ("Script: {0}" -f $reducedHomeKeypressProbe)
& $reducedHomeKeypressProbe @reducedHomeKeypressArgs

Write-Host ""
Write-Host "=== google-enter-order-localhost ==="
Write-Host ("Script: {0}" -f $localhostEnterOrderProbe)
& $localhostEnterOrderProbe @localhostEnterOrderArgs

Write-Host ""
Write-Host "=== form-controls-google-enter-order-surface ==="
Write-Host ("Script: {0}" -f $formControlsEnterOrderSurfaceCheck)
& $formControlsEnterOrderSurfaceCheck @formControlsEnterOrderSurfaceCheckArgs

Write-Host ""
Write-Host "=== form-controls-google-enter-order ==="
Write-Host ("Script: {0}" -f $formControlsEnterOrderRunner)
& $formControlsEnterOrderRunner @formControlsEnterOrderArgs

Write-Host ""
Write-Host "Next: if the shared surface check, shared gates, localhost title probe, reduced-home keypress-before-submit probe, localhost Enter-order wrapper, dedicated shared form-controls surface check, and dedicated shared form-controls Google enter-order runner stay green, move on to the smallest live Google manual pass."
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": "# placeholder\n",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": "# placeholder\n",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order"
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "shared-enter-order"; goal = "Run the shared label baseline, submit gates, and the stricter localhost keypress-before-submit wrapper through the same main runner entrypoint."; command = $sharedEnterOrderCommand },
        [ordered]@{ name = "form-controls-enter-order-surface-check"; goal = "Fail fast if the dedicated shared form-controls Enter-order note, helper, trace guide, or smallest bounded probe drifted out of sync before you depend on that last shared checkpoint."; command = $formControlsEnterOrderSurfaceCheckCommand },
        [ordered]@{ name = "form-controls-enter-order-flow"; goal = "Print the dedicated shared form-controls Enter-order ladder when you want the smallest real-surface keypress-before-submit gate spelled out before you run it."; command = $formControlsEnterOrderFlowCommand },
        [ordered]@{ name = "form-controls-enter-order-trace-guide"; goal = "Read the dedicated shared form-controls Enter-order marker guide when you want the smallest later-stage shared checkpoint translated into the next narrowing step before rerunning it."; command = $formControlsEnterOrderTraceGuideCommand },
        [ordered]@{ name = "form-controls-enter-order"; goal = "Run the dedicated shared form-controls Enter-order gate when you want the smallest later-stage keypress-before-submit proof before attached HTML or live Google replay."; command = $formControlsEnterOrderCommand }
    )
    notes = @(
        "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the dedicated form-controls gate or the manual Google pass."
    )
}
""",
    "scripts/windows/run_google_input_validation.ps1": r"""
$sharedEnterOrderRunner = Join-Path $scriptRoot "run_google_shared_enter_order_validation.ps1"
function Invoke-SharedEnterOrderSequence {
    $args = @{
        SharedEnterOrderPort = $SharedEnterOrderPort
        ReducedHomeKeypressPort = $ReducedHomeKeypressPort
        TitleProbePort = $TitleProbePort
        EnterMutationSuffix = $EnterMutationSuffix
    }
    Invoke-ProbeScript -Label "google-shared-enter-order" -ScriptPath $sharedEnterOrderRunner -Arguments $args
}
switch ($Phase) {
    "shared-enter-order" {
        Invoke-SharedEnterOrderSequence
    }
}
Write-Host "Shared enter-order port: $SharedEnterOrderPort"
Write-Host "Shared enter-order title probe port: $TitleProbePort"
Write-Host "Shared enter-order reduced-home keypress port: $ReducedHomeKeypressPort"
Write-Host "Next: if the shared label baseline, submit gates, stricter enter-order localhost probe, reduced-home input-phase checkpoint, and submit-timing check stay green, move on to the smallest live Google manual pass."
Write-Host "Next: return to -Phase input-phase-localhost or -Phase submit-timing once the label baseline, deferred/basic form-controls, reduced Google-home, and inline-flow probes are green, or use -Phase shared-enter-order for the stricter keypress-before-submit wrapper."
Write-Host "Next: use -Phase quick for the fast title-plus-watch first pass, -IncludeTitleProbe for the quick headed title pass, -Phase input-phase-localhost for the reduced-home localhost keypress-before-submit check, -Phase submit-timing for the bounded Google-shaped keypress-before-submit check, -IncludeSharedInput for the label baseline plus deferred/basic form-controls, reduced Google-home, and inline-flow checks, -IncludeSharedEnterOrder to fold the stricter wrapper into the one-shot flow, -Phase shared-enter-order for the stricter wrapper by itself, -Phase trace for live Google trace capture after the bounded phases, -IncludeWatch for the self-starting title-stream pass, -ManualGoogleStyle for the attached Google-style localhost follow-up, or -ManualInputPath for the saved localhost HTML follow-up before the smallest live Google manual check."
""",
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
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_shared_enter_order_validation_surface.ps1"
        )
        cls.google_input_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1"
        )
        cls.main_runner = read_text(cls.repo_root / "scripts/windows/run_google_input_validation.ps1")
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.shared_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1"
        )
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
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "scripts/windows/run_google_issue3_recommended_validation.ps1",
            "scripts/windows/show_google_attached_html_validation_flow.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")

    def test_shared_surface_checker_keeps_docs_and_probe_references(self) -> None:
        for fragment in (
            "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md",
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "show_headed_validation_suites.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "run_google_shared_enter_order_validation.ps1",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "run_google_input_validation.ps1",
            "chrome-google-title-probe.ps1",
            "chrome-google-home-keypress-submit-probe.ps1",
            "google-enter-order-localhost-probe.ps1",
            "google-enter-order-probe.ps1",
            "enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/README.md",
        ):
            self.assertIn(fragment, self.surface_check)

    def test_google_input_flow_keeps_shared_enter_order_and_dedicated_form_controls_handoff(self) -> None:
        for fragment in (
            "shared-enter-order",
            "run_google_input_validation.ps1 -Phase shared-enter-order",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "stricter keypress-before-submit wrapper",
            "smallest later-stage keypress-before-submit proof",
        ):
            self.assertIn(fragment, self.google_input_flow)

    def test_main_runner_keeps_shared_enter_order_phase_wiring_and_next_steps(self) -> None:
        self.assertIn('Join-Path $scriptRoot "run_google_shared_enter_order_validation.ps1"', self.main_runner)
        self.assertIn('Invoke-ProbeScript -Label "google-shared-enter-order"', self.main_runner)
        self.assertRegex(
            self.main_runner,
            re.compile(r'"shared-enter-order"\s*\{\s*Invoke-SharedEnterOrderSequence', re.DOTALL),
        )
        for fragment in (
            "Shared enter-order port:",
            "Shared enter-order title probe port:",
            "Shared enter-order reduced-home keypress port:",
            "use -Phase shared-enter-order for the stricter keypress-before-submit wrapper",
            "stricter enter-order localhost probe",
        ):
            self.assertIn(fragment, self.main_runner)

    def test_shared_flow_keeps_contextual_next_steps_for_trace_and_suite_router_handoff(self) -> None:
        for fragment in (
            "show_google_issue3_suite_router_next_steps.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_trace_validation_flow.ps1",
            "saved summary, pinned input paths, browser override, host, and shared input context",
            "saved-summary or pinned-bundle context attached",
            "including the live-trace handoff",
        ):
            self.assertIn(fragment, self.shared_flow)

    def test_shared_runner_keeps_surface_to_dedicated_probe_sequence(self) -> None:
        for fragment in (
            '$surfaceCheck = Join-Path $scriptRoot "check_google_shared_enter_order_validation_surface.ps1"',
            '$sharedRunner = Join-Path $scriptRoot "run_google_input_validation.ps1"',
            '$googleTitleProbe = Join-Path $RepoRoot "tmp-browser-smoke\\google-investigation-next\\chrome-google-title-probe.ps1"',
            '$reducedHomeKeypressProbe = Join-Path $RepoRoot "tmp-browser-smoke\\google-home\\chrome-google-home-keypress-submit-probe.ps1"',
            '$localhostEnterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\\google-investigation-next\\google-enter-order-localhost-probe.ps1"',
            '$formControlsEnterOrderSurfaceCheck = Join-Path $scriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"',
            '$formControlsEnterOrderRunner = Join-Path $scriptRoot "run_google_form_controls_enter_order_validation.ps1"',
            '=== google-shared-enter-order-surface ===',
            '=== google-title-localhost ===',
            '=== google-home-keypress-submit ===',
            '=== google-enter-order-localhost ===',
            '=== form-controls-google-enter-order-surface ===',
            '=== form-controls-google-enter-order ===',
            "shared surface check, shared gates, localhost title probe, reduced-home keypress-before-submit probe, localhost Enter-order wrapper, dedicated shared form-controls surface check, and dedicated shared form-controls Google enter-order runner stay green",
        ):
            self.assertIn(fragment, self.shared_runner)

    def test_shared_click_focus_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.shared_probe, "shared click-focus probe")
        self.assertIn('"--window_width"', self.shared_probe)
        self.assertIn('"--window_height"', self.shared_probe)
        self.assertIn('"--screenshot_png"', self.shared_probe)


if __name__ == "__main__":
    unittest.main()
