import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def normalize_backslashes(source: str) -> str:
    return source.replace("\\\\", "\\")


FIXTURE_FILES = {
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1"
$localhostCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase localhost"
$titleSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_title_validation_surface.ps1"
$titleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
$titleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_title_validation.ps1"
$quickFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_quick_validation_flow.ps1"
$quickCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_quick_validation.ps1"
$homeCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home"
$homepageFixtureSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_homepage_fixture_validation_surface.ps1"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1"
$submitPathSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_path_validation_surface.ps1"
$submitPathFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1"
$submitPathCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_submit_timing_validation.ps1"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared-enter-order"
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
$issue3SuiteRouterHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1"
$issue3SuiteRouterNextStepsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1"
$issue3ReplayRouteCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route.ps1"
$issue3ReplayShortcutsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1"
$issue3SafeRouteEntrypointsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1"
$issue3SafeRoutePatchHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1"
$issue3SafeRouteWrapperCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1"
$issue3AttachedBundleSuiteCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
$issue3AttachedBundleFirstEntrypointCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1"
$issue3AttachedBundleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1"
$issue3AttachedBundleRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait"
$attachedGoogleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
$attachedGoogleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait"
$traceCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase trace"
$watchCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase watch"
$fullCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1"

$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = $surfaceCheckCommand }
        [ordered]@{ name = "localhost"; command = $localhostCommand }
        [ordered]@{ name = "title-surface-check"; command = $titleSurfaceCheckCommand }
        [ordered]@{ name = "title-flow"; command = $titleFlowCommand }
        [ordered]@{ name = "title"; command = $titleCommand }
        [ordered]@{ name = "quick-flow"; command = $quickFlowCommand }
        [ordered]@{ name = "quick"; command = $quickCommand }
        [ordered]@{ name = "home"; command = $homeCommand }
        [ordered]@{ name = "homepage-fixture-surface-check"; command = $homepageFixtureSurfaceCheckCommand }
        [ordered]@{ name = "homepage-fixture-flow"; command = $homepageFixtureFlowCommand }
        [ordered]@{ name = "homepage-fixture"; command = $homepageFixtureCommand }
        [ordered]@{ name = "submit-path-surface-check"; command = $submitPathSurfaceCheckCommand }
        [ordered]@{ name = "submit-path-flow"; command = $submitPathFlowCommand }
        [ordered]@{ name = "submit-path"; command = $submitPathCommand }
        [ordered]@{ name = "submit-timing-flow"; command = $submitTimingFlowCommand }
        [ordered]@{ name = "submit-timing"; command = $submitTimingCommand }
        [ordered]@{ name = "shared"; command = $sharedCommand }
        [ordered]@{ name = "shared-enter-order"; command = $sharedEnterOrderCommand }
        [ordered]@{ name = "form-controls-enter-order-surface-check"; command = $formControlsEnterOrderSurfaceCheckCommand }
        [ordered]@{ name = "form-controls-enter-order-flow"; command = $formControlsEnterOrderFlowCommand }
        [ordered]@{ name = "form-controls-enter-order-trace-guide"; command = $formControlsEnterOrderTraceGuideCommand }
        [ordered]@{ name = "form-controls-enter-order"; command = $formControlsEnterOrderCommand }
        [ordered]@{ name = "issue3-suite-router-handoff"; command = $issue3SuiteRouterHandoffCommand }
        [ordered]@{ name = "issue3-suite-router-next-steps"; command = $issue3SuiteRouterNextStepsCommand }
        [ordered]@{ name = "issue3-replay-route"; command = $issue3ReplayRouteCommand }
        [ordered]@{ name = "issue3-replay-shortcuts"; command = $issue3ReplayShortcutsCommand }
        [ordered]@{ name = "issue3-safe-route-entrypoints"; command = $issue3SafeRouteEntrypointsCommand }
        [ordered]@{ name = "issue3-safe-route-patch-handoff"; command = $issue3SafeRoutePatchHandoffCommand }
        [ordered]@{ name = "issue3-safe-route-wrapper"; command = $issue3SafeRouteWrapperCommand }
        [ordered]@{ name = "issue3-attached-bundle-suite"; command = $issue3AttachedBundleSuiteCommand }
        [ordered]@{ name = "issue3-attached-bundle-first"; command = $issue3AttachedBundleFirstEntrypointCommand }
        [ordered]@{ name = "issue3-attached-bundle-flow"; command = $issue3AttachedBundleFlowCommand }
        [ordered]@{ name = "issue3-attached-bundle"; command = $issue3AttachedBundleRunnerCommand }
        [ordered]@{ name = "attached-google-flow"; command = $attachedGoogleFlowCommand }
        [ordered]@{ name = "attached-google"; command = $attachedGoogleCommand }
        [ordered]@{ name = "trace"; command = $traceCommand }
        [ordered]@{ name = "watch"; command = $watchCommand }
        [ordered]@{ name = "full"; command = $fullCommand }
    )
    saved_page_follow_up = [ordered]@{
        command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase manual -ManualPort 8123 -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'"
    }
}
""",
    "scripts/windows/check_google_validation_surface.ps1": r"""
