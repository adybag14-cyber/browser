import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
switch ($true) {
    { $SuiteName -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
        break
    }
    { $SuiteName -eq "google-shared-enter-order" } {
        Write-Section "google-shared-enter-order"
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these when the shared Enter-order ladder is already narrowed and you want the last shared form-controls keypress-before-submit gate isolated again."
        )
        break
    }
    { $SuiteName -eq "google-recommended" } {
        Write-Section "google-recommended"
        Write-Route -Name "google-recommended" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        ) -Notes @(
            "Use the shared Enter-submit probe first, then the dedicated Google form-controls Enter-order gate, then verify Google homepage typing, focus retention, and Enter submit manually."
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
            "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
            "Use the attached-html change-area quickstart when the next step should stay on the shorter issue #3 attached-page ladder before the top-level quickstart or bundle-focused helpers.",
            "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
            "Use the compact bundle-suite helper when the replay should stay pinned to the known three-page compatibility set but you still want the bundle lane printed with the broader attached-page follow-up surfaces before bundle-first replay.",
            "Use the bundle-first helper only after the compact bundle-suite helper has made the pinned three-page route easy to reopen, or when -InputPath already fixes the bundle inputs tightly enough that the narrower bundle-only bridge is the next obvious step.",
            "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder.",
            "Keep the same preferred starting page pinned by rerunning this router with -PreferredInitialPage before switching to the Google-shaped attached-page helper route.",
            "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder.",
            "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
        )
        break
    }
}
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "raw-probe"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1" }
        [ordered]@{ name = "broader-stack"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1" }
    )
}
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
$flow = [ordered]@{
    steps = @(
        [ordered]@{ name = "surface-check"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1" }
        [ordered]@{ name = "recommended"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1" }
        [ordered]@{ name = "shared-only"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared" }
        [ordered]@{ name = "google-title-localhost"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1" }
        [ordered]@{ name = "reduced-home-keypress"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1" }
        [ordered]@{ name = "localhost-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1" }
        [ordered]@{ name = "shared-click-focus-fallback"; command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus" }
        [ordered]@{ name = "form-controls-flow"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1" }
        [ordered]@{ name = "form-controls-enter-order"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1" }
        [ordered]@{ name = "form-controls-trace-guide"; command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1" }
    )
    notes = @(
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated form-controls gate before widening back to the broader shared Enter-order ladder."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-recommended-enter-order-suite-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleRecommendedEnterOrderSuiteSurfaceTest(unittest.TestCase):
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
        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )

    def test_form_controls_suite_keeps_shared_follow_up_route(self) -> None:
        self.assertIn('{ $SuiteName -eq "google-form-controls-enter-order" }', self.router)
        self.assertIn('Write-Section "google-form-controls-enter-order"', self.router)
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up"', self.router)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", self.router)
        self.assertIn("run_google_shared_enter_order_validation.ps1", self.router)
        self.assertIn("broader shared Enter-order ladder back on one surface", self.router)

    def test_shared_suite_keeps_dedicated_form_controls_follow_up(self) -> None:
        self.assertIn('{ $SuiteName -eq "google-shared-enter-order" }', self.router)
        self.assertIn('Write-Section "google-shared-enter-order"', self.router)
        self.assertIn('Write-Route -Name "dedicated-form-controls-follow-up"', self.router)
        self.assertIn("Get-GoogleFormControlsEnterOrderCommands", self.router)
        self.assertIn("last shared form-controls keypress-before-submit gate", self.router)

    def test_google_recommended_suite_keeps_manual_google_and_issue3_ladder(self) -> None:
        self.assertIn('{ $SuiteName -eq "google-recommended" }', self.router)
        self.assertIn('Write-Section "google-recommended"', self.router)
        self.assertIn(r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1', self.router)
        self.assertIn(r'.\scripts\windows\run_google_form_controls_enter_order_validation.ps1', self.router)
        self.assertIn('browse --headed `"https://www.google.com/`"', self.router)

        expected_helpers = (
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        )
        for helper in expected_helpers:
            self.assertIn(helper, self.router)

    def test_google_recommended_suite_keeps_bundle_and_pinning_notes(self) -> None:
        expected_fragments = (
            "shared Enter-submit probe first",
            "dedicated Google form-controls Enter-order gate",
            "broader attached-page localhost flow",
            "dedicated Google-shaped attached-page flow",
            "compact bundle-suite helper",
            "bundle-first helper",
            "validation-router attached-html surface checker",
            "-PreferredInitialPage",
            "-SummaryPath",
            "-BrowserExe",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.router)

    def test_form_controls_flow_keeps_trace_raw_probe_and_broader_stack(self) -> None:
        for step_name in (
            "surface-check",
            "trace-guide",
            "shared-click-focus-fallback",
            "recommended",
            "raw-probe",
            "broader-stack",
        ):
            self.assertIn(f'name = "{step_name}"', self.form_controls_flow)

        self.assertIn(
            r'.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus',
            self.form_controls_flow,
        )
        self.assertIn(r'.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1', self.form_controls_flow)
        self.assertIn(r'.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1', self.form_controls_flow)

    def test_shared_flow_keeps_localhost_and_form_controls_handoffs(self) -> None:
        for step_name in (
            "surface-check",
            "recommended",
            "shared-only",
            "google-title-localhost",
            "reduced-home-keypress",
            "localhost-enter-order",
            "shared-click-focus-fallback",
            "form-controls-flow",
            "form-controls-enter-order",
            "form-controls-trace-guide",
        ):
            self.assertIn(f'name = "{step_name}"', self.shared_flow)

        self.assertIn(
            r'.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1',
            self.shared_flow,
        )
        self.assertIn(
            r'.\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1',
            self.shared_flow,
        )
        self.assertIn(
            r'.\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1',
            self.shared_flow,
        )
        self.assertIn(
            r'.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1',
            self.shared_flow,
        )
        self.assertIn("dedicated form-controls gate", self.shared_flow)


if __name__ == "__main__":
    unittest.main()
