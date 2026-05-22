from __future__ import annotations

import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_google_trace_validation_flow.ps1": r"""
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "lightpanda",
    [int]$WindowReadyAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
)

$suiteRouterEntry = '.\scripts\windows\show_headed_validation_suites.ps1'
$surfaceCheck = '.\scripts\windows\check_google_trace_validation_surface.ps1'
$reducedTraceProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-home-enter-trace-probe.ps1'
$wrapperRunner = '.\scripts\windows\run_google_input_validation.ps1'
$liveTraceProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-home-input-probe.ps1'
$artifactGuide = '.\scripts\windows\show_google_trace_artifact_guide.ps1'
$submitTimingFlow = '.\scripts\windows\show_google_submit_timing_validation_flow.ps1'
$sharedEnterOrderFlow = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
$attachedHtmlFlow = '.\scripts\windows\show_google_attached_html_validation_flow.ps1'

$flow = [ordered]@{
    steps = @(
        [ordered]@{
            name = "suite-router"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-input'"
        }
        [ordered]@{
            name = "surface-check"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_trace_validation_surface.ps1"
        }
        [ordered]@{
            name = "reduced-trace"
            command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-enter-trace-probe.ps1"
        }
        [ordered]@{
            name = "wrapper"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase 'trace' -TraceInputText 'lightpanda' -TraceWindowReadyAttempts 80 -TracePollMilliseconds 250"
        }
        [ordered]@{
            name = "direct-live-probe"
            command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-input-probe.ps1"
        }
    )
    next_steps = @(
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_artifact_guide.ps1 after any reduced-home or live Google capture when you want the current trace files, their tails, and the closest follow-up helpers printed on one surface.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1 when you need to re-walk the bounded keydown, keypress, and submit ordering with the same repo-root, browser, host, and input context before another live capture.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1 when you want the stricter shared Enter-order stack printed with the same repo-root, browser, host, and input context before the next live trace rerun.",
        "Use powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 when the next question is whether the current attached or saved Google-style localhost pages diverge before the live Google homepage does."
    )
    notes = @(
        "Start with the nearest supported shared suite-router entry when you need the higher-level Google input lane, its neighboring suites, and the dedicated helper surface reintroduced before you dive into raw trace commands.",
        "Run the trace surface checker first so missing guides, runner wiring, or probe files fail before the later-stage capture looks trustworthy.",
        "After any capture, print the trace artifact guide so the reduced-home logs, live-home logs, and Google-focused runtime traces stay on one repeatable inspection surface.",
        "Treat this helper as a later-stage investigation handoff, not the first gate. Start with the reduced localhost probes and shared input stacks first.",
        "Use the wrapper unless you already know you need the raw direct probe outputs from tmp-browser-smoke/google-investigation-next.",
        "When LeaveOpen is set, the reduced and live trace commands keep the headed window open after capture so the real surface can be inspected before teardown.",
        "The printed handoff commands preserve the current repo root, browser path, host, input text, and LeaveOpen mode where those later helpers support them. The top-level router handoff now uses the nearest real supported entry instead of a nonexistent google-live-trace suite name."
    )
}
""",
    "scripts/windows/check_google_trace_validation_surface.ps1": r"""
