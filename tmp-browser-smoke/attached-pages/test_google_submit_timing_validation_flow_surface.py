from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_submit_timing_validation_flow.ps1": r"""
$surfaceCheck = '.\\scripts\\windows\\check_google_submit_timing_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_submit_timing_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\layout-smoke\\chrome-google-submit-timing-probe.ps1'
$homePhaseRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$traceFlow = '.\\scripts\\windows\\show_google_trace_validation_flow.ps1'
$replayShortcuts = '.\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1'

$flow = [ordered]@{
    issue = "Headed Windows Google submit-timing validation flow"
    focus = "Bounded Google-shaped keydown, keypress, and submit ordering on the real headed surface before the broader shared Enter-order or live Google passes."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the bounded submit-timing guide, helper, wrapper, or raw probe drifted before you trust this narrower issue #3 timing slice."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $surfaceCheck)
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated submit-timing wrapper first so the bounded timing slice stays on the same reusable command surface as the other issue #3 Windows helpers."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $wrapperRunner)
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw submit-timing probe only when you need to narrow a wrapper failure to the underlying Google-shaped headed click, type, and Enter-order path."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $directProbe)
        }
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0} before this wrapper when you want the reduced headed homepage pass first." -f $homePhaseRunner),
        ("Use powershell -ExecutionPolicy Bypass -File {0} after this wrapper is green when you want the stricter shared Enter-order stack printed with the same repo-root, browser, host, and input context." -f $sharedEnterOrderFlow),
        ("Use powershell -ExecutionPolicy Bypass -File {0} when this bounded timing slice is green but the live Google homepage still diverges." -f $traceFlow),
        ("Use powershell -ExecutionPolicy Bypass -File {0} when you want the compact issue #3 replay helper map reopened from this bounded timing slice before switching into attached-page, Windows replay, or safe-route follow-up." -f $replayShortcuts)
    )
    notes = @(
        "Start with the surface check when you want the bounded submit-timing slice to fail fast on missing guide, helper, wrapper, or raw-probe drift before the broader issue #3 ladder.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/layout-smoke.",
        "Keep the same host, port, and input text here when you want the submit-timing slice aligned with the broader issue #3 flow.",
        "Treat this as the bounded bridge between the reduced homepage pass and the stricter shared Enter-order stack."
    )
}
""",
    "scripts/windows/check_google_submit_timing_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_TIMING_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the bounded issue #3 submit-timing slice."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Broader later-stage issue #3 note that routes into the submit-timing slice."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the submit-timing helper."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the bounded submit-timing slice discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the bounded submit-timing slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "One-command bounded submit-timing wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1" -Kind "file" -Purpose "Raw Google-shaped headed keydown, keypress, and submit-ordering probe.")
)
""",
    "scripts/windows/run_google_submit_timing_validation.ps1": r"""
$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "submit-timing"
    Host = $Host
    SubmitTimingPort = $SubmitTimingPort
    InputText = $InputText
}

& $runner @arguments
""",
    "scripts/windows/run_google_input_validation.ps1": r"""
    [ValidateSet("localhost", "title", "home", "input-phase-localhost", "submit-timing", "quick", "shared", "shared-enter-order", "trace", "watch", "manual", "all")]
    [string]$Phase = "all",
    [int]$SubmitTimingPort = 8181,

$submitTimingProbe = Join-Path $probeRoot "layout-smoke\chrome-google-submit-timing-probe.ps1"

function Invoke-SubmitTimingSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $SubmitTimingPort
        InputText = $InputText
    }
    Invoke-ProbeScript -Label "google-submit-timing" -ScriptPath $submitTimingProbe -Arguments $args
}
""",
    "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1": r"""
$pageUrl = "http://$Host`:$Port/google-submit-timing.html"
$outPng = Join-Path $root "google-submit-timing.png"
$browserOut = Join-Path $root "google-submit-timing.browser.stdout.txt"
$browserErr = Join-Path $root "google-submit-timing.browser.stderr.txt"
$serverOut = Join-Path $root "google-submit-timing.server.stdout.txt"
$serverErr = Join-Path $root "google-submit-timing.server.stderr.txt"
$profileRoot = Join-Path $root "profile-google-submit-timing"
$titleAfterTypePattern = "Google Timing Input $InputText*"
$titleAfterEnterPattern = "Google Timing Submitted*$InputText*"
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-submit-timing-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleSubmitTimingValidationFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow = read_text(
            cls.repo_root / "scripts/windows/show_google_submit_timing_validation_flow.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_submit_timing_validation_surface.ps1"
        )
        cls.wrapper = read_text(
            cls.repo_root / "scripts/windows/run_google_submit_timing_validation.ps1"
        )
        cls.input_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_input_validation.ps1"
        )
        cls.raw_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1"
        )

    def test_flow_keeps_surface_check_wrapper_and_direct_probe(self) -> None:
        for fragment in (
            r"$surfaceCheck = '.\\scripts\\windows\\check_google_submit_timing_validation_surface.ps1'",
            r"$wrapperRunner = '.\\scripts\\windows\\run_google_submit_timing_validation.ps1'",
            r"$directProbe = '.\\tmp-browser-smoke\\layout-smoke\\chrome-google-submit-timing-probe.ps1'",
            'name = "surface-check"',
            'name = "wrapper"',
            'name = "direct-probe"',
            "bounded submit-timing guide, helper, wrapper, or raw probe drifted",
            "bounded timing slice stays on the same reusable command surface",
            "Google-shaped headed click, type, and Enter-order path",
        ):
            self.assertIn(fragment, self.flow)

    def test_flow_keeps_next_step_handoffs(self) -> None:
        for fragment in (
            "run_google_input_validation.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "show_google_trace_validation_flow.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
            "reduced headed homepage pass",
            "stricter shared Enter-order stack",
            "live Google homepage still diverges",
            "compact issue #3 replay helper map",
        ):
            self.assertIn(fragment, self.flow)

    def test_flow_notes_preserve_alignment_context(self) -> None:
        for fragment in (
            "Start with the surface check",
            "Start with the wrapper unless you already know you need the direct probe output files",
            "Keep the same host, port, and input text here",
            "Treat this as the bounded bridge between the reduced homepage pass and the stricter shared Enter-order stack.",
        ):
            self.assertIn(fragment, self.flow)

    def test_surface_check_keeps_expected_reference_paths(self) -> None:
        for fragment in (
            'docs/GOOGLE_SUBMIT_TIMING_VALIDATION.md',
            'docs/GOOGLE_SUBMIT_PATH_VALIDATION.md',
            'docs/WINDOWS_FULL_USE.md',
            'scripts/windows/show_headed_validation_suites.ps1',
            'scripts/windows/show_google_submit_timing_validation_flow.ps1',
            'scripts/windows/run_google_submit_timing_validation.ps1',
            'tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1',
        ):
            self.assertIn(fragment, self.surface_check)

    def test_wrapper_still_routes_through_submit_timing_phase(self) -> None:
        for fragment in (
            'Phase = "submit-timing"',
            'Host = $Host',
            'SubmitTimingPort = $SubmitTimingPort',
            'InputText = $InputText',
            '& $runner @arguments',
        ):
            self.assertIn(fragment, self.wrapper)

    def test_input_runner_still_exposes_submit_timing_mode(self) -> None:
        for fragment in (
            '"submit-timing"',
            '[int]$SubmitTimingPort = 8181',
            r'$submitTimingProbe = Join-Path $probeRoot "layout-smoke\chrome-google-submit-timing-probe.ps1"',
            'Invoke-ProbeScript -Label "google-submit-timing" -ScriptPath $submitTimingProbe -Arguments $args',
        ):
            self.assertIn(fragment, self.input_runner)

    def test_raw_probe_keeps_submit_timing_artifacts_and_title_contract(self) -> None:
        for fragment in (
            'http://$Host`:$Port/google-submit-timing.html',
            'google-submit-timing.png',
            'google-submit-timing.browser.stdout.txt',
            'google-submit-timing.browser.stderr.txt',
            'google-submit-timing.server.stdout.txt',
            'google-submit-timing.server.stderr.txt',
            'profile-google-submit-timing',
            'Google Timing Input $InputText*',
            'Google Timing Submitted*$InputText*',
        ):
            self.assertIn(fragment, self.raw_probe)


if __name__ == "__main__":
    unittest.main()
