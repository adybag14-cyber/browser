import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?["\']browse["\'].*?["\']--browser_mode["\'].*?["\']headed["\']',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/check_google_quick_validation_surface.ps1": r"""
docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md
scripts/windows/show_google_title_validation_flow.ps1
scripts/windows/check_google_title_validation_surface.ps1
scripts/windows/show_google_quick_validation_flow.ps1
scripts/windows/run_google_quick_validation.ps1
scripts/windows/run_google_input_validation.ps1
scripts/windows/run_google_home_watch_probe.ps1
scripts/windows/watch_headed_probe.ps1
tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1
src/browser/tests/page/google_home_title_probe.html
""",
    "scripts/windows/show_google_quick_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_quick_validation_surface.ps1'
$titleFlow = '.\scripts\windows\show_google_title_validation_flow.ps1'
$wrapperRunner = '.\scripts\windows\run_google_quick_validation.ps1'
$directQuickRunner = '.\scripts\windows\run_google_input_validation.ps1'
$watchRunner = '.\scripts\windows\run_google_home_watch_probe.ps1'
[ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck" }
[ordered]@{ name = "title-flow"; command = "powershell -ExecutionPolicy Bypass -File $titleFlow" }
[ordered]@{ name = "wrapper"; command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments" }
[ordered]@{ name = "raw-quick-phase"; command = "powershell -ExecutionPolicy Bypass -File $directQuickRunner -Phase quick$directQuickArguments" }
[ordered]@{ name = "watch-only"; command = "powershell -ExecutionPolicy Bypass -File $watchRunner$watchArguments -SendEnter" }
"Use .\scripts\windows\show_google_home_validation_flow.ps1 after this quick slice is green when you want the reduced homepage gate printed before execution."
"Use .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1 when the next question is whether the saved homepage fixture still agrees with the quick headed proof."
"Use .\scripts\windows\show_google_submit_timing_validation_flow.ps1 when the title and watch phases are green but keydown, keypress, and submit ordering still need a narrower headed check."
"Start with the surface check when you want the fast quick slice to fail fast on missing docs, helper scripts, or watch-probe drift before a longer manual run."
"Start with the title flow helper when you want the quick wrapper to inherit the same focus, typed-text, and Enter marker meanings as the bounded title checkpoint."
"Use the wrapper unless you already know you need the raw quick phase or watch helper by itself."
"Keep the same host, title port, input text, and watch timing overrides here when you want the quick slice aligned with the broader issue #3 runner."
"Treat this quick slice as the bridge between the bounded title checkpoint and the reduced homepage or saved-homepage follow-up, not as a replacement for those later gates."
""",
    "scripts/windows/run_google_quick_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_quick_validation_surface.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
Write-Host "=== google-quick-surface ==="
& $surfaceCheck -RepoRoot $RepoRoot
$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "quick"
    Host = $Host
    InputText = $InputText
    TitlePort = $TitlePort
    WatchPort = $WatchPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}
& $runner @arguments
""",
    "scripts/windows/run_google_issue3_recommended_validation.ps1": r"""