$references = @(
    @{ Path = "docs/GOOGLE_TRACE_VALIDATION.md"; Exists = $true },
    @{ Path = "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md"; Exists = $true },
    @{ Path = "docs/WINDOWS_FULL_USE.md"; Exists = $true },
    @{ Path = "scripts/windows/show_headed_validation_suites.ps1"; Exists = $true },
    @{ Path = "scripts/windows/show_google_input_validation_flow.ps1"; Exists = $true },
    @{ Path = "scripts/windows/show_google_submit_path_validation_flow.ps1"; Exists = $true },
    @{ Path = "scripts/windows/run_google_issue3_submit_path_validation.ps1"; Exists = $true },
    @{ Path = "scripts/windows/show_google_trace_validation_flow.ps1"; Exists = $true },
    @{ Path = "scripts/windows/show_google_trace_artifact_guide.ps1"; Exists = $true },
    @{ Path = "scripts/windows/run_google_trace_validation.ps1"; Exists = $true },
    @{ Path = "scripts/windows/run_google_input_validation.ps1"; Exists = $true },
    @{ Path = "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1"; Exists = $true },
    @{ Path = "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1"; Exists = $true }
)
""",
    "scripts/windows/check_google_validation_surface.ps1": r"""
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
    "scripts/windows/run_google_input_validation.ps1": r"""
param(
    [ValidateSet("localhost", "title", "home", "input-phase-localhost", "submit-timing", "quick", "shared", "shared-enter-order", "trace", "watch", "manual", "all")]
    [string]$Phase = "all",
    [string]$TraceInputText = "lightpanda",
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250,
    [switch]$LeaveOpen
)

$liveGoogleTraceProbe = Join-Path $googleLocalhostRoot "chrome-google-home-input-probe.ps1"

function Invoke-TraceSequence {
    $args = @{
        TraceInputText = $TraceInputText
        TraceWindowReadyAttempts = $TraceWindowReadyAttempts
        TracePollMilliseconds = $TracePollMilliseconds
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home-live-trace" -ScriptPath $liveGoogleTraceProbe -Arguments $args
}

switch ($Phase) {
    "trace" {
        Invoke-TraceSequence
    }
}

Write-Host "Next: inspect the captured real-Google trace tails, then compare them with the nearest bounded localhost, reduced-homepage, reduced-home input-phase, or submit-timing phase before changing the headed input path."
""",
    "scripts/windows/run_google_issue3_recommended_validation.ps1": r"""
param(
    [string]$TraceInputText = "lightpanda",
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250
)

$basePhaseArguments = @{
    TraceInputText = $TraceInputText
    TraceWindowReadyAttempts = $TraceWindowReadyAttempts
    TracePollMilliseconds = $TracePollMilliseconds
}
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "720", "--screenshot_png", $pngPath, $probeUrl)
$titleAfterKeydown = Wait-TitleLike -ProcessId $browser.Id -Needle "KEYDOWN:" -Attempts 20
$titleAfterKeypress = Wait-TitleLike -ProcessId $browser.Id -Needle "KEYPRESS:Enter:" -Attempts 20
$titleAfterSubmit = Wait-TitleLike -ProcessId $browser.Id -Needle "SUBMIT:" -Attempts 80
$traceArtifacts = Get-TraceArtifactPaths -Root $root
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1": r"""
$browser = Start-Process -FilePath $BrowserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "1366", "--window_height", "768", "https://www.google.com/")
$resultsNavigationLikely = ($traceText -match "google\.com/search") -or ($traceText -match "search\?q=")
$runtimeInputLogs = @(Get-ChildItem -Path $root -Filter "runtime-input-backend-*.log")
$wndprocLogs = @(Get-ChildItem -Path $root -Filter "wndproc-input-*.log")
$browserGone = $false
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-trace-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleTraceValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.trace_flow = read_text(cls.repo_root / "scripts/windows/show_google_trace_validation_flow.ps1")
        cls.trace_surface = read_text(cls.repo_root / "scripts/windows/check_google_trace_validation_surface.ps1")
        cls.surface_router = read_text(cls.repo_root / "scripts/windows/check_google_validation_surface.ps1")
        cls.main_runner = read_text(cls.repo_root / "scripts/windows/run_google_input_validation.ps1")
        cls.recommended_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_issue3_recommended_validation.ps1"
        )
        cls.reduced_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1"
        )
        cls.live_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1"
        )

    def test_trace_flow_keeps_expected_step_order(self) -> None:
        ordered_names = [
            "suite-router",
            "surface-check",
            "reduced-trace",
            "wrapper",
            "direct-live-probe",
        ]
        positions = []
        for name in ordered_names:
            needle = f'name = "{name}"'
            index = self.trace_flow.find(needle)
            self.assertNotEqual(-1, index, f"trace flow should keep the {name} step")
            positions.append(index)
        self.assertEqual(positions, sorted(positions))

    def test_trace_flow_keeps_suite_router_wrapper_and_direct_probe_commands(self) -> None:
        for fragment in (
            r".\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-input'",
            r".\scripts\windows\check_google_trace_validation_surface.ps1",
            r".\tmp-browser-smoke\google-investigation-next\chrome-google-home-enter-trace-probe.ps1",
            r".\scripts\windows\run_google_input_validation.ps1 -Phase 'trace'",
            r".\tmp-browser-smoke\google-investigation-next\chrome-google-home-input-probe.ps1",
            r"-TraceInputText 'lightpanda'",
            r"-TraceWindowReadyAttempts 80",
            r"-TracePollMilliseconds 250",
        ):
            self.assertIn(fragment, self.trace_flow)

    def test_trace_flow_keeps_artifact_and_follow_up_handoffs(self) -> None:
        for fragment in (
            r".\scripts\windows\show_google_trace_artifact_guide.ps1",
            r".\scripts\windows\show_google_submit_timing_validation_flow.ps1",
            r".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_attached_html_validation_flow.ps1",
            "reduced-home logs, live-home logs, and Google-focused runtime traces",
            "nearest real supported entry instead of a nonexistent google-live-trace suite name",
            "Use the wrapper unless you already know you need the raw direct probe outputs",
            "LeaveOpen mode",
        ):
            self.assertIn(fragment, self.trace_flow)

    def test_trace_surface_checker_keeps_docs_runner_and_probe_references(self) -> None:
        expected_paths = (
            "docs/GOOGLE_TRACE_VALIDATION.md",
            "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/show_google_submit_path_validation_flow.ps1",
            "scripts/windows/run_google_issue3_submit_path_validation.ps1",
            "scripts/windows/show_google_trace_validation_flow.ps1",
            "scripts/windows/show_google_trace_artifact_guide.ps1",
            "scripts/windows/run_google_trace_validation.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1",
        )
        for path in expected_paths:
            self.assertIn(path, self.trace_surface)

    def test_google_surface_router_keeps_trace_profile_mapping(self) -> None:
        self.assertIn('trace = "check_google_trace_validation_surface.ps1"', self.surface_router)

    def test_main_runner_keeps_trace_phase_wiring_and_next_step_guidance(self) -> None:
        for fragment in (
            '"trace"',
            "TraceInputText",
            "TraceWindowReadyAttempts",
            "TracePollMilliseconds",
            "LeaveOpen",
            'Join-Path $googleLocalhostRoot "chrome-google-home-input-probe.ps1"',
            'Invoke-ProbeScript -Label "google-home-live-trace"',
            "inspect the captured real-Google trace tails",
            "reduced-home input-phase",
            "submit-timing phase",
        ):
            self.assertIn(fragment, self.main_runner)

    def test_recommended_runner_keeps_trace_inputs_available_for_follow_up(self) -> None:
        for fragment in (
            '[string]$TraceInputText = "lightpanda"',
            "[int]$TraceWindowReadyAttempts = 80",
            "[int]$TracePollMilliseconds = 250",
            "TraceInputText = $TraceInputText",
            "TraceWindowReadyAttempts = $TraceWindowReadyAttempts",
            "TracePollMilliseconds = $TracePollMilliseconds",
        ):
            self.assertIn(fragment, self.recommended_runner)

    def test_reduced_trace_probe_keeps_headed_launch_and_event_markers(self) -> None:
        assert_explicit_headed_launch(self, self.reduced_probe, "reduced-home trace probe")
        for fragment in (
            '"--screenshot_png"',
            'Needle "KEYDOWN:"',
            'Needle "KEYPRESS:Enter:"',
            'Needle "SUBMIT:"',
            "Get-TraceArtifactPaths -Root $root",
        ):
            self.assertIn(fragment, self.reduced_probe)

    def test_live_trace_probe_keeps_headed_launch_and_runtime_log_tails(self) -> None:
        assert_explicit_headed_launch(self, self.live_probe, "live Google trace probe")
        for fragment in (
            "google\\.com/search",
            'search\\?q=',
            'runtime-input-backend-*.log',
            'wndproc-input-*.log',
            "$browserGone",
        ):
            self.assertIn(fragment, self.live_probe)


if __name__ == "__main__":
    unittest.main()
