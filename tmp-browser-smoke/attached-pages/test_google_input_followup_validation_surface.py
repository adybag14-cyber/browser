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


def extract_named_route_block(source: str, route_name: str) -> str:
    pattern = re.compile(
        rf'Write-Route\s+-Name\s+"{re.escape(route_name)}"\s+-Commands\s+@\((?P<body>(?:.|\n)*?)\)\s+-Notes',
        re.MULTILINE,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find route block for {route_name}")
    return match.group("body")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$(?:(?:script:)?BrowserExe|browserExe)\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_form_controls_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_form_controls_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
    )
}

Write-Route -Name "input" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
) -Notes @(
    "These are the current bounded input checks already committed on this branch.",
    "Use them before live-site or saved-page follow-up."
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
) -Notes @(
    "Use the broader attached-page localhost flow when the next step should stay generic before the route narrows into the shorter issue #3 helpers.",
    "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
)

Write-Route -Name "google-recommended" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
    "& `"$BrowserExe`" browse --headed `"https://www.google.com/`"",
    (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
    (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
    (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
) -Notes @(
    "Use the bounded input probe first, then the dedicated Google form-controls Enter-order gate, then live Google, then the broader attached-page localhost flow and dedicated Google-shaped attached-page flow before the shorter issue #3 helper surface, the compact bundle-suite helper, or bundle-first replay.",
    "Run the validation-router attached-html surface checker before trusting the shorter issue #3 helper ladder so missing quickstart notes or downstream helper paths fail fast."
)
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} elseif ($DeferredEnter) {
  "deferred-enter"
} else {
  "default-enter"
}

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
$googleSubmitPhase = $null
$googleEventLog = $null
""",
    "tmp-browser-smoke/form-controls/label-click-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
$titleAfterClick = "Label Smoke true"
""",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": r"""
$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "440", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl)
$submitPhase = "keypress"
$keydownHeldWithoutSubmit = $true
$eventLog = "FOCUS;BI:Q:1;IN:Q;KD:Enter:Q;KP:Enter:Q;SUBMIT:Q"
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
$references = @(
    "scripts/windows/show_headed_validation_suites.ps1",
    "scripts/windows/show_google_input_validation_flow.ps1",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
    "scripts/windows/run_form_controls_validation.ps1",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1"
)
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"
& $surfaceCheck @surfaceCheckArgs
& $runner @arguments
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-input-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleInputFollowUpValidationSurfaceTest(unittest.TestCase):
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
        cls.enter_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1")
        cls.label_probe = read_text(cls.repo_root / "tmp-browser-smoke/form-controls/label-click-probe.ps1")
        cls.google_enter_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )

    def test_default_input_route_keeps_enter_and_label_probes(self) -> None:
        commands_block = extract_named_route_block(self.router, "input")
        self.assertIn(r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1", commands_block)
        self.assertIn(r"tmp-browser-smoke\form-controls\label-click-probe.ps1", commands_block)

    def test_google_input_change_area_keeps_bounded_manual_and_issue3_routes(self) -> None:
        bounded_block = extract_named_route_block(self.router, "bounded-input")
        self.assertIn(r"tmp-browser-smoke\form-controls\enter-submit-probe.ps1", bounded_block)
        self.assertIn(r"tmp-browser-smoke\form-controls\label-click-probe.ps1", bounded_block)

        form_controls_route = re.search(
            r'Write-Route\s+-Name\s+"google-form-controls-enter-order"\s+-Commands\s+\(Get-GoogleFormControlsEnterOrderCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            form_controls_route,
            "google-input change area should surface the dedicated form-controls Enter-order route",
        )

        manual_google = extract_named_route_block(self.router, "manual-google")
        self.assertIn('browse --headed `"https://www.google.com/`"', manual_google)

        issue3_follow_up = extract_named_route_block(self.router, "issue3-attached-html-follow-up")
        self.assertIn("show_attached_html_validation_flow.ps1", issue3_follow_up)
        self.assertIn("show_google_attached_html_validation_flow.ps1", issue3_follow_up)
        self.assertIn("check_google_issue3_validation_router_attached_html_quickstart_surface.ps1", issue3_follow_up)
        self.assertIn("show_google_issue3_attached_html_change_area_quickstart.ps1", issue3_follow_up)
        self.assertIn("show_google_issue3_top_level_attached_html_quickstart.ps1", issue3_follow_up)
        self.assertIn("show_google_issue3_attached_html_target_bundle_suite_surface.ps1", issue3_follow_up)
        self.assertIn("show_google_issue3_attached_bundle_first_entrypoint.ps1", issue3_follow_up)

    def test_google_recommended_route_keeps_full_google_ladder(self) -> None:
        commands_block = extract_named_route_block(self.router, "google-recommended")
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea input", commands_block)
        self.assertIn(r"show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order", commands_block)
        self.assertIn('browse --headed `"https://www.google.com/`"', commands_block)
        self.assertIn("show_attached_html_validation_flow.ps1", commands_block)
        self.assertIn("show_google_attached_html_validation_flow.ps1", commands_block)
        self.assertIn("check_google_issue3_validation_router_attached_html_quickstart_surface.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_html_change_area_quickstart.ps1", commands_block)
        self.assertIn("show_google_issue3_top_level_attached_html_quickstart.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_html_target_bundle_suite_surface.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_bundle_first_entrypoint.ps1", commands_block)

    def test_google_recommended_notes_keep_order_and_validation_router_guidance(self) -> None:
        notes_match = re.search(
            r'Write-Route\s+-Name\s+"google-recommended"\s+-Commands\s+@\((?:.|\n)*?\)\s+-Notes\s+@\((?P<notes>(?:.|\n)*?)\)',
            self.router,
            re.MULTILINE,
        )
        self.assertIsNotNone(notes_match, "google-recommended notes should be present")
        notes = notes_match.group("notes")
        self.assertIn("bounded input probe first", notes)
        self.assertIn("dedicated Google form-controls Enter-order gate", notes)
        self.assertIn("live Google", notes)
        self.assertIn("validation-router attached-html surface checker", notes)

    def test_form_controls_probes_keep_explicit_headed_launches(self) -> None:
        assert_explicit_headed_launch(self, self.enter_probe, "shared enter-submit probe")
        assert_explicit_headed_launch(self, self.label_probe, "label-click probe")
        assert_explicit_headed_launch(self, self.google_enter_probe, "google enter-order probe")
        self.assertIn('"--screenshot_png"', self.enter_probe)
        self.assertIn('"--screenshot_png"', self.label_probe)
        self.assertIn('"--screenshot_png"', self.google_enter_probe)

    def test_form_controls_probes_keep_google_enter_order_markers(self) -> None:
        self.assertIn('"google-enter-order"', self.enter_probe)
        self.assertIn("ClickFocus currently supports only -GoogleEnterOrder", self.enter_probe)
        self.assertIn("$googleSubmitPhase", self.enter_probe)
        self.assertIn("$googleEventLog", self.enter_probe)
        self.assertIn("$submitPhase = \"keypress\"", self.google_enter_probe)
        self.assertIn("$keydownHeldWithoutSubmit = $true", self.google_enter_probe)
        self.assertIn("KP:Enter:Q", self.google_enter_probe)
        self.assertIn("SUBMIT:Q", self.google_enter_probe)

    def test_dedicated_surface_checker_and_runner_keep_google_enter_order_dependencies(self) -> None:
        self.assertIn("show_headed_validation_suites.ps1", self.surface_check)
        self.assertIn("show_google_input_validation_flow.ps1", self.surface_check)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", self.surface_check)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", self.surface_check)
        self.assertIn("run_google_form_controls_enter_order_validation.ps1", self.surface_check)
        self.assertIn("tmp-browser-smoke/form-controls/enter-submit-probe.ps1", self.surface_check)
        self.assertIn("tmp-browser-smoke/form-controls/google-enter-order-probe.ps1", self.surface_check)

        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", self.runner)
        self.assertIn(r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1", self.runner)
        self.assertIn("& $surfaceCheck", self.runner)
        self.assertIn("& $runner", self.runner)


if __name__ == "__main__":
    unittest.main()
