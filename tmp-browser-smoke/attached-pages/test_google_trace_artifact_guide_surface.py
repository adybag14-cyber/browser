from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_trace_artifact_guide.ps1": r"""
$groups = @(
    [pscustomobject]@{
        name = "reduced-trace"
        purpose = "Reduced-home probe logs and screenshot from chrome-google-home-enter-trace-probe.ps1."
        count = 5
        artifacts = @(
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.browser.stdout.txt") -Purpose "Reduced-home headed browser stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.browser.stderr.txt") -Purpose "Reduced-home headed browser stderr." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.server.stdout.txt") -Purpose "Reduced-home localhost server stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.server.stderr.txt") -Purpose "Reduced-home localhost server stderr and submit markers." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.before.png") -Purpose "Reduced-home screenshot captured before the trace typing phase." -TailCount 0
        )
    }
    [pscustomobject]@{
        name = "live-trace"
        purpose = "Real Google homepage probe logs from chrome-google-home-input-probe.ps1."
        count = 2
        artifacts = @(
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-input.browser.stdout.txt") -Purpose "Live Google headed browser stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-input.browser.stderr.txt") -Purpose "Live Google headed browser stderr." -TailCount $TailCount
        )
    }
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "browse-render" -Pattern "browse-render.log" -Purpose "Shared browse-render log written by the browser trace path.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "runtime-renderer" -Pattern "runtime-renderer.log" -Purpose "Shared runtime-renderer log emitted during Google-focused rendering.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "session-wait" -Pattern "session-wait.log" -Purpose "Session wait trace captured while Google-related page readiness is polled.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "runtime-input" -Pattern "runtime-input-backend-*.log" -Purpose "Per-window backend input trace logs from the headed Win32 runtime.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "wndproc-input" -Pattern "wndproc-input-*.log" -Purpose "Per-window Win32 wndproc trace logs for Google-focused input handling.")
)

$activationMarkers = Get-ActivationMarkerSummaries -RepoRoot $resolvedRepoRoot -Groups $groups
$activationOverview = [pscustomobject]@{
    headed_runtime_markers_found = @($activationMarkers | Where-Object { $_.marker -like '* headed runtime' -and $_.found }).Count
    fallback_markers_found = @($activationMarkers | Where-Object { $_.marker -like '* headed fallback' -and $_.found }).Count
    total_markers_found = @($activationMarkers | Where-Object { $_.found }).Count
}

$guide = [pscustomobject]@{
    issue = "Google live trace artifact guide"
    activation_markers = @(
        [pscustomobject]@{ marker = "browse headed runtime"; meaning = "Confirms the browse command stayed on the native headed runtime."; expected_when = "The reduced-home or live Google probe really opened the native headed browser window." }
        [pscustomobject]@{ marker = "browse headed fallback"; meaning = "Shows the browse command dropped to the safe headless runtime instead of staying headed."; expected_when = "A headed request did not keep the native window alive, so later input traces may not describe the intended surface." }
        [pscustomobject]@{ marker = "serve headed runtime"; meaning = "Confirms the server-side headed startup stayed on the native runtime."; expected_when = "A headed serve session for the localhost replay path really kept the native surface active." }
        [pscustomobject]@{ marker = "serve headed fallback"; meaning = "Shows the server-side headed startup dropped to the safe headless runtime."; expected_when = "A headed localhost replay session fell back before the later Google flow could be trusted as a native headed run." }
    )
    activation_overview = $activationOverview
    next_steps = @(
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_trace_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
    )
    notes = @(
        "Check the activation markers first so a headed fallback is visible before you spend time narrowing Google input behavior.",
        "Compare the reduced-home and live-trace outputs before assuming the real Google homepage divergence belongs in the Win32 engine path.",
        "Use the submit-timing and shared Enter-order helpers when the trace logs stop matching the closest bounded localhost checkpoints.",
        "Use the attached-html helper when the next question is whether saved or attached Google-like localhost pages diverge earlier than the live homepage path."
    )
}
""",
    "scripts/windows/show_google_trace_validation_flow.ps1": r"""
