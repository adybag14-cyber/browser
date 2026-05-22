import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized_backslashes(source: str) -> str:
    return source.replace("\\\\", "\\")


FIXTURE_FILES = {
    "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1": r"""
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$sharedClickFocusArgs = @('-GoogleEnterOrder', '-ClickFocus')
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
""",
    "scripts/windows/show_google_shared_enter_order_validation_flow.ps1": r"""
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$sharedClickFocusArgs = @('-GoogleEnterOrder', '-ClickFocus')
$formControlsFlow = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
(New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable shared click-first fallback probe that the dedicated Enter-order flow helper prints with -GoogleEnterOrder -ClickFocus."),
""",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1": r"""
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus
)

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} elseif ($DeferredEnter) {
  "deferred-enter"
} else {
  "default-enter"
}

$focusTitleNeedle = if ($probeMode -eq "google-enter-order") { "Google Enter Focused" } else { $null }
$googleServerPattern = if ($probeMode -eq "google-enter-order") {
  "GOOGLE_ENTER_SUBMIT q=$([regex]::Escape($InputText)) phase=([^ ]*) active_name=([^ ]*) active_id=([^ ]*) selection=([^ ]*) events=(.*)"
} else {
  $null
}

if ($focusTitleNeedle) {
  if ($ClickFocus) {
    [void](Invoke-SmokeClientClick -Hwnd $hwnd -X 170 -Y 82)
  } else {
    Send-SmokeTab
  }
}

if ($probeMode -eq "google-enter-order") {
  if ($googleSubmitPhase -eq "keydown") {
    throw "google enter-order probe observed submit at keydown instead of after keypress"
  }
  if ($googleEventLog -notlike "*KP:Enter:$InputText*" -or $googleEventLog -notlike "*SUBMIT:$InputText*") {
    throw "google enter-order probe did not capture the expected Enter event trail"
  }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-click-focus-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderClickFocusSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.form_controls_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1"
        )
        cls.shared_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_shared_enter_order_validation_flow.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.enter_submit_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/form-controls/enter-submit-probe.ps1"
        )

    def test_form_controls_flow_keeps_click_focus_probe_reference(self) -> None:
        normalized = normalized_backslashes(self.form_controls_flow)
        self.assertIn(r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1", normalized)
        self.assertIn("-GoogleEnterOrder", normalized)
        self.assertIn("-ClickFocus", normalized)
        self.assertIn("show_google_form_controls_enter_order_trace_guide.ps1", normalized)

    def test_shared_flow_keeps_click_focus_probe_reference(self) -> None:
        normalized = normalized_backslashes(self.shared_flow)
        self.assertIn(r".\tmp-browser-smoke\form-controls\enter-submit-probe.ps1", normalized)
        self.assertIn("-GoogleEnterOrder", normalized)
        self.assertIn("-ClickFocus", normalized)
        self.assertIn("show_google_form_controls_enter_order_validation_flow.ps1", normalized)

    def test_surface_check_keeps_click_focus_probe_dependency_visible(self) -> None:
        self.assertIn("tmp-browser-smoke/form-controls/enter-submit-probe.ps1", self.surface_check)
        self.assertIn("click-first fallback probe", self.surface_check)
        self.assertIn("-GoogleEnterOrder -ClickFocus", self.surface_check)

    def test_probe_keeps_click_focus_guard_and_google_mode_switch(self) -> None:
        self.assertIn("[switch]$GoogleEnterOrder", self.enter_submit_probe)
        self.assertIn("[switch]$ClickFocus", self.enter_submit_probe)
        self.assertIn("ClickFocus currently supports only -GoogleEnterOrder.", self.enter_submit_probe)
        self.assertIn('"google-enter-order"', self.enter_submit_probe)
        self.assertIn('"Google Enter Focused"', self.enter_submit_probe)

    def test_probe_keeps_click_first_focus_branch(self) -> None:
        self.assertRegex(
            self.enter_submit_probe,
            r"if\s+\(\$ClickFocus\)\s*\{\s*\[void\]\(Invoke-SmokeClientClick",
        )
        self.assertIn("Send-SmokeTab", self.enter_submit_probe)

    def test_probe_keeps_google_submit_telemetry_checks(self) -> None:
        self.assertIn("GOOGLE_ENTER_SUBMIT", self.enter_submit_probe)
        self.assertIn("submit at keydown instead of after keypress", self.enter_submit_probe)
        self.assertIn("KP:Enter:$InputText", self.enter_submit_probe)
        self.assertIn("SUBMIT:$InputText", self.enter_submit_probe)


if __name__ == "__main__":
    unittest.main()
