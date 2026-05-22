import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_recommended_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_issue3_recommended_validation_surface.ps1'
$recommendedRunner = '.\scripts\windows\run_google_issue3_recommended_validation.ps1'
$titleFlow = '.\scripts\windows\show_google_title_validation_flow.ps1'
$quickFlow = '.\scripts\windows\show_google_quick_validation_flow.ps1'
$homepageFixtureFlow = '.\scripts\windows\show_google_homepage_fixture_validation_flow.ps1'
$submitTimingFlow = '.\scripts\windows\show_google_submit_timing_validation_flow.ps1'
$sharedEnterOrderFlow = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
$traceFlow = '.\scripts\windows\show_google_trace_validation_flow.ps1'
$attachedHtmlFlow = '.\scripts\windows\show_google_attached_html_validation_flow.ps1'

$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1" }
        [ordered]@{ name = "title-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1" }
        [ordered]@{ name = "quick-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1" }
        [ordered]@{ name = "homepage-fixture-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1" }
        [ordered]@{ name = "submit-timing-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1" }
        [ordered]@{ name = "shared-enter-order-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1" }
        [ordered]@{ name = "attached-html-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1" }
        [ordered]@{ name = "trace-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1" }
    )
    next_steps = @(
        "Start with the recommended runner when you want one command to prove the bounded localhost-first issue #3 ladder before any real Google capture.",
        "Use the quick flow after the surface check when you want the early title-plus-watch gate spelled out before the reduced homepage pass.",
        "Use the attached-HTML flow after the recommended runner is green when the next question is whether the current saved or attached pages diverge before live Google does.",
        "Use the trace flow only after the bounded localhost, quick, saved-homepage fixture, reduced-home input-phase, submit-timing, and shared Enter-order slices are all green together."
    )
    notes = @(
        "This helper exists to make the one-command recommended runner inspectable before execution, not to replace the narrower flow helpers.",
        "The recommended runner now begins with its own dedicated surface-check and then folds the quick title-plus-watch gate in before the reduced homepage pass so the scripted sequence matches the surrounding docs and helper text.",
        "ManualInputPath and ManualInitialPage are forwarded into the printed attached-HTML flow when they are already known, so the saved-page handoff stays reproducible."
    )
}
""",
    "scripts/windows/run_google_issue3_recommended_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_issue3_recommended_validation_surface.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
$summaryGuide = Join-Path $PSScriptRoot "show_google_issue3_validation_summary_guide.ps1"
$phaseBoundaryHelper = Join-Path $PSScriptRoot "show_google_issue3_phase_boundary.ps1"
$artifactBundleHelper = Join-Path $PSScriptRoot "show_google_issue3_validation_artifact_bundle.ps1"
$handoffHelper = Join-Path $PSScriptRoot "show_google_issue3_validation_handoff.ps1"
$refreshChainHelper = Join-Path $PSScriptRoot "refresh_google_issue3_validation_handoff_chain.ps1"
$homepageFixtureRunner = Join-Path $PSScriptRoot "run_google_homepage_fixture_validation.ps1"

function Invoke-RecommendedPhase {
    param([string]$Phase)
    & $runner -Phase $Phase
}

function Invoke-HomepageFixturePhase {
    & $homepageFixtureRunner
}

function Invoke-RecommendedStep {
    param([string]$Name)
    switch ($Name) {
        "surface-check" { & $surfaceCheck -Json | Set-Content $surfaceCheckArtifactPath }
        "title" { Invoke-RecommendedPhase -Phase "title" }
        "quick" { Invoke-RecommendedPhase -Phase "quick" }
        "homepage-fixture" { Invoke-HomepageFixturePhase }
        "input-phase" { Invoke-RecommendedPhase -Phase "input-phase" }
        "shared" { Invoke-RecommendedPhase -Phase "shared" }
        "submit-timing" { Invoke-RecommendedPhase -Phase "submit-timing" }
        "manual" { Invoke-RecommendedPhase -Phase "manual" }
        "summary-guide" { & $summaryGuide -SummaryPath $SummaryPath -Json | Set-Content $guideArtifactPath }
        "phase-boundary" { & $phaseBoundaryHelper -SummaryPath $SummaryPath -Json | Set-Content $phaseBoundaryArtifactPath }
        "artifact-bundle" { & $artifactBundleHelper -SummaryPath $SummaryPath -Json | Set-Content $artifactBundlePath }
        "handoff" { & $handoffHelper -SummaryPath $SummaryPath -Json | Set-Content $handoffArtifactPath }
        "refresh-chain" { & $refreshChainHelper -SummaryPath $SummaryPath -Json | Set-Content $refreshChainArtifactPath }
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-issue3-recommended-flow-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3RecommendedFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_recommended_validation_flow.ps1"
        )
        cls.runner = read_text(
            cls.repo_root / "scripts/windows/run_google_issue3_recommended_validation.ps1"
        )

    def test_flow_helper_keeps_the_expected_recommended_steps(self) -> None:
        expected_commands = (
            r".\scripts\windows\check_google_issue3_recommended_validation_surface.ps1",
            r".\scripts\windows\run_google_issue3_recommended_validation.ps1",
            r".\scripts\windows\show_google_title_validation_flow.ps1",
            r".\scripts\windows\show_google_quick_validation_flow.ps1",
            r".\scripts\windows\show_google_homepage_fixture_validation_flow.ps1",
            r".\scripts\windows\show_google_submit_timing_validation_flow.ps1",
            r".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_attached_html_validation_flow.ps1",
            r".\scripts\windows\show_google_trace_validation_flow.ps1",
        )
        for command in expected_commands:
            self.assertIn(command, self.flow_helper)

    def test_flow_helper_keeps_quick_gate_manual_followup_and_trace_ordering_notes(self) -> None:
        expected_notes = (
            "surface-check and then folds the quick title-plus-watch gate in before the reduced homepage pass",
            "attached-HTML flow after the recommended runner is green",
            "trace flow only after the bounded localhost, quick, saved-homepage fixture, reduced-home input-phase, submit-timing, and shared Enter-order slices are all green together",
            "ManualInputPath and ManualInitialPage are forwarded into the printed attached-HTML flow",
        )
        for note in expected_notes:
            self.assertIn(note, self.flow_helper)

    def test_runner_keeps_surface_check_phase_helpers_and_artifact_guides(self) -> None:
        expected_fragments = (
            'check_google_issue3_recommended_validation_surface.ps1',
            'run_google_input_validation.ps1',
            'run_google_homepage_fixture_validation.ps1',
            'show_google_issue3_validation_summary_guide.ps1',
            'show_google_issue3_phase_boundary.ps1',
            'show_google_issue3_validation_artifact_bundle.ps1',
            'show_google_issue3_validation_handoff.ps1',
            'refresh_google_issue3_validation_handoff_chain.ps1',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.runner)

    def test_runner_keeps_phase_switches_for_bounded_replay_and_followup(self) -> None:
        expected_phases = (
            '"title" { Invoke-RecommendedPhase -Phase "title" }',
            '"quick" { Invoke-RecommendedPhase -Phase "quick" }',
            '"homepage-fixture" { Invoke-HomepageFixturePhase }',
            '"input-phase" { Invoke-RecommendedPhase -Phase "input-phase" }',
            '"shared" { Invoke-RecommendedPhase -Phase "shared" }',
            '"submit-timing" { Invoke-RecommendedPhase -Phase "submit-timing" }',
            '"manual" { Invoke-RecommendedPhase -Phase "manual" }',
            '"summary-guide" { & $summaryGuide -SummaryPath $SummaryPath -Json | Set-Content $guideArtifactPath }',
            '"phase-boundary" { & $phaseBoundaryHelper -SummaryPath $SummaryPath -Json | Set-Content $phaseBoundaryArtifactPath }',
            '"artifact-bundle" { & $artifactBundleHelper -SummaryPath $SummaryPath -Json | Set-Content $artifactBundlePath }',
            '"handoff" { & $handoffHelper -SummaryPath $SummaryPath -Json | Set-Content $handoffArtifactPath }',
            '"refresh-chain" { & $refreshChainHelper -SummaryPath $SummaryPath -Json | Set-Content $refreshChainArtifactPath }',
        )
        for phase in expected_phases:
            self.assertIn(phase, self.runner)


if __name__ == "__main__":
    unittest.main()