$phasePlan = [System.Collections.Generic.List[object]]::new()
$phasePlan.Add([pscustomobject]@{ Name = "localhost"; Action = { Invoke-RecommendedPhase -Phase "localhost" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "quick"; Action = { Invoke-RecommendedPhase -Phase "quick" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "home"; Action = { Invoke-RecommendedPhase -Phase "home" } }) | Out-Null
""",
    "scripts/windows/run_google_home_watch_probe.ps1": r"""
if (-not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}
$watchScript = Join-Path $scriptRoot "watch_headed_probe.ps1"
if (-not (Test-Path -LiteralPath $watchScript -PathType Leaf)) {
    throw "watch helper not found: $watchScript"
}
$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
$summaryPath = Join-Path $artifactRoot "google-home-watch.summary.json"
$probeUrl = "http://$Host`:$Port$ProbePagePath"
$readyTitleMarkers = @(
    "BOUND|",
    "A=INPUT:q::1",
    "FOCUSED|"
)
$watchArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Url = $probeUrl
    ExpectedTitleContains = $readyTitleMarkers[0]
    ExpectedTitleContainsAny = $readyTitleMarkers[1..($readyTitleMarkers.Count - 1)]
    TimeoutSeconds = $TimeoutSeconds
    PollMilliseconds = $PollMilliseconds
    InputText = $InputText
}
if ($SendEnter) {
    $watchArgs.SendEnter = $true
    $watchArgs.ExpectedEnterTitleContains = "SUBMIT:$InputText"
}
if (-not [string]::IsNullOrWhiteSpace($InputText)) {
    $watchArgs.ExpectedTypedTitleContains = "TYPED:$InputText"
}
$summary | ConvertTo-Json -Depth 8 | Tee-Object -FilePath $summaryPath
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "440", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-quick-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleQuickValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.surface_check = read_text(cls.repo_root / "scripts/windows/check_google_quick_validation_surface.ps1")
        cls.quick_flow = read_text(cls.repo_root / "scripts/windows/show_google_quick_validation_flow.ps1")
        cls.quick_runner = read_text(cls.repo_root / "scripts/windows/run_google_quick_validation.ps1")
        cls.recommended_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_issue3_recommended_validation.ps1"
        )
        cls.watch_runner = read_text(cls.repo_root / "scripts/windows/run_google_home_watch_probe.ps1")
        cls.title_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1"
        )

    def test_surface_check_keeps_docs_helpers_watch_probe_and_fixture_refs(self) -> None:
        for path in (
            "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md",
            "scripts/windows/show_google_title_validation_flow.ps1",
            "scripts/windows/check_google_title_validation_surface.ps1",
            "scripts/windows/show_google_quick_validation_flow.ps1",
            "scripts/windows/run_google_quick_validation.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "scripts/windows/run_google_home_watch_probe.ps1",
            "scripts/windows/watch_headed_probe.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1",
            "src/browser/tests/page/google_home_title_probe.html",
        ):
            self.assertIn(path, self.surface_check)

    def test_quick_flow_keeps_surface_title_wrapper_raw_and_watch_steps(self) -> None:
        for command in (
            r".\scripts\windows\check_google_quick_validation_surface.ps1",
            r".\scripts\windows\show_google_title_validation_flow.ps1",
            r".\scripts\windows\run_google_quick_validation.ps1",
            r".\scripts\windows\run_google_input_validation.ps1",
            r".\scripts\windows\run_google_home_watch_probe.ps1",
        ):
            self.assertIn(command, self.quick_flow)
        self.assertIn('-Phase quick', self.quick_flow)
        self.assertIn('-SendEnter', self.quick_flow)

    def test_quick_flow_keeps_follow_up_and_bridge_guidance(self) -> None:
        for snippet in (
            r".\scripts\windows\show_google_home_validation_flow.ps1",
            r".\scripts\windows\show_google_homepage_fixture_validation_flow.ps1",
            r".\scripts\windows\show_google_submit_timing_validation_flow.ps1",
            "fail fast on missing docs, helper scripts, or watch-probe drift",
            "quick wrapper to inherit the same focus, typed-text, and Enter marker meanings",
            "quick slice aligned with the broader issue #3 runner",
            "bridge between the bounded title checkpoint and the reduced homepage or saved-homepage follow-up",
        ):
            self.assertIn(snippet, self.quick_flow)

    def test_quick_runner_keeps_surface_check_and_quick_phase_args(self) -> None:
        self.assertIn('Write-Host "=== google-quick-surface ==="', self.quick_runner)
        self.assertIn('& $surfaceCheck -RepoRoot $RepoRoot', self.quick_runner)
        self.assertIn('Phase = "quick"', self.quick_runner)
        for arg_name in (
            "TitlePort",
            "WatchPort",
            "ServerReadyTimeoutSeconds",
            "HomeWindowReadyAttempts",
            "HomeTitleWaitAttempts",
            "HomePollMilliseconds",
            "WatchTimeoutSeconds",
            "WatchPollMilliseconds",
        ):
            self.assertIn(arg_name, self.quick_runner)
        self.assertIn("$arguments.LeaveOpen = $true", self.quick_runner)
        self.assertIn("& $runner @arguments", self.quick_runner)

    def test_recommended_runner_keeps_quick_phase_in_main_plan(self) -> None:
        self.assertIn('Name = "localhost"', self.recommended_runner)
        self.assertIn('Name = "quick"', self.recommended_runner)
        self.assertIn('Invoke-RecommendedPhase -Phase "quick"', self.recommended_runner)
        self.assertIn('Name = "home"', self.recommended_runner)

    def test_watch_runner_keeps_binary_watch_helper_and_title_markers(self) -> None:
        for snippet in (
            'headed browser binary not found: $BrowserExe',
            'watch helper not found: $watchScript',
            r'tmp-browser-smoke\headed-probe',
            'google-home-watch.summary.json',
            'http://$Host`:$Port$ProbePagePath',
            '"BOUND|"',
            '"A=INPUT:q::1"',
            '"FOCUSED|"',
            'ExpectedEnterTitleContains = "SUBMIT:$InputText"',
            'ExpectedTypedTitleContains = "TYPED:$InputText"',
            'Tee-Object -FilePath $summaryPath',
        ):
            self.assertIn(snippet, self.watch_runner)

    def test_title_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.title_probe, "google title probe")
        self.assertIn('"--screenshot_png"', self.title_probe)


if __name__ == "__main__":
    unittest.main()