$artifactGuide = '.\\scripts\\windows\\show_google_trace_artifact_guide.ps1'
$submitTimingFlow = '.\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1'
$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$attachedHtmlFlow = '.\\scripts\\windows\\show_google_attached_html_validation_flow.ps1'
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1": r"""
$browserOut = Join-Path $root "chrome-google-home-enter-trace.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-enter-trace.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-enter-trace.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-enter-trace.server.stderr.txt"
$pngPath = Join-Path $root "chrome-google-home-enter-trace.before.png"
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1": r"""
$browserOut = Join-Path $root "chrome-google-home-input.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-input.browser.stderr.txt"
$browseRenderLog = Join-Path $root "browse-render.log"
$rendererLog = Join-Path $root "runtime-renderer.log"
$sessionWaitLog = Join-Path $root "session-wait.log"
Get-ChildItem -Path $root -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-trace-artifacts-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleTraceArtifactGuideSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.artifact_guide = read_text(
            cls.repo_root / "scripts/windows/show_google_trace_artifact_guide.ps1"
        )
        cls.trace_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_trace_validation_flow.ps1"
        )
        cls.reduced_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1"
        )
        cls.live_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1"
        )

    def test_artifact_guide_keeps_reduced_and_live_trace_groups(self) -> None:
        for fragment in (
            'name = "reduced-trace"',
            "chrome-google-home-enter-trace.browser.stdout.txt",
            "chrome-google-home-enter-trace.browser.stderr.txt",
            "chrome-google-home-enter-trace.server.stdout.txt",
            "chrome-google-home-enter-trace.server.stderr.txt",
            "chrome-google-home-enter-trace.before.png",
            'name = "live-trace"',
            "chrome-google-home-input.browser.stdout.txt",
            "chrome-google-home-input.browser.stderr.txt",
        ):
            self.assertIn(fragment, self.artifact_guide)

    def test_artifact_guide_keeps_shared_runtime_log_groups(self) -> None:
        for fragment in (
            '-Name "browse-render" -Pattern "browse-render.log"',
            '-Name "runtime-renderer" -Pattern "runtime-renderer.log"',
            '-Name "session-wait" -Pattern "session-wait.log"',
            '-Name "runtime-input" -Pattern "runtime-input-backend-*.log"',
            '-Name "wndproc-input" -Pattern "wndproc-input-*.log"',
        ):
            self.assertIn(fragment, self.artifact_guide)

    def test_artifact_guide_keeps_activation_summary_and_marker_meanings(self) -> None:
        for fragment in (
            "headed_runtime_markers_found",
            "fallback_markers_found",
            "total_markers_found",
            'marker = "browse headed runtime"',
            'marker = "browse headed fallback"',
            'marker = "serve headed runtime"',
            'marker = "serve headed fallback"',
            "The reduced-home or live Google probe really opened the native headed browser window.",
            "A headed localhost replay session fell back before the later Google flow could be trusted as a native headed run.",
        ):
            self.assertIn(fragment, self.artifact_guide)

    def test_artifact_guide_keeps_follow_up_commands_and_notes(self) -> None:
        for fragment in (
            "show_google_trace_validation_flow.ps1",
            "show_google_submit_timing_validation_flow.ps1",
            "show_google_shared_enter_order_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "Check the activation markers first",
            "Compare the reduced-home and live-trace outputs",
            "Use the submit-timing and shared Enter-order helpers",
            "Use the attached-html helper",
        ):
            self.assertIn(fragment, self.artifact_guide)

    def test_trace_flow_still_points_back_to_the_artifact_guide(self) -> None:
        for fragment in (
            "$artifactGuide = '.\\\\scripts\\\\windows\\\\show_google_trace_artifact_guide.ps1'",
            "$submitTimingFlow = '.\\\\scripts\\\\windows\\\\show_google_submit_timing_validation_flow.ps1'",
            "$sharedEnterOrderFlow = '.\\\\scripts\\\\windows\\\\show_google_shared_enter_order_validation_flow.ps1'",
            "$attachedHtmlFlow = '.\\\\scripts\\\\windows\\\\show_google_attached_html_validation_flow.ps1'",
        ):
            self.assertIn(fragment, self.trace_flow)

    def test_probe_artifacts_match_the_guide_contract(self) -> None:
        for fragment in (
            'Join-Path $root "chrome-google-home-enter-trace.browser.stdout.txt"',
            'Join-Path $root "chrome-google-home-enter-trace.browser.stderr.txt"',
            'Join-Path $root "chrome-google-home-enter-trace.server.stdout.txt"',
            'Join-Path $root "chrome-google-home-enter-trace.server.stderr.txt"',
            'Join-Path $root "chrome-google-home-enter-trace.before.png"',
        ):
            self.assertIn(fragment, self.reduced_probe)

        for fragment in (
            'Join-Path $root "chrome-google-home-input.browser.stdout.txt"',
            'Join-Path $root "chrome-google-home-input.browser.stderr.txt"',
            'Join-Path $root "browse-render.log"',
            'Join-Path $root "runtime-renderer.log"',
            'Join-Path $root "session-wait.log"',
            'Filter "runtime-input-backend-*.log"',
            'Filter "wndproc-input-*.log"',
        ):
            self.assertIn(fragment, self.live_probe)


if __name__ == "__main__":
    unittest.main()
