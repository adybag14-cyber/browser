import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized_backslashes(source: str) -> str:
    return source.replace("\\\\", "\\")


FIXTURE_FILES = {
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the dedicated shared form-controls Enter-order gate."),
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Broader shared Enter-order note that widens out from the dedicated gate."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the dedicated form-controls Enter-order helpers."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the dedicated form-controls Enter-order gate discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Main issue #3 flow helper that should still point at the dedicated form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Broader shared Enter-order flow helper that should still widen into the dedicated gate."),
    (New-ValidationReference -Path "scripts/windows/run_form_controls_validation.ps1" -Kind "file" -Purpose "Shared form-controls runner that should still expose the dedicated google-enter-order probe slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the dedicated form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1" -Kind "file" -Purpose "Quick diagnosis helper for interpreting the dedicated Enter-order probe markers."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated form-controls Enter-order runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/form_server.py" -Kind "file" -Purpose "Shared localhost form-controls server that the dedicated Enter-order probe boots before replay."),
    (New-ValidationReference -Path "tmp-browser-smoke/common/Win32Input.ps1" -Kind "file" -Purpose "Shared Win32 input helper used by the dedicated Enter-order probe for click and text delivery."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared tab-window helper used by the dedicated Enter-order probe for profile setup, window discovery, and owned-process cleanup."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable shared click-first fallback probe that the dedicated Enter-order flow helper prints with -GoogleEnterOrder -ClickFocus."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1" -Kind "file" -Purpose "Compatibility wrapper that keeps older chrome-prefixed probe entry points valid while they still appear in notes or prior issue handoffs."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Shared form-controls suite note for the dedicated Enter-order gate.")
)
""",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the shared Enter-order ladder."),
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the final shared form-controls gate."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the shared Enter-order helpers."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared headed validation suite router that should keep the google-shared-enter-order slice reachable from the broader catalog."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the shared Enter-order slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "One-command shared Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated fail-fast checker for the final shared form-controls gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the final shared form-controls gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared baseline runner used before the stricter Enter-order probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Reduced localhost Google title probe used before the Enter-order wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Localhost Enter-order wrapper used before broader replay."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable click-first shared probe that mirrors the Google-shaped Enter path before the dedicated form-controls gate."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Shared form-controls suite note for the final bounded gate.")
)
""",
    "scripts/windows/show_headed_validation_suites.ps1": r"""
Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
""",
    "scripts/windows/show_google_input_validation_flow.ps1": r"""
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase shared-enter-order"
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-enter-surface-checkers-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderSurfaceCheckersTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.form_controls_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.shared_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_shared_enter_order_validation_surface.ps1"
        )
        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")
        cls.google_input_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_input_validation_flow.ps1"
        )

    def test_form_controls_surface_checker_keeps_dedicated_gate_dependencies(self) -> None:
        for expected in (
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_input_validation_flow.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/run_form_controls_validation.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "tmp-browser-smoke/form-controls/form_server.py",
            "tmp-browser-smoke/common/Win32Input.ps1",
            "tmp-browser-smoke/tabs/TabProbeCommon.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/README.md",
        ):
            self.assertIn(expected, self.form_controls_surface)

    def test_shared_surface_checker_keeps_shared_and_final_gate_dependencies(self) -> None:
        for expected in (
            "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md",
            "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md",
            "docs/WINDOWS_FULL_USE.md",
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/show_google_shared_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_shared_enter_order_validation.ps1",
            "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1",
            "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1",
            "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/README.md",
        ):
            self.assertIn(expected, self.shared_surface)

    def test_router_keeps_both_enter_order_routes_discoverable(self) -> None:
        self.assertIn(
            'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            self.router,
        )
        self.assertIn(
            'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)',
            self.router,
        )

    def test_google_input_flow_keeps_dedicated_surface_checker_and_shared_handoff(self) -> None:
        normalized = normalized_backslashes(self.google_input_flow)
        for expected in (
            r".\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
            r".\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
            r".\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            r".\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order",
        ):
            self.assertIn(expected, normalized)


if __name__ == "__main__":
    unittest.main()
