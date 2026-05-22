import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized_backslashes(source: str) -> str:
    return source.replace("\\\\", "\\")


FIXTURE_FILES = {
    "scripts/windows/show_saved_page_google_validation_flow.ps1": r"""
[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$Json,
    [switch]$LeaveOpen,
    [switch]$ManualGoogleStyle
)

$leaveOpenArgument = if ($LeaveOpen) { " -LeaveOpen" } else { "" }
$leaveServerRunningArgument = if ($LeaveOpen) { " -LeaveServerRunning" } else { "" }
$manualGoogleStyleArgument = if ($ManualGoogleStyle) { " -ManualGoogleStyle" } else { "" }
$sharedSummaryArguments = ""
$sharedLaunchArguments = ""
$sharedGoogleArguments = ""
$summaryHelper = '.\\scripts\\windows\\summarize_localhost_html_pages.ps1'
$directHelper = '.\\scripts\\windows\\start_localhost_html_validation.ps1'
$stagedHelper = '.\\scripts\\windows\\start_staged_localhost_html_validation.ps1'
$googleFlowHelper = '.\\scripts\\windows\\show_google_input_validation_flow.ps1'
$googleRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$titleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1$sharedGoogleArguments"
$titleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_title_validation.ps1$sharedGoogleArguments"
$quickCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase quick"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase home"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1$sharedGoogleArguments$leaveOpenArgument"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1$sharedGoogleArguments$leaveOpenArgument"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1$sharedGoogleArguments"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase submit-timing"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase shared-enter-order"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch$manualGoogleStyleArgument$leaveOpenArgument"
$traceCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase trace$leaveOpenArgument"
$preferredInitialPageArgument = ""
if ($PreferredInitialPage) {
    $quotedPreferredInitialPage = "'saved-page.html'"
    $preferredInitialPageArgument = " -PreferredInitialPage $quotedPreferredInitialPage"
}
$manualInitialPageArgument = if ($PreferredInitialPage) {
    " -ManualInitialPage $quotedPreferredInitialPage"
} else {
    ""
}
$launchInitialPageArgument = if ($PreferredInitialPage) {
    " -InitialPage $quotedPreferredInitialPage"
} else {
    ""
}

if ($PageRoot) {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>'$sharedSummaryArguments -Port $Port$preferredInitialPageArgument"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot '<saved-page-dir>'$sharedLaunchArguments -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait$leaveServerRunningArgument"
} else {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>'$sharedSummaryArguments -Port $Port -PreferredInitialPage '<preferred-initial-page>'"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot '<saved-page-dir>'$sharedLaunchArguments -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait$leaveServerRunningArgument"
}

if ($InputPath -and $InputPath.Count -gt 0) {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -InputPath 'saved-a.html', 'saved-b.html'$sharedSummaryArguments -Port $Port$preferredInitialPageArgument"
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath 'saved-a.html', 'saved-b.html'$sharedLaunchArguments -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualInputPath 'saved-a.html', 'saved-b.html'$manualGoogleStyleArgument$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper$sharedGoogleArguments -ManualPort $Port$manualInitialPageArgument -ManualInputPath 'saved-a.html', 'saved-b.html'$manualGoogleStyleArgument$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch -ManualPort $Port$manualInitialPageArgument -ManualInputPath 'saved-a.html', 'saved-b.html'$manualGoogleStyleArgument$leaveOpenArgument"
} elseif ($ManualGoogleStyle) {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_localhost_validation.ps1$sharedGoogleArguments -Port $Port$preferredInitialPageArgument -GoogleStyle -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper$sharedGoogleArguments -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
} else {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath '<saved-html-or-folder>'$sharedLaunchArguments -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase manual -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper$sharedGoogleArguments -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'$leaveOpenArgument"
}

$flow = [ordered]@{
    issue = "Google-style saved page follow-up"
    focus = "Route saved or attached localhost HTML pages through the bounded Google headed-input gates before the manual headed pass, then expose the dedicated title flow, bounded title wrapper, fast quick pass, reduced homepage headed pass, saved homepage fixture pass, read-first submit-timing flow, bounded submit-timing pass, one-shot full pass, and live trace path when real Google still diverges."
    preferred_initial_page = $PreferredInitialPage
    manual_google_style = [bool]$ManualGoogleStyle
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{ name = "inventory"; command = $summaryCommand }
        [ordered]@{ name = "google-localhost"; command = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase localhost" }
        [ordered]@{ name = "google-title-flow"; command = $titleFlowCommand }
        [ordered]@{ name = "google-title"; command = $titleCommand }
        [ordered]@{ name = "google-quick"; command = $quickCommand }
        [ordered]@{ name = "google-home"; command = $homeCommand }
        [ordered]@{ name = "google-homepage-fixture-flow"; command = $homepageFixtureFlowCommand }
        [ordered]@{ name = "google-homepage-fixture"; command = $homepageFixtureCommand }
        [ordered]@{ name = "google-submit-timing-flow"; command = $submitTimingFlowCommand }
        [ordered]@{ name = "google-submit-timing"; command = $submitTimingCommand }
        [ordered]@{ name = "google-shared"; command = $sharedEnterOrderCommand }
        [ordered]@{ name = "google-full"; command = $fullCommand }
        [ordered]@{ name = "google-manual"; command = $manualCommand }
        [ordered]@{ name = "google-trace"; command = $traceCommand }
        [ordered]@{ name = "direct-headed"; command = $directCommand }
        [ordered]@{ name = "staged-headed"; command = $stagedCommand }
        [ordered]@{ name = "flow-map"; command = $flowMapCommand }
    )
    notes = @(
        "Use this helper when the saved or attached HTML pages look like search-box, delayed-readiness, or Enter-submit investigations related to headed Google-style behavior.",
        "Run the reduced localhost, title, quick, reduced homepage, saved homepage fixture, and bounded submit-timing phases before treating a saved-page manual pass as evidence for issue #3.",
        "Use google-title-flow when you want the dedicated title wrapper and raw probe handoff printed before you run that narrower slice.",
        "Use google-home after google-quick when you want the bounded real-surface Enter path before the saved homepage fixture, submit-timing pass, shared gates, or saved-page manual pass.",
        "Use google-homepage-fixture-flow when the next question is whether the bounded localhost copy of the captured Google homepage still matches the reduced headed flow before you widen into broader saved-page or attached-page follow-up.",
        "Use google-submit-timing-flow when you want the bounded Google-shaped keydown, keypress, and submit-ordering wrapper printed before the shared or saved-page manual follow-up.",
        "Use google-shared for the stricter Enter-order wrapper when you want the shared label-click baseline and shared submit gates ahead of the saved-page manual pass.",
        "Use google-full when you want the runner's built-in localhost-first order, quick title pass, reduced homepage pass, bounded submit-timing pass, shared Enter-order wrapper, and watch phase in one command, and keep the same saved-page manual follow-up attached when InputPath is already supplied.",
        "Use google-trace after google-manual when the saved pages behave but the real Google homepage still diverges, so the next evidence comes from the live headed path instead of another saved-page rerun.",
        "When PreferredInitialPage is set, the inventory, direct, staged, Google manual, and broader flow-map commands keep that page as the first headed target instead of falling back to a generated index or another arbitrary file.",
        "When InputPath is provided, the broader flow-map command also preserves the same manual port, initial page, and saved-page inputs for the next printed handoff.",
        "When ManualGoogleStyle is set, the Google manual, Google full, staged-headed, and broader flow-map commands auto-discover current-run attached HTML under user_files first and then agent_files, and they prefer a Google-like attached page when PreferredInitialPage is not set.",
        "When LeaveOpen is set, the printed Google manual, Google full, Google trace, direct-headed, staged-headed, and homepage-fixture commands keep the browser or localhost session open so you can inspect the same headed state after the bounded automation phases finish.",
        "The printed inventory, bounded Google, manual, trace, direct, staged, and broader flow-map commands now preserve the current repo root, browser path, host, and saved-page follow-up context where those later helpers support it.",
        "Use direct-headed when the saved pages already live in one clean directory, and staged-headed when they are spread across standalone files or folders."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-saved-page-google-flow-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class SavedPageGoogleValidationFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.flow = read_text(cls.repo_root / "scripts/windows/show_saved_page_google_validation_flow.ps1")
        cls.normalized_flow = normalized_backslashes(cls.flow)

    def test_flow_keeps_expected_saved_page_google_steps(self) -> None:
        expected_steps = (
            'name = "inventory"',
            'name = "google-localhost"',
            'name = "google-title-flow"',
            'name = "google-title"',
            'name = "google-quick"',
            'name = "google-home"',
            'name = "google-homepage-fixture-flow"',
            'name = "google-homepage-fixture"',
            'name = "google-submit-timing-flow"',
            'name = "google-submit-timing"',
            'name = "google-shared"',
            'name = "google-full"',
            'name = "google-manual"',
            'name = "google-trace"',
            'name = "direct-headed"',
            'name = "staged-headed"',
            'name = "flow-map"',
        )
        for fragment in expected_steps:
            self.assertIn(fragment, self.flow)

    def test_flow_keeps_google_phase_commands_visible(self) -> None:
        expected_commands = (
            r".\scripts\windows\show_google_title_validation_flow.ps1",
            r".\scripts\windows\run_google_title_validation.ps1",
            r".\scripts\windows\show_google_homepage_fixture_validation_flow.ps1",
            r".\scripts\windows\run_google_homepage_fixture_validation.ps1",
            r".\scripts\windows\show_google_submit_timing_validation_flow.ps1",
            r".\scripts\windows\show_google_input_validation_flow.ps1",
            r".\scripts\windows\run_google_input_validation.ps1",
            "-Phase localhost",
            "-Phase quick",
            "-Phase home",
            "-Phase submit-timing",
            "-Phase shared-enter-order",
            "-Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch",
            "-Phase trace",
        )
        for fragment in expected_commands:
            self.assertIn(fragment, self.normalized_flow)

    def test_flow_keeps_saved_page_follow_up_commands_visible(self) -> None:
        expected_fragments = (
            r".\scripts\windows\summarize_localhost_html_pages.ps1",
            r".\scripts\windows\start_localhost_html_validation.ps1",
            r".\scripts\windows\start_staged_localhost_html_validation.ps1",
            r".\scripts\windows\run_attached_html_localhost_validation.ps1",
            "-LaunchBrowser -Wait",
            "-ManualPort $Port",
            "-ManualInitialPage",
            "-ManualInputPath",
            "-ManualGoogleStyle",
            "-GoogleStyle -Wait",
            "-LeaveOpen",
            "-LeaveServerRunning",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.normalized_flow)

    def test_flow_keeps_preferred_initial_page_wiring(self) -> None:
        expected_fragments = (
            '$preferredInitialPageArgument = " -PreferredInitialPage $quotedPreferredInitialPage"',
            '$manualInitialPageArgument = if ($PreferredInitialPage)',
            '$launchInitialPageArgument = if ($PreferredInitialPage)',
            '$summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot',
            '$directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot',
            '$summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -InputPath',
            '$manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner$sharedGoogleArguments -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualInputPath',
            '$flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper$sharedGoogleArguments -ManualPort $Port$manualInitialPageArgument -ManualInputPath',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.flow)

    def test_flow_keeps_manual_google_style_branch(self) -> None:
        expected_fragments = (
            '} elseif ($ManualGoogleStyle) {',
            r'.\scripts\windows\run_attached_html_localhost_validation.ps1$sharedGoogleArguments -Port $Port$preferredInitialPageArgument -GoogleStyle -Wait$leaveServerRunningArgument',
            '-Phase manual -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument',
            '-Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument',
            'manual_google_style = [bool]$ManualGoogleStyle',
            'leave_open = [bool]$LeaveOpen',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.normalized_flow)

    def test_notes_keep_google_and_saved_page_guidance(self) -> None:
        expected_notes = (
            "saved or attached HTML pages look like search-box, delayed-readiness, or Enter-submit investigations",
            "reduced localhost, title, quick, reduced homepage, saved homepage fixture, and bounded submit-timing phases",
            "dedicated title wrapper and raw probe handoff",
            "bounded localhost copy of the captured Google homepage",
            "stricter Enter-order wrapper",
            "runner's built-in localhost-first order",
            "Use google-trace after google-manual",
            "When PreferredInitialPage is set",
            "When InputPath is provided",
            "When ManualGoogleStyle is set",
            "When LeaveOpen is set",
            "preserve the current repo root, browser path, host, and saved-page follow-up context",
            "Use direct-headed when the saved pages already live in one clean directory",
        )
        for fragment in expected_notes:
            self.assertIn(fragment, self.flow)


if __name__ == "__main__":
    unittest.main()
