import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$homepageFixtureSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_homepage_fixture_validation_surface.ps1"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1$leaveOpenArgument"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1$leaveOpenArgument"
$submitPathSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_path_validation_surface.ps1"
$submitPathFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1"
$submitPathCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared-enter-order"
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
$attachedGoogleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1$attachedGoogleInitialPageArgument$leaveOpenArgument"
$attachedGoogleCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1$attachedGoogleInitialPageArgument -Wait"
$attachedBundleInputPathArgument = ""
$issue3SuiteRouterHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_handoff.ps1$attachedBundleInputPathArgument"
$issue3SuiteRouterNextStepsCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1$attachedBundleInputPathArgument"
$issue3ReplayRouteCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1$attachedBundleInputPathArgument"
$issue3ReplayShortcutsCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1$attachedBundleInputPathArgument"
$issue3SafeRouteEntrypointsCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1"
$issue3SafeRoutePatchHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1"
$issue3SafeRouteWrapperCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1"
$issue3AttachedBundleSuiteCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
$issue3AttachedBundleFirstEntrypointCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1$attachedBundleInputPathArgument"
$issue3AttachedBundleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1$attachedBundleInputPathArgument"
$issue3AttachedBundleRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1$attachedBundleInputPathArgument -Wait"
$traceCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase trace$leaveOpenArgument"
$watchCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase watch$leaveOpenArgument"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner$manualGoogleStyleArgument$leaveOpenArgument"
$manualInitialPageArgument = ""
$attachedGoogleInitialPageArgument = ""

if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $attachedBundleInputPathArgument = " -InputPath " + ($quotedPaths -join ", ")
}

