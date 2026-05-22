import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$browser\w*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
)

$googleInputFollowUpNotes = @(
    "Use the broader attached-page localhost flow when the next step should stay generic before the route narrows into the shorter issue #3 helpers.",
    "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
    "Use the attached-html change-area quickstart when the next step should stay on the shorter issue #3 attached-page ladder before the top-level quickstart or bundle-focused helpers.",
    "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
    "Use the compact bundle-suite helper when the replay should stay pinned to the known three-page compatibility set but you still want the bundle lane printed with the broader attached-page follow-up surfaces before bundle-first replay.",
    "Use the bundle-first helper only after the compact bundle-suite helper has made the pinned three-page route easy to reopen, or when -InputPath already fixes the bundle inputs tightly enough that the narrower bundle-only bridge is the next obvious step.",
    "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
)

Write-Route -Name "bounded-input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
)

Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
    "Use this after the shared input probes are green when the next question is whether submit still waits until keypress on the Google-style form-controls path."
)

Write-Route -Name "manual-google" -Commands @(
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
) -Notes @(
    "Use this after the bounded input probes are green."
)

Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
    (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
) -Notes $googleInputFollowUpNotes
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
[CmdletBinding()]
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus,
  [string]$RepoRoot,
  [string]$BrowserExe
)

if ($DeferredEnter -and $GoogleEnterOrder) {
  throw "Choose at most one specialized enter-submit mode."
}

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$typedTitleNeedle = switch ($probeMode) {
  "google-enter-order" { "Google Enter VALUE:$InputText" }
  default { "Enter Submit $InputText" }
}
$serverSubmitPattern = switch ($probeMode) {
  "google-enter-order" { "FORM_SUBMIT /submitted\.html\?submit_phase=.*\bq=$([regex]::Escape($InputText))" }
  default { "FORM_SUBMIT /submitted\.html\?name=$([regex]::Escape($InputText))" }
}
$googleServerPattern = if ($probeMode -eq "google-enter-order") {
  "GOOGLE_ENTER_SUBMIT q=$([regex]::Escape($InputText)) phase=([^ ]*) active_name=([^ ]*) active_id=([^ ]*) selection=([^ ]*) events=(.*)"
} else {
  $null
}
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
Send-SmokeText $InputText
Send-SmokeEnter
if ($probeMode -eq "google-enter-order") {
  if ($googleSubmitPhase -eq "keydown") {
    throw "google enter-order probe observed submit at keydown instead of after keypress"
  }
  if ($googleSubmitPhase -ne "keypress") {
    throw "google enter-order probe observed submit phase '$googleSubmitPhase' instead of keypress"
  }
  if ($googleEventLog -notlike "*KP:Enter:$InputText*" -or $googleEventLog -notlike "*SUBMIT:$InputText*") {
    throw "google enter-order probe did not capture the expected Enter event trail"
  }
}
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe
)

$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
[void](Invoke-SmokeClientClick $hwnd 316 408)
$titleAfterClick = Wait-ForTitleLike $hwnd "Label Smoke true*" $TitleWaitAttempts $PollMilliseconds
if (-not $titleAfterClick) {
  throw "label click did not toggle the checkbox"
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-validation-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")
        cls.enter_submit_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")
        cls.label_click_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1")

    def test_default_input_route_keeps_bounded_form_control_probes(self) -> None:
        self.assertIn('Write-Route -Name "input" -Commands @(', self.router)
        self.assertIn(r'tmp-browser-smoke\form-controls\enter-submit-probe.ps1', self.router)
        self.assertIn(r'tmp-browser-smoke\form-controls\label-click-probe.ps1', self.router)
        self.assertIn("current bounded input checks", self.router)
        self.assertIn("before live-site or saved-page follow-up", self.router)

    def test_google_input_change_area_keeps_manual_google_and_issue3_follow_up(self) -> None:
        self.assertIn('Write-Route -Name "bounded-input" -Commands @(', self.router)
        self.assertIn("smallest shared headed checks for typing, focus, and Enter submit", self.router)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', self.router)
        self.assertIn("shared input probes are green", self.router)
        self.assertIn('Write-Route -Name "manual-google"', self.router)
        self.assertIn('browse --headed `"https://www.google.com/`"', self.router)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', self.router)

    def test_google_input_follow_up_keeps_broader_attached_page_ladder(self) -> None:
        expected_fragments = [
            "broader attached-page localhost flow",
            "dedicated Google-shaped attached-page flow",
            "attached-html change-area quickstart",
            "top-level attached-page quickstart",
            "compact bundle-suite helper",
            "bundle-first helper",
            "validation-router attached-html surface checker",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ]
        for fragment in expected_fragments:
            self.assertIn(fragment, self.router)

    def test_enter_submit_probe_keeps_explicit_headed_launch(self) -> None:
        assert_explicit_headed_launch(self, self.enter_submit_probe, "enter-submit probe")
        self.assertIn("[switch]$DeferredEnter", self.enter_submit_probe)
        self.assertIn("[switch]$GoogleEnterOrder", self.enter_submit_probe)
        self.assertIn("[switch]$ClickFocus", self.enter_submit_probe)
        self.assertIn('"--screenshot_png"', self.enter_submit_probe)
        self.assertIn("Send-SmokeText $InputText", self.enter_submit_probe)
        self.assertIn("Send-SmokeEnter", self.enter_submit_probe)

    def test_enter_submit_probe_keeps_google_keypress_submit_telemetry(self) -> None:
        self.assertIn("GOOGLE_ENTER_SUBMIT", self.enter_submit_probe)
        self.assertIn("submit at keydown instead of after keypress", self.enter_submit_probe)
        self.assertIn("submit phase '$googleSubmitPhase' instead of keypress", self.enter_submit_probe)
        self.assertIn("*KP:Enter:$InputText*", self.enter_submit_probe)
        self.assertIn("*SUBMIT:$InputText*", self.enter_submit_probe)

    def test_label_click_probe_keeps_explicit_headed_launch_and_click_assertion(self) -> None:
        assert_explicit_headed_launch(self, self.label_click_probe, "label-click probe")
        self.assertIn("Invoke-SmokeClientClick", self.label_click_probe)
        self.assertIn('Wait-ForTitleLike $hwnd "Label Smoke true*"', self.label_click_probe)
        self.assertIn("label click did not toggle the checkbox", self.label_click_probe)


if __name__ == "__main__":
    unittest.main()
