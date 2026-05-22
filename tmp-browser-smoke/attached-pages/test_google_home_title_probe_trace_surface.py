import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'(?:(?:\$psi\.Arguments\s*=)|(?:Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+)).*?browse.*?--browser_mode\s+headed',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1": r"""
$helper = Join-Path $RepoRoot "scripts\windows\watch_headed_probe.ps1"
$probeUrl = "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
$readyUrl = "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html"
$browseTrace = Join-Path $scriptRoot "browse-render.log"
$rendererTrace = Join-Path $scriptRoot "runtime-renderer.log"
$sessionTrace = Join-Path $scriptRoot "session-wait.log"
Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

function Get-TraceTailSummaries([string]$Root, [string]$Pattern) {
    $summaries = @()
    return $summaries
}

function Get-TraceArtifactPaths([string]$Root) {
    $patterns = @(
        "browse-render.log",
        "runtime-renderer.log",
        "session-wait.log",
        "runtime-input-backend-*.log",
        "wndproc-input-*.log"
    )
    return $patterns
}

$helperJson = & $helper `
    -RepoRoot $RepoRoot `
    -BrowserExe $BrowserExe `
    -Url $probeUrl `
    -ExpectedTitleContainsAny @("A=INPUT:q::1", "FOCUSED|") `
    -InputText $InputText `
    -ExpectedTypedTitleContains ("TYPED:{0}" -f $InputText) `
    -SendEnter `
    -ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText)

$result = [pscustomobject]@{
    helper_outcome = $helperOutcome
    helper_failure_stage = if ($helperResult) { $helperResult.failure_stage } else { $null }
    helper_ready_marker = Get-StateField $readyState "marker"
    helper_typed_query_value = Get-StateField $typedState "query_value"
    helper_enter_last_event = Get-StateField $enterState "last_event"
    helper_trace_tail_markers = @($helperTraceTail | ForEach-Object { $_.marker })
    helper_trace_tail_query_values = @($helperTraceTail | ForEach-Object { $_.query_value })
    browse_trace = Get-TraceSummary $browseTrace
    renderer_trace = Get-TraceSummary $rendererTrace
    session_trace = Get-TraceSummary $sessionTrace
    trace_artifacts = @(Get-TraceArtifactPaths $scriptRoot)
    backend_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
    wndproc_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
    backend_trace_tails = @(Get-TraceTailSummaries $scriptRoot "runtime-input-backend-*.log")
    wndproc_trace_tails = @(Get-TraceTailSummaries $scriptRoot "wndproc-input-*.log")
}
""",
    "scripts/windows/watch_headed_probe.ps1": r"""
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $BrowserExe
$psi.Arguments = "browse --browser_mode headed --window_width 1366 --window_height 768 `"$Url`""
$readyMarkers = New-Object System.Collections.Generic.List[string]
foreach ($marker in $ExpectedTitleContainsAny) {
    if (-not $readyMarkers.Contains($marker)) {
        $readyMarkers.Add($marker)
    }
}
if ($matchedReady -and -not $inputSent) {
    Send-SmokeAsciiText $InputText
}
if ($matchedReady -and $matchedTyped -and -not $enterSent) {
    Send-SmokeEnter
}
$result = [pscustomobject]@{
    matched_ready_marker = $readyMarkerMatched
    ready_title_state = $readyTitleState
    typed_title_state = $typedTitleState
    enter_title_state = $enterTitleState
    trace_path = $tracePath
    trace = $trace
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-home-title-trace-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleHomeTitleProbeTraceSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
        )
        cls.helper = read_text(cls.repo_root / "scripts/windows/watch_headed_probe.ps1")

    def test_probe_keeps_google_home_probe_query_route(self) -> None:
        self.assertIn("google_home_title_probe.html?google-home-probe=1", self.probe)
        self.assertIn("google_home_title_probe.html", self.probe)
        self.assertIn("watch_headed_probe.ps1", self.probe)

    def test_probe_keeps_trace_cleanup_and_artifact_catalog(self) -> None:
        expected_fragments = (
            "browse-render.log",
            "runtime-renderer.log",
            "session-wait.log",
            'runtime-input-backend-*.log',
            'wndproc-input-*.log',
            "Get-TraceArtifactPaths",
            "Get-TraceTailSummaries",
            "backend_trace_files",
            "wndproc_trace_files",
            "backend_trace_tails",
            "wndproc_trace_tails",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.probe)

    def test_probe_keeps_expected_helper_handoff_markers(self) -> None:
        expected_fragments = (
            '-ExpectedTitleContainsAny @("A=INPUT:q::1", "FOCUSED|")',
            '-ExpectedTypedTitleContains ("TYPED:{0}" -f $InputText)',
            "-SendEnter",
            '-ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText)',
            "helper_failure_stage",
            "helper_ready_marker",
            "helper_typed_query_value",
            "helper_enter_last_event",
            "helper_trace_tail_markers",
            "helper_trace_tail_query_values",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.probe)

    def test_probe_keeps_helper_outcome_and_trace_summary_fields(self) -> None:
        expected_fragments = (
            "helper_outcome",
            "browse_trace",
            "renderer_trace",
            "session_trace",
            "trace_artifacts",
            "Get-StateField $readyState",
            "Get-StateField $typedState",
            "Get-StateField $enterState",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.probe)

    def test_helper_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.helper, "headed probe helper")
        self.assertIn("--window_width 1366", self.helper)
        self.assertIn("--window_height 768", self.helper)

    def test_helper_keeps_ready_input_and_enter_stages(self) -> None:
        expected_fragments = (
            "ExpectedTitleContainsAny",
            "$readyMarkers",
            "matched_ready_marker",
            "Send-SmokeAsciiText $InputText",
            "Send-SmokeEnter",
            "ready_title_state",
            "typed_title_state",
            "enter_title_state",
            "trace_path",
            "trace = $trace",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.helper)


if __name__ == "__main__":
    unittest.main()