steps = @(
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

common_overrides = @(
    "-HomepageFixturePort 8155",
    "-SubmitTimingPort 8181",
    "-SharedEnterOrderPort 8157",
    "-ManualPort 8123",
    "-SharedInputText Q",
    "-TraceInputText lightpanda"
)

notes = @(
    "Use the homepage-fixture-surface-check step before homepage-fixture-flow or homepage-fixture when you want the dedicated note, helper, wrapper, and raw probe chain to fail fast before you widen into the later submit-path ladder.",
    "Use the submit-path-surface-check step before submit-path-flow or submit-path when you want the later issue #3 note, helper, trace guide, and bounded probes to fail fast before you depend on that narrower ladder.",
    "Use submit-timing after the homepage-fixture or submit-path pass when you want one extra Google-shaped headed check before the shared form-controls and inline-flow gates.",
    "Use the form-controls-enter-order-surface-check step before the dedicated form-controls flow, trace guide, or runner when you want the smallest shared later-stage note, helper, and bounded probe chain to fail fast.",
    "Use issue3-safe-route-entrypoints when you want the newest fresh replay, reuse-current-outputs, refresh-status, handoff-safe, summary-guide-safe, and runner-wiring-safe commands printed together before choosing the next narrower replay branch.",
    "When SummaryPath or InputPath are supplied, the suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached instead of dropping back to generic route defaults.",
    "When ManualInitialPage is set, the printed attached-google-flow and attached-google commands keep that page preferred for the auto-discovered attached-page path.",
    "When ManualInputPath is provided, the printed full command, issue3-suite-router-handoff helper, issue3-suite-router-next-steps helper, issue3-replay-route helper, issue3-replay-shortcuts helper, issue3-attached-bundle-first helper, issue3-attached-bundle flow, and issue3-attached-bundle runner also preserve the same fixed input set for the bundle-first route instead of relying on auto-discovery.",
    "When ManualGoogleStyle is set, the printed manual and full commands auto-discover current-run attached HTML under user_files first and then agent_files, and they prefer a Google-like attached page when ManualInitialPage is not set.",
    "When LeaveOpen is set, the printed quick-flow, quick, homepage-fixture-flow, homepage-fixture, watch, trace, manual, full, and attached-google-flow commands keep the headed follow-up state easier to inspect after the bounded automation phases finish."
)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-input-later-stage-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleInputLaterStageValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow = read_text(cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1")

    def assert_in_order(self, *snippets: str) -> None:
        offsets = [self.flow.index(snippet) for snippet in snippets]
        self.assertEqual(offsets, sorted(offsets))

    def test_keeps_later_stage_step_commands(self) -> None:
        expected = (
            "check_google_homepage_fixture_validation_surface.ps1",
            "show_google_homepage_fixture_validation_flow.ps1",
            "run_google_homepage_fixture_validation.ps1",
            "check_google_submit_path_validation_surface.ps1",
            "show_google_submit_path_validation_flow.ps1",
            "run_google_issue3_submit_path_validation.ps1",
            "show_google_submit_timing_validation_flow.ps1",
            "run_google_submit_timing_validation.ps1",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "show_google_form_controls_enter_order_validation_flow.ps1",
            "show_google_form_controls_enter_order_trace_guide.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
            "show_google_issue3_suite_router_handoff.ps1",
            "show_google_issue3_suite_router_next_steps.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
            "show_google_issue3_safe_route_entrypoints.ps1",
            "run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
            "show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "run_google_attached_html_validation.ps1",
        )
        for snippet in expected:
            self.assertIn(snippet, self.flow)

    def test_keeps_later_stage_step_order(self) -> None:
        self.assert_in_order(
            'name = "homepage-fixture-surface-check"',
            'name = "homepage-fixture-flow"',
            'name = "homepage-fixture"',
            'name = "submit-path-surface-check"',
            'name = "submit-path-flow"',
            'name = "submit-path"',
            'name = "submit-timing-flow"',
            'name = "submit-timing"',
            'name = "shared"',
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
            'name = "watch"',
            'name = "full"',
        )

    def test_keeps_context_preserving_bundle_and_attached_arguments(self) -> None:
        for snippet in (
            '$manualInitialPageArgument = ""',
            '$attachedGoogleInitialPageArgument = ""',
            '$attachedBundleInputPathArgument = ""',
            '$attachedGoogleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1$attachedGoogleInitialPageArgument$leaveOpenArgument"',
            '$attachedGoogleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1$attachedGoogleInitialPageArgument -Wait"',
            '$issue3SuiteRouterHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1$attachedBundleInputPathArgument"',
            '$issue3AttachedBundleFirstEntrypointCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1$attachedBundleInputPathArgument"',
        ):
            self.assertIn(snippet, self.flow)

    def test_keeps_common_overrides_for_later_stage_alignment(self) -> None:
        for override in (
            "-HomepageFixturePort 8155",
            "-SubmitTimingPort 8181",
            "-SharedEnterOrderPort 8157",
            "-ManualPort 8123",
            "-SharedInputText Q",
            "-TraceInputText lightpanda",
        ):
            self.assertIn(override, self.flow)

    def test_keeps_notes_for_later_stage_and_manual_context(self) -> None:
        expected = (
            "Use the homepage-fixture-surface-check step before homepage-fixture-flow or homepage-fixture",
            "Use the submit-path-surface-check step before submit-path-flow or submit-path",
            "Use submit-timing after the homepage-fixture or submit-path pass",
            "Use the form-controls-enter-order-surface-check step before the dedicated form-controls flow, trace guide, or runner",
            "Use issue3-safe-route-entrypoints when you want the newest fresh replay",
            "When SummaryPath or InputPath are supplied, the suite-router next-step and replay-route helpers now keep that same saved-summary or pinned-bundle context attached",
            "When ManualInitialPage is set, the printed attached-google-flow and attached-google commands keep that page preferred",
            "When ManualInputPath is provided, the printed full command, issue3-suite-router-handoff helper, issue3-suite-router-next-steps helper, issue3-replay-route helper, issue3-replay-shortcuts helper, issue3-attached-bundle-first helper, issue3-attached-bundle flow, and issue3-attached-bundle runner also preserve the same fixed input set",
            "When ManualGoogleStyle is set, the printed manual and full commands auto-discover current-run attached HTML",
            "When LeaveOpen is set, the printed quick-flow, quick, homepage-fixture-flow, homepage-fixture, watch, trace, manual, full, and attached-google-flow commands keep the headed follow-up state easier to inspect",
        )
        for snippet in expected:
            self.assertIn(snippet, self.flow)


if __name__ == "__main__":
    unittest.main()
