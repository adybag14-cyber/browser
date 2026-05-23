from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1": r"""
$guidePath = 'docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md'
$surfaceCheckScript = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$flowScript = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$wrapperScript = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbeScript = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'

$guide = [ordered]@{
    issue = 'Google form-controls Enter-order trace guide'
    purpose = 'Translate the dedicated shared Google-style Enter-order probe markers and JSON fields into click-focus, typed-text, held-keydown, keypress, and submit stages before widening issue #3 validation again.'
    guide_path = $guidePath
    surface_check_command = "powershell -ExecutionPolicy Bypass -File $surfaceCheckScript"
    flow_command = "powershell -ExecutionPolicy Bypass -File $flowScript"
    wrapper_command = "powershell -ExecutionPolicy Bypass -File $wrapperScript"
    raw_probe_command = "powershell -ExecutionPolicy Bypass -File $rawProbeScript"
    quick_diagnosis = @(
        'No title_after_click or no FOCUS marker means the headed click-focus path is still broken before typing starts.',
        'title_after_click plus no title_after_type means Enter-order is not the first failure; typed text never became visible after focus.',
        'keydown_held_without_submit = false means the page already submitted or navigated during held Enter keydown, before the later Enter phase settled.',
        'submit_record missing means the server-side proof never arrived, so do not treat a title-only transition as a green shared gate.',
        'submit_phase = keydown means the page still submitted too early, before keypress reached the form.',
        'An event_log with KD:Enter but no KP:Enter means the Enter keydown arrived but keypress still did not reach the page.',
        'KP:Enter plus no SUBMIT marker means keypress arrived but the form did not transition into submit.',
        'submit_phase = keypress with submit_after_keydown = true and submit_after_keypress = true is the exact green end-state for the dedicated gate.'
    )
    next_step = 'Run the dedicated surface checker first, print this guide or the full flow helper when needed, rerun the dedicated wrapper, and keep the JSON fields for issue notes before moving back to the wider shared Enter-order ladder or live Google follow-up.'
}
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the dedicated shared form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the dedicated form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1" -Kind "file" -Purpose "Quick diagnosis helper for interpreting the dedicated Enter-order probe markers."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated form-controls Enter-order runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable shared click-first fallback probe that the dedicated Enter-order flow helper prints with -GoogleEnterOrder -ClickFocus."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."),
""",
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$surfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$runner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$broaderStack = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'

$flow = [ordered]@{
    notes = @(
        "Use the trace guide when you need a quick read on whether the failure stayed before focus, before typed text became visible, or before keypress reached submit.",
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated gate before widening back to the broader shared Enter-order ladder."
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0}" -f $traceGuide),
        ("Use powershell -ExecutionPolicy Bypass -File {0} -GoogleEnterOrder -ClickFocus" -f $sharedClickFocusProbe),
        ("Use powershell -ExecutionPolicy Bypass -File {0}" -f $runner),
        ("Use powershell -ExecutionPolicy Bypass -File {0}" -f $broaderStack)
    )
}
""",
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
Write-Host "=== google-form-controls-enter-order-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)

Write-Host "=== google-form-controls-enter-order ==="
Write-Host ("Script: {0}" -f $runner)
""",
    "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1": r"""
$focusTitleNeedle = "Google Enter Focused"
$typedTitleNeedle = "Google Enter VALUE:$InputText"
$submittedTitleNeedle = "Submitted $InputText"

$keydownHeldWithoutSubmit = ($titleAfterKeyDown -notlike "$submittedTitleNeedle*") -and ($null -eq $submitRecordAfterKeyDown)
if ($submitPhase -ne "keypress") { throw "expected submit phase keypress, got '$submitPhase'" }
if ($eventLog -notlike "*KP:Enter:$InputText*" -or $eventLog -notlike "*SUBMIT:$InputText*") {
  throw "google enter-order probe did not capture the expected Enter event trail"
}
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} else {
  "default-enter"
}

$googleServerPattern = if ($probeMode -eq "google-enter-order") {
  "GOOGLE_ENTER_SUBMIT q=$([regex]::Escape($InputText)) phase=([^ ]*) active_name=([^ ]*) active_id=([^ ]*) selection=([^ ]*) events=(.*)"
} else {
  $null
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-form-controls-trace-guide-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleFormControlsEnterOrderTraceGuideSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.trace_guide = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.wrapper = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.raw_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1"
        )
        cls.shared_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )

    def test_trace_guide_keeps_core_commands_and_identity(self) -> None:
        for fragment in (
            "Google form-controls Enter-order trace guide",
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            r".\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            r".\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1",
            "Translate the dedicated shared Google-style Enter-order probe markers",
        ):
            self.assertIn(fragment, self.trace_guide)

    def test_trace_guide_keeps_quick_diagnosis_markers(self) -> None:
        for fragment in (
            "No title_after_click or no FOCUS marker",
            "title_after_click plus no title_after_type",
            "keydown_held_without_submit = false",
            "submit_record missing",
            "submit_phase = keydown",
            "KD:Enter but no KP:Enter",
            "KP:Enter plus no SUBMIT marker",
            "submit_phase = keypress with submit_after_keydown = true and submit_after_keypress = true",
        ):
            self.assertIn(fragment, self.trace_guide)

    def test_surface_check_keeps_trace_guide_and_probe_dependencies_visible(self) -> None:
        for fragment in (
            'docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md',
            'scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1',
            'scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1',
            'scripts/windows/run_google_form_controls_enter_order_validation.ps1',
            'tmp-browser-smoke/form-controls/enter-submit-probe.ps1',
            'tmp-browser-smoke/form-controls/google-enter-order-probe.ps1',
        ):
            self.assertIn(fragment, self.surface_check)

    def test_flow_still_routes_into_trace_guide_and_click_focus_fallback(self) -> None:
        for fragment in (
            r"$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'",
            r"$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'",
            "before focus, before typed text became visible, or before keypress reached submit",
            "compare the reusable Google-shaped page against the dedicated gate",
            "-GoogleEnterOrder -ClickFocus",
            "show_google_shared_enter_order_validation_flow.ps1",
        ):
            self.assertIn(fragment, self.flow)

    def test_wrapper_keeps_surface_check_then_probe_order(self) -> None:
        for fragment in (
            "=== google-form-controls-enter-order-surface ===",
            "=== google-form-controls-enter-order ===",
            "Script: {0}",
        ):
            self.assertIn(fragment, self.wrapper)

    def test_raw_probe_and_shared_probe_keep_keypress_submit_contract(self) -> None:
        for fragment in (
            'Google Enter Focused',
            'Google Enter VALUE:$InputText',
            'Submitted $InputText',
            'expected submit phase keypress',
            '*KP:Enter:$InputText*',
            '*SUBMIT:$InputText*',
        ):
            self.assertIn(fragment, self.raw_probe)

        for fragment in (
            'ClickFocus currently supports only -GoogleEnterOrder.',
            '"google-enter-order"',
            'GOOGLE_ENTER_SUBMIT q=$([regex]::Escape($InputText))',
        ):
            self.assertIn(fragment, self.shared_probe)


if __name__ == "__main__":
    unittest.main()
