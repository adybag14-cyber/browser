import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
switch ($true) {
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Section $ChangeArea
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use this after the shared input probes are green when the next question is whether submit still waits until keypress on the Google-style form-controls path."
        )

        Write-Route -Name "manual-google" -Commands @(
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        ) -Notes @(
            "Use this after the bounded input probes are green."
        )

        Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
            (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
            (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
        ) -Notes @(
            "Use the broader attached-page localhost flow when the next step should stay generic before the route narrows into the shorter issue #3 helpers.",
            "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
            "Use the attached-html change-area quickstart when the next step should stay on the shorter issue #3 attached-page ladder before the top-level quickstart or bundle-focused helpers.",
            "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
            "Use the compact bundle-suite helper when the replay should stay pinned to the known three-page compatibility set but you still want the bundle lane printed with the broader attached-page follow-up surfaces before bundle-first replay.",
            "Use the bundle-first helper only after the compact bundle-suite helper has made the pinned three-page route easy to reopen, or when -InputPath already fixes the bundle inputs tightly enough that the narrower bundle-only bridge is the next obvious step.",
            "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder.",
            "Keep the same preferred starting page pinned by rerunning this router with -PreferredInitialPage before switching to the Google-shaped attached-page helper route.",
            "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder.",
            "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
        )
        break
    }
}
""",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "shared-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order" }
        [ordered]@{ name = "form-controls-enter-order-surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "form-controls-enter-order-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1" }
        [ordered]@{ name = "form-controls-enter-order-trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
        [ordered]@{ name = "form-controls-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "issue3-suite-router-handoff"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1" }
        [ordered]@{ name = "issue3-suite-router-next-steps"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1" }
        [ordered]@{ name = "issue3-replay-route"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1" }
        [ordered]@{ name = "issue3-replay-shortcuts"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1" }
        [ordered]@{ name = "issue3-safe-route-entrypoints"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1" }
        [ordered]@{ name = "issue3-safe-route-patch-handoff"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" }
        [ordered]@{ name = "issue3-safe-route-wrapper"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" }
        [ordered]@{ name = "issue3-attached-bundle-suite"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle" }
        [ordered]@{ name = "issue3-attached-bundle-first"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1" }
        [ordered]@{ name = "issue3-attached-bundle-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1" }
        [ordered]@{ name = "issue3-attached-bundle"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait" }
        [ordered]@{ name = "attached-google-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1" }
        [ordered]@{ name = "attached-google"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait" }
        [ordered]@{ name = "trace"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase trace" }
        [ordered]@{ name = "full"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1" }
    )
    notes = @(
        "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the dedicated form-controls gate or the manual Google pass.",
        "Use the form-controls-enter-order-surface-check step before the dedicated form-controls flow, trace guide, or runner when you want the smallest shared later-stage note, helper, and bounded probe chain to fail fast.",
        "Use issue3-suite-router-next-steps when you want the compact matrix that maps the higher-level suite-router start points onto the current replay-route, bundle-first, replay-shortcuts, and safe-route helpers before the replay narrows further.",
        "Use attached-google-flow when you want the current run's attached Google-like HTML pages auto-discovered and the matching localhost-first issue #3 sequence printed before the broader manual follow-up.",
        "Use attached-google when you want the helper to auto-discover current-run attached Google-like HTML pages instead of restating ManualInputPath by hand."
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
Write-Host ("Shared enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ("Shared enter-order title probe port: {0}" -f $TitleProbePort)
Write-Host ("Shared enter-order reduced-home keypress port: {0}" -f $ReducedHomeKeypressPort)
switch ($Phase) {
    "shared-enter-order" {
        Invoke-SharedEnterOrderSequence
    }
}
Write-Host "Next: use -Phase shared-enter-order for the stricter keypress-before-submit wrapper."
""",
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": "# placeholder\n",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": "# placeholder\n",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_suite_router_handoff.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_suite_router_next_steps.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_replay_route.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_replay_shortcuts.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1": "# placeholder\n",
    "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": "# placeholder\n",
    "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/run_attached_html_target_bundle_validation.ps1": "# placeholder\n",
    "scripts/windows/show_google_attached_html_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/run_google_attached_html_validation.ps1": "# placeholder\n",
    "scripts/windows/run_google_issue3_recommended_validation.ps1": "# placeholder\n",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-input-change-area-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleInputChangeAreaValidationSurfaceTest(unittest.TestCase):
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
        cls.google_input_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1"
        )
        cls.main_runner = read_text(cls.repo_root / "scripts/windows/run_google_input_validation.ps1")

    def test_google_input_change_area_keeps_expected_route_sections(self) -> None:
        block_match = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"input"\s+-or\s+\$ChangeArea\s+-eq\s+"google-input"\s*\}\s*\{(.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(block_match, "google-input change area should exist")
        block = block_match.group(1)

        for fragment in (
            'Write-Route -Name "bounded-input"',
            'Write-Route -Name "google-form-controls-enter-order"',
            'Write-Route -Name "manual-google"',
            'Write-Route -Name "issue3-attached-html-follow-up"',
            r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1',
            r'.\tmp-browser-smoke\form-controls\label-click-probe.ps1',
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(fragment, block)

    def test_google_input_change_area_keeps_follow_up_guidance(self) -> None:
        for fragment in (
            "broader attached-page localhost flow",
            "dedicated Google-shaped attached-page flow",
            "attached-html change-area quickstart",
            "top-level attached-page quickstart",
            "compact bundle-suite helper",
            "bundle-first helper",
            "validation-router attached-html surface checker first",
            "-PreferredInitialPage",
            "-SummaryPath",
            "-BrowserExe",
        ):
            self.assertIn(fragment, self.router)

    def test_google_input_flow_keeps_shared_and_issue3_follow_up_steps(self) -> None:
        for step_name in (
            'name = "shared-enter-order"',
            'name = "form-controls-enter-order-surface-check"',
            'name = "form-controls-enter-order-flow"',
            'name = "form-controls-enter-order-trace-guide"',
            'name = "form-controls-enter-order"',
            'name = "issue3-suite-router-handoff"',
            'name = "issue3-suite-router-next-steps"',
            'name = "issue3-replay-route"',
            'name = "issue3-replay-shortcuts"',
            'name = "issue3-safe-route-entrypoints"',
            'name = "issue3-safe-route-patch-handoff"',
            'name = "issue3-safe-route-wrapper"',
            'name = "issue3-attached-bundle-suite"',
            'name = "issue3-attached-bundle-first"',
            'name = "issue3-attached-bundle-flow"',
            'name = "issue3-attached-bundle"',
            'name = "attached-google-flow"',
            'name = "attached-google"',
            'name = "trace"',
            'name = "full"',
        ):
            self.assertIn(step_name, self.google_input_flow)

    def test_google_input_flow_keeps_key_notes(self) -> None:
        for fragment in (
            "stricter keypress-before-submit wrapper",
            "smallest shared later-stage note, helper, and bounded probe chain",
            "compact matrix that maps the higher-level suite-router start points",
            "attached Google-like HTML pages auto-discovered",
            "helper to auto-discover current-run attached Google-like HTML pages",
        ):
            self.assertIn(fragment, self.google_input_flow)

    def test_main_runner_keeps_shared_enter_order_phase_wiring(self) -> None:
        for fragment in (
            'Join-Path $scriptRoot "run_google_shared_enter_order_validation.ps1"',
            'Invoke-ProbeScript -Label "google-shared-enter-order"',
            '"shared-enter-order"',
            "Invoke-SharedEnterOrderSequence",
            "Shared enter-order port:",
            "Shared enter-order title probe port:",
            "Shared enter-order reduced-home keypress port:",
            "use -Phase shared-enter-order for the stricter keypress-before-submit wrapper",
        ):
            self.assertIn(fragment, self.main_runner)

    def test_google_input_surface_scripts_exist(self) -> None:
        for relative_path in (
            "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1",
            "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
            "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
            "scripts/windows/show_google_issue3_replay_route.ps1",
            "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
            "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1",
            "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
            "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1",
            "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1",
            "scripts/windows/run_attached_html_target_bundle_validation.ps1",
            "scripts/windows/show_google_attached_html_validation_flow.ps1",
            "scripts/windows/run_google_attached_html_validation.ps1",
            "scripts/windows/run_google_issue3_recommended_validation.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")


if __name__ == "__main__":
    unittest.main()