param([string]$Profile = "issue3")
$profileToScript = @{
    issue3 = "check_headed_validation_surface.ps1"
    title = "check_google_title_validation_surface.ps1"
    "input-phase-localhost" = "check_google_home_input_phase_localhost_validation_surface.ps1"
    "homepage-fixture" = "check_google_homepage_fixture_validation_surface.ps1"
    "submit-path" = "check_google_submit_path_validation_surface.ps1"
    "form-controls-enter-order" = "check_google_form_controls_enter_order_validation_surface.ps1"
    "shared-enter-order" = "check_google_shared_enter_order_validation_surface.ps1"
    trace = "check_google_trace_validation_surface.ps1"
    "attached-html" = "check_google_attached_html_validation_surface.ps1"
    all = "check_headed_validation_surface.ps1"
}
""",
    "scripts/windows/run_google_issue3_recommended_validation.ps1": r"""
$phasePlan = [System.Collections.Generic.List[object]]::new()
$phasePlan.Add([pscustomobject]@{ Name = "localhost"; Action = { Invoke-RecommendedPhase -Phase "localhost" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "quick"; Action = { Invoke-RecommendedPhase -Phase "quick" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "home"; Action = { Invoke-RecommendedPhase -Phase "home" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "homepage-fixture"; Action = { Invoke-HomepageFixturePhase } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "input-phase-localhost"; Action = { Invoke-RecommendedPhase -Phase "input-phase-localhost" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "submit-timing"; Action = { Invoke-RecommendedPhase -Phase "submit-timing" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "shared-enter-order"; Action = { Invoke-RecommendedPhase -Phase "shared-enter-order" } }) | Out-Null
if ($manualPhaseEnabled) {
    $phasePlan.Add([pscustomobject]@{ Name = "manual"; Action = { Invoke-RecommendedPhase -Phase "manual" } }) | Out-Null
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-input-flow-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleInputValidationFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow_script = read_text(cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1")
        cls.surface_script = read_text(cls.repo_root / "scripts/windows/check_google_validation_surface.ps1")
        cls.recommended_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_issue3_recommended_validation.ps1"
        )

    def test_google_input_flow_keeps_key_validation_stages_in_order(self) -> None:
        ordered_names = [
            "surface-check",
            "localhost",
            "title-surface-check",
            "title-flow",
            "title",
            "quick-flow",
            "quick",
            "home",
            "homepage-fixture-surface-check",
            "homepage-fixture-flow",
            "homepage-fixture",
            "submit-path-surface-check",
            "submit-path-flow",
            "submit-path",
            "submit-timing-flow",
            "submit-timing",
            "shared",
            "shared-enter-order",
            "form-controls-enter-order-surface-check",
            "form-controls-enter-order-flow",
            "form-controls-enter-order-trace-guide",
            "form-controls-enter-order",
            "trace",
            "watch",
            "full",
        ]

        positions = []
        for name in ordered_names:
            needle = f'name = "{name}"'
            index = self.flow_script.find(needle)
            self.assertNotEqual(-1, index, f"google input flow should keep the {name} step")
            positions.append(index)

        self.assertEqual(positions, sorted(positions), "google input flow steps should stay in the expected order")

    def test_google_input_flow_keeps_issue3_helper_handoff_chain(self) -> None:
        normalized = normalize_backslashes(self.flow_script)
        for command in (
            r".\scripts\windows\show_google_issue3_suite_router_handoff.ps1",
            r".\scripts\windows\show_google_issue3_suite_router_next_steps.ps1",
            r".\scripts\windows\show_google_issue3_replay_route.ps1",
            r".\scripts\windows\show_google_issue3_replay_shortcuts.ps1",
            r".\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1",
            r".\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
            r".\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1",
            r".\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            r".\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1",
            r".\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1",
            r".\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait",
            r".\scripts\windows\show_google_attached_html_validation_flow.ps1",
            r".\scripts\windows\run_google_attached_html_validation.ps1 -Wait",
        ):
            self.assertIn(command, normalized)

    def test_google_input_flow_keeps_manual_follow_up_template(self) -> None:
        self.assertIn('run_google_input_validation.ps1 -Phase manual', self.flow_script)
        self.assertIn("-ManualInitialPage '<preferred-initial-page>'", self.flow_script)
        self.assertIn("-ManualInputPath '<saved-html-or-folder>'", self.flow_script)

    def test_google_surface_router_keeps_profiles_used_by_flow(self) -> None:
        normalized = normalize_backslashes(self.surface_script)
        for profile_name, script_name in (
            ("title", "check_google_title_validation_surface.ps1"),
            ("homepage-fixture", "check_google_homepage_fixture_validation_surface.ps1"),
            ("submit-path", "check_google_submit_path_validation_surface.ps1"),
            ("form-controls-enter-order", "check_google_form_controls_enter_order_validation_surface.ps1"),
            ("shared-enter-order", "check_google_shared_enter_order_validation_surface.ps1"),
            ("trace", "check_google_trace_validation_surface.ps1"),
            ("attached-html", "check_google_attached_html_validation_surface.ps1"),
        ):
            pattern = re.compile(
                rf'(?:"{re.escape(profile_name)}"|{re.escape(profile_name)})\s*=\s*"{re.escape(script_name)}"'
            )
            self.assertRegex(normalized, pattern)

    def test_recommended_runner_keeps_core_phase_plan(self) -> None:
        for phase_name, phase_expr in (
            ("localhost", 'Invoke-RecommendedPhase -Phase "localhost"'),
            ("quick", 'Invoke-RecommendedPhase -Phase "quick"'),
            ("home", 'Invoke-RecommendedPhase -Phase "home"'),
            ("homepage-fixture", "Invoke-HomepageFixturePhase"),
            ("input-phase-localhost", 'Invoke-RecommendedPhase -Phase "input-phase-localhost"'),
            ("submit-timing", 'Invoke-RecommendedPhase -Phase "submit-timing"'),
            ("shared-enter-order", 'Invoke-RecommendedPhase -Phase "shared-enter-order"'),
        ):
            self.assertIn(f'Name = "{phase_name}"', self.recommended_runner)
            self.assertIn(phase_expr, self.recommended_runner)

        manual_guard = re.search(
            r'if\s*\(\$manualPhaseEnabled\)\s*\{\s*\$phasePlan\.Add\(\[pscustomobject\]@\{\s*Name = "manual"; Action = \{ Invoke-RecommendedPhase -Phase "manual" \} \}\)',
            self.recommended_runner,
            re.DOTALL,
        )
        self.assertIsNotNone(
            manual_guard,
            "recommended runner should keep manual replay as an optional trailing phase",
        )


if __name__ == "__main__":
    unittest.main()
