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
    "scripts/windows/check_google_title_validation_surface.ps1": r"""
[CmdletBinding()]
$references = @(
    @{ Path = "docs/WINDOWS_FULL_USE.md" },
    @{ Path = "scripts/windows/show_google_input_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_title_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_title_probe_trace_guide.ps1" },
    @{ Path = "scripts/windows/run_google_title_validation.ps1" },
    @{ Path = "scripts/windows/run_google_home_title_probe.ps1" },
    @{ Path = "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" },
    @{ Path = "tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md" },
    @{ Path = "src/browser/tests/page/google_home_title_probe.html" }
)
Write-Host "Google title validation surface is intact."
""",
    "scripts/windows/show_google_title_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_title_validation_surface.ps1'
$wrapperRunner = '.\scripts\windows\run_google_title_validation.ps1'
$traceGuide = '.\scripts\windows\show_google_title_probe_trace_guide.ps1'
$directProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1'
$traceGuidePath = 'tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md'
$flow = [ordered]@{
    read_first_guide = $traceGuidePath
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck" }
        [ordered]@{ name = "read-first"; command = "powershell -ExecutionPolicy Bypass -File $traceGuide" }
        [ordered]@{ name = "wrapper"; command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner" }
        [ordered]@{ name = "direct-probe"; command = "powershell -ExecutionPolicy Bypass -File $directProbe" }
    )
    next_steps = @(
        "Use .\scripts\windows\run_google_quick_validation.ps1 after the title wrapper is green when you want the fast title-plus-watch first pass.",
        "Use .\scripts\windows\run_google_input_validation.ps1 -Phase home after the title wrapper is green when you want the reduced headed homepage submit pass.",
        "Use .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1 when the title wrapper is green and you want the stricter shared Enter-order stack printed before you run it."
    )
    notes = @(
        "Start with the surface-check when you want the bounded title slice to fail fast on missing guide, helper, direct-probe, or fixture drift before the broader issue #3 ladder.",
        "Use .\scripts\windows\check_google_validation_surface.ps1 when you want the whole issue #3 validation surface checked instead of only the narrower title slice.",
        "Start with the read-first guide when you want the marker meanings without opening the markdown note by hand.",
        "The printed guide mirrors $traceGuidePath so the command output and the saved note stay aligned.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/google-investigation-next.",
        "Keep the title wrapper bounded to localhost before moving into the reduced homepage, shared, or live Google trace phases.",
        "Reuse the same host, port, input text, and timing overrides here when you need the title probe to stay aligned with the broader issue #3 validation flow."
    )
}
""",
    "scripts/windows/run_google_title_validation.ps1": r"""
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "title"
    Host = $Host
    TitlePort = $TitlePort
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
& $runner @arguments
""",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "title-surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_title_validation_surface.ps1" }
        [ordered]@{ name = "title-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1" }
        [ordered]@{ name = "title"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1" }
        [ordered]@{ name = "quick-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1" }
        [ordered]@{ name = "quick"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1" }
    )
    notes = @(
        "Use the title-surface-check step before title-flow or title when you want the narrower title guide, helper, direct-probe, and fixture chain to fail fast before you depend on that smaller issue #3 ladder.",
        "Use the title-flow step when you want the dedicated title wrapper and raw probe handoff printed before you run that narrower slice."
    )
}
""",
    "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1": r"""
$browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$probeUrl,"--window_width","1280","--window_height","900","--screenshot_png",$screenshotPath
$titleInitial = Wait-ForGoogleProbeTitle $hwnd @("*BOUND*","*NOQ*","*INIT*")
$titleFocused = Wait-ForGoogleProbeTitle $hwnd @("*FOCUSED*","*FOCUSIN:INPUT:q*","*A=INPUT:q*")
Send-SmokeAsciiText $InputText
$titleTyped = Wait-ForGoogleProbeTitle $hwnd @("*TYPED:$escapedInputText*","*|V=$escapedInputText|*")
Send-SmokeEnter
$titleSubmitted = Wait-ForGoogleProbeTitle $hwnd @("*SUBMIT:$escapedInputText*")
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-title-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleTitleValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_title_validation_surface.ps1"
        )
        cls.flow = read_text(
            cls.repo_root / "scripts/windows/show_google_title_validation_flow.ps1"
        )
        cls.runner = read_text(
            cls.repo_root / "scripts/windows/run_google_title_validation.ps1"
        )
        cls.input_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1"
        )
        cls.title_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1"
        )

    def test_surface_check_keeps_docs_helpers_probe_and_fixture_refs(self) -> None:
        for path in (
            "docs/WINDOWS_FULL_USE.md",
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/show_google_title_validation_flow.ps1",
            "scripts/windows/show_google_title_probe_trace_guide.ps1",
            "scripts/windows/run_google_title_validation.ps1",
            "scripts/windows/run_google_home_title_probe.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md",
            "src/browser/tests/page/google_home_title_probe.html",
        ):
            self.assertIn(path, self.surface_check)

    def test_flow_keeps_surface_read_first_wrapper_and_direct_probe_steps(self) -> None:
        for name in ("surface-check", "read-first", "wrapper", "direct-probe"):
            self.assertIn(f'name = "{name}"', self.flow)
        for command in (
            r".\scripts\windows\check_google_title_validation_surface.ps1",
            r".\scripts\windows\show_google_title_probe_trace_guide.ps1",
            r".\scripts\windows\run_google_title_validation.ps1",
            r".\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
        ):
            self.assertIn(command, self.flow)
        self.assertIn("tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md", self.flow)

    def test_flow_keeps_quick_home_and_shared_follow_up_guidance(self) -> None:
        for snippet in (
            r".\scripts\windows\run_google_quick_validation.ps1",
            r".\scripts\windows\run_google_input_validation.ps1 -Phase home",
            r".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
            "fail fast on missing guide, helper, direct-probe, or fixture drift",
            r".\scripts\windows\check_google_validation_surface.ps1",
            "command output and the saved note stay aligned",
            "bounded to localhost before moving into the reduced homepage, shared, or live Google trace phases",
            "aligned with the broader issue #3 validation flow",
        ):
            self.assertIn(snippet, self.flow)

    def test_runner_keeps_title_phase_and_shared_args(self) -> None:
        self.assertIn('Phase = "title"', self.runner)
        for arg_name in (
            "RepoRoot",
            "BrowserExe",
            "Host",
            "TitlePort",
            "InputText",
            "ServerReadyTimeoutSeconds",
            "HomeWindowReadyAttempts",
            "HomeTitleWaitAttempts",
            "HomePollMilliseconds",
        ):
            self.assertIn(arg_name, self.runner)
        self.assertIn("& $runner @arguments", self.runner)

    def test_main_google_input_flow_keeps_title_slice_before_quick_slice(self) -> None:
        for name in ("title-surface-check", "title-flow", "title", "quick-flow", "quick"):
            self.assertIn(f'name = "{name}"', self.input_flow)
        self.assertIn(r".\scripts\windows\check_google_title_validation_surface.ps1", self.input_flow)
        self.assertIn(r".\scripts\windows\show_google_title_validation_flow.ps1", self.input_flow)
        self.assertIn(r".\scripts\windows\run_google_title_validation.ps1", self.input_flow)
        self.assertIn("narrower title guide, helper, direct-probe, and fixture chain", self.input_flow)

    def test_title_probe_keeps_browse_launch_and_marker_contract(self) -> None:
        self.assertIn('Start-Process -FilePath $BrowserExe -ArgumentList "browse",$probeUrl', self.title_probe)
        for snippet in (
            '"--screenshot_png"',
            '*BOUND*',
            '*FOCUSED*',
            "Send-SmokeAsciiText $InputText",
            "*TYPED:$escapedInputText*",
            "Send-SmokeEnter",
            "*SUBMIT:$escapedInputText*",
        ):
            self.assertIn(snippet, self.title_probe)


if __name__ == "__main__":
    unittest.main()
