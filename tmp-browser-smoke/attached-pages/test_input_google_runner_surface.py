import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/run_google_form_controls_enter_order_validation.ps1": r"""
[CmdletBinding()]
param()

$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"

Write-Host "=== google-form-controls-enter-order-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck @surfaceCheckArgs

Write-Host ""
Write-Host "=== google-form-controls-enter-order ==="
Write-Host ("Script: {0}" -f $runner)
& $runner @arguments
""",
    "scripts/windows/run_google_shared_enter_order_validation.ps1": r"""
[CmdletBinding()]
param()

$surfaceCheck = Join-Path $scriptRoot "check_google_shared_enter_order_validation_surface.ps1"
$sharedRunner = Join-Path $scriptRoot "run_google_input_validation.ps1"
$googleTitleProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1"
$reducedHomeKeypressProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1"
$localhostEnterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1"
$formControlsEnterOrderSurfaceCheck = Join-Path $scriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderRunner = Join-Path $scriptRoot "run_google_form_controls_enter_order_validation.ps1"

Write-Host "=== google-shared-enter-order-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck @surfaceCheckArgs

Write-Host ""
& $sharedRunner @sharedArgs

Write-Host ""
Write-Host "=== google-title-localhost ==="
Write-Host ("Script: {0}" -f $googleTitleProbe)
& $googleTitleProbe @titleProbeArgs

Write-Host ""
Write-Host "=== google-home-keypress-submit ==="
Write-Host ("Script: {0}" -f $reducedHomeKeypressProbe)
& $reducedHomeKeypressProbe @reducedHomeKeypressArgs

Write-Host ""
Write-Host "=== google-enter-order-localhost ==="
Write-Host ("Script: {0}" -f $localhostEnterOrderProbe)
& $localhostEnterOrderProbe @localhostEnterOrderArgs

Write-Host ""
Write-Host "=== form-controls-google-enter-order-surface ==="
Write-Host ("Script: {0}" -f $formControlsEnterOrderSurfaceCheck)
& $formControlsEnterOrderSurfaceCheck @formControlsEnterOrderSurfaceCheckArgs

Write-Host ""
Write-Host "=== form-controls-google-enter-order ==="
Write-Host ("Script: {0}" -f $formControlsEnterOrderRunner)
& $formControlsEnterOrderRunner @formControlsEnterOrderArgs

Write-Host ""
Write-Host "Next: if the shared surface check, shared gates, localhost title probe, reduced-home keypress-before-submit probe, localhost Enter-order wrapper, dedicated shared form-controls surface check, and dedicated shared form-controls Google enter-order runner stay green, move on to the smallest live Google manual pass."
""",
    "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the dedicated form-controls Enter-order gate discoverable."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated form-controls Enter-order runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable shared click-first fallback probe that the dedicated Enter-order flow helper prints with -GoogleEnterOrder -ClickFocus."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface.")
)
""",
    "scripts/windows/check_google_shared_enter_order_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared headed validation suite router that should keep the google-shared-enter-order slice reachable from the broader catalog."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "One-command shared Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated fail-fast checker for the final shared form-controls gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared baseline runner used before the stricter Enter-order probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Reduced localhost Google title probe used before the Enter-order wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Localhost Enter-order wrapper used before broader replay."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Reusable click-first shared probe that mirrors the Google-shaped Enter path before the dedicated form-controls gate.")
)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-input-google-runner-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class InputGoogleRunnerSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.form_controls_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        )
        cls.shared_runner = read_text(
            cls.repo_root / "scripts/windows/run_google_shared_enter_order_validation.ps1"
        )
        cls.form_controls_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1"
        )
        cls.shared_surface = read_text(
            cls.repo_root / "scripts/windows/check_google_shared_enter_order_validation_surface.ps1"
        )

    def test_form_controls_runner_keeps_surface_check_and_probe_handoff(self) -> None:
        self.assertIn("check_google_form_controls_enter_order_validation_surface.ps1", self.form_controls_runner)
        self.assertIn(r"tmp-browser-smoke\form-controls\google-enter-order-probe.ps1", self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order-surface ===", self.form_controls_runner)
        self.assertIn("=== google-form-controls-enter-order ===", self.form_controls_runner)

    def test_shared_runner_keeps_staged_google_handoff_chain(self) -> None:
        for expected in (
            "check_google_shared_enter_order_validation_surface.ps1",
            "run_google_input_validation.ps1",
            r"tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1",
            r"tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1",
            r"tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1",
            "check_google_form_controls_enter_order_validation_surface.ps1",
            "run_google_form_controls_enter_order_validation.ps1",
        ):
            self.assertIn(expected, self.shared_runner)

        for section in (
            "=== google-shared-enter-order-surface ===",
            "=== google-title-localhost ===",
            "=== google-home-keypress-submit ===",
            "=== google-enter-order-localhost ===",
            "=== form-controls-google-enter-order-surface ===",
            "=== form-controls-google-enter-order ===",
        ):
            self.assertIn(section, self.shared_runner)

        self.assertIn("move on to the smallest live Google manual pass", self.shared_runner)

    def test_form_controls_surface_checker_keeps_router_runner_and_probe_references(self) -> None:
        for expected in (
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
        ):
            self.assertIn(expected, self.form_controls_surface)

    def test_shared_surface_checker_keeps_shared_and_dedicated_follow_on_references(self) -> None:
        for expected in (
            "scripts/windows/show_headed_validation_suites.ps1",
            "scripts/windows/run_google_shared_enter_order_validation.ps1",
            "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1",
            "scripts/windows/run_google_form_controls_enter_order_validation.ps1",
            "scripts/windows/run_google_input_validation.ps1",
            "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1",
            "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1",
            "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1",
            "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1",
            "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        ):
            self.assertIn(expected, self.shared_surface)


if __name__ == "__main__":
    unittest.main()
