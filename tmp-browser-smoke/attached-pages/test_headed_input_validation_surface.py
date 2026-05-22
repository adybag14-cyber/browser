import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_function_block(source: str, function_name: str) -> str:
    pattern = re.compile(
        rf"function\s+{re.escape(function_name)}[^\{{]*\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find function block for {function_name}")
    return match.group(0)


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$[A-Za-z_:][A-Za-z0-9_:]*\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
    )
}

Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
)

switch ($true) {
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )

        if ($ChangeArea -eq "google-input") {
            $googleInputFollowUpNotes = @(
                "Use the broader attached-page localhost flow when the next step should stay generic before the route narrows into the shorter issue #3 helpers.",
                "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
                "Use the attached-html change-area quickstart when the next step should stay on the shorter issue #3 attached-page ladder before the top-level quickstart or bundle-focused helpers.",
                "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
                "Use the compact bundle-suite helper when the replay should stay pinned to the known three-page compatibility set but you still want the bundle lane printed with the broader attached-page follow-up surfaces before bundle-first replay.",
                "Use the bundle-first helper only after the compact bundle-suite helper has made the pinned three-page route easy to reopen, or when -InputPath already fixes the bundle inputs tightly enough that the narrower bundle-only bridge is the next obvious step.",
                "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
            )
            if ($PreferredInitialPage) {
                $googleInputFollowUpNotes += "Keep the same preferred starting page pinned by rerunning this router with -PreferredInitialPage before switching to the Google-shaped attached-page helper route."
            }
            if ($SummaryPath) {
                $googleInputFollowUpNotes += "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder."
            }
            if ($isCustomBrowserExe) {
                $googleInputFollowUpNotes += "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
            }

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
        }
        break
    }
}
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
[CmdletBinding()]
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus
)
$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} elseif ($DeferredEnter) {
  "deferred-enter"
} else {
  "default-enter"
}
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe
)
$profileRoot = Join-Path $root "profile-label-click"
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
[void](Invoke-SmokeClientClick $hwnd 316 408)
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"
Write-Host "Google form-controls Enter-order validation"
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host "=== google-form-controls-enter-order-surface ==="
& $surfaceCheck @surfaceCheckArgs
Write-Host "=== google-form-controls-enter-order ==="
& $runner @arguments
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": "# placeholder\n",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": "# placeholder\n",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": "# placeholder\n",
    "scripts/windows/show_attached_html_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/show_google_attached_html_validation_flow.ps1": "# placeholder\n",
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": "# placeholder\n",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": "# placeholder\n",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-headed-input-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class HeadedInputValidationSurfaceTest(unittest.TestCase):
    FOLLOW_UP_SCRIPTS = (
        "show_attached_html_validation_flow.ps1",
        "show_google_attached_html_validation_flow.ps1",
        "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "show_google_issue3_attached_html_change_area_quickstart.ps1",
        "show_google_issue3_top_level_attached_html_quickstart.ps1",
        "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "show_google_issue3_attached_bundle_first_entrypoint.ps1",
    )

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
        cls.enter_submit_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )
        cls.label_click_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1"
        )
        cls.google_form_controls_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )

    def test_default_router_keeps_bounded_input_route(self) -> None:
        route_match = re.search(
            r'Write-Route\s+-Name\s+"input"\s+-Commands\s+@\((?P<body>.*?)\)\s+-Notes\s+@\((?P<notes>.*?)\)',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(route_match, "default router should keep the bounded input route")
        body = route_match.group("body")
        notes = route_match.group("notes")
        self.assertIn(r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1", body)
        self.assertIn(r".\tmp-browser-smoke\form-controls\label-click-probe.ps1", body)
        self.assertIn("current bounded input checks", notes)
        self.assertIn("live-site or saved-page follow-up", notes)

    def test_google_input_change_area_keeps_bounded_input_manual_google_and_follow_up_ladder(self) -> None:
        block_match = re.search(
            r'\{\s*\$ChangeArea\s+-eq\s+"input"\s+-or\s+\$ChangeArea\s+-eq\s+"google-input"\s*\}\s*\{(?P<body>.*?)break',
            self.router,
            re.DOTALL,
        )
        self.assertIsNotNone(block_match, "input/google-input change area should exist")
        body = block_match.group("body")
        self.assertIn('Write-Route -Name "bounded-input"', body)
        self.assertIn(r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1", body)
        self.assertIn(r".\tmp-browser-smoke\form-controls\label-click-probe.ps1", body)
        self.assertIn("smallest shared headed checks for typing, focus, and Enter submit", body)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', body)
        self.assertIn("Get-GoogleFormControlsEnterOrderCommands", body)
        self.assertIn('Write-Route -Name "manual-google"', body)
        self.assertIn('browse --headed `"https://www.google.com/`"', body)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', body)

    def test_google_input_notes_keep_escalation_and_rerun_pinning_guidance(self) -> None:
        for fragment in (
            "broader attached-page localhost flow",
            "dedicated Google-shaped attached-page flow",
            "attached-html change-area quickstart",
            "top-level attached-page quickstart",
            "compact bundle-suite helper",
            "bundle-first helper",
            "validation-router attached-html surface checker",
            "Keep the same preferred starting page pinned by rerunning this router with -PreferredInitialPage",
            "Keep the same saved summary pinned by rerunning this router with -SummaryPath",
            "Keep the same non-default binary pinned by rerunning this router with -BrowserExe",
        ):
            self.assertIn(fragment, self.router)

    def test_google_input_follow_up_ladder_keeps_expected_helper_scripts(self) -> None:
        for script_name in self.FOLLOW_UP_SCRIPTS:
            self.assertIn(script_name, self.router)
        for relative_path in (
            "scripts/windows/show_attached_html_validation_flow.ps1",
            "scripts/windows/show_google_attached_html_validation_flow.ps1",
            "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1",
            "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1",
            "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")

    def test_enter_submit_probe_keeps_specialized_modes_and_explicit_headed_launch(self) -> None:
        for fragment in ("$DeferredEnter", "$GoogleEnterOrder", "$ClickFocus", '"google-enter-order"', '"deferred-enter"'):
            self.assertIn(fragment, self.enter_submit_probe)
        assert_explicit_headed_launch(self, self.enter_submit_probe, "enter-submit probe")
        self.assertIn('"--window_width"', self.enter_submit_probe)
        self.assertIn('"--window_height"', self.enter_submit_probe)
        self.assertIn('"--screenshot_png"', self.enter_submit_probe)

    def test_label_click_probe_keeps_explicit_headed_launch_and_click_flow(self) -> None:
        assert_explicit_headed_launch(self, self.label_click_probe, "label-click probe")
        self.assertIn("profile-label-click", self.label_click_probe)
        self.assertIn("Invoke-SmokeClientClick", self.label_click_probe)
        self.assertIn('"--screenshot_png"', self.label_click_probe)

    def test_google_form_controls_runner_keeps_surface_check_and_probe_handoff(self) -> None:
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", self.google_form_controls_runner)
        self.assertIn(r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1", self.google_form_controls_runner)
        self.assertIn("google-form-controls-enter-order-surface", self.google_form_controls_runner)
        self.assertIn("google-form-controls-enter-order", self.google_form_controls_runner)
        self.assertIn("Shared Enter-order port", self.google_form_controls_runner)


if __name__ == "__main__":
    unittest.main()
