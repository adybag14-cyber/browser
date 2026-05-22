import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/run_issue3_enter_submit_runtime_revalidation.ps1": """
[CmdletBinding()]
param(
    [switch]$SkipSharedEnterOrder,
    [switch]$SkipReducedGoogleProbe,
    [switch]$LeaveOpen,
    [switch]$Json
)

$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$sharedRunner = Join-Path $PSScriptRoot "run_google_form_controls_enter_order_validation.ps1"
$reducedProbe = Join-Path $RepoRoot "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"

foreach ($path in @($surfaceCheck, $sharedRunner, $reducedProbe)) {
    throw "Required runtime revalidation helper not found: $path"
}

$steps.Add((Run-Step -Name "google-form-controls-enter-order-surface" -Action {
    & $surfaceCheck -RepoRoot $RepoRoot
})) | Out-Null

$steps.Add((Run-Step -Name "google-form-controls-enter-order" -Action {
    & $sharedRunner -RepoRoot $RepoRoot
})) | Out-Null

$steps.Add((Run-Step -Name "reduced-google-home-title-probe" -Action {
    & $reducedProbe -RepoRoot $RepoRoot -LeaveOpen:$LeaveOpen
})) | Out-Null

$manualCommand = ".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:{0}/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1" -f $ReducedGoogleProbePort

[ordered]@{
    profile = "issue3-enter-submit-runtime-revalidation"
    shared_enter_order_port = $SharedEnterOrderPort
    reduced_google_probe_port = $ReducedGoogleProbePort
    skipped_shared_enter_order = [bool]$SkipSharedEnterOrder
    skipped_reduced_google_probe = [bool]$SkipReducedGoogleProbe
    leave_open = [bool]$LeaveOpen
    manual_reduced_probe_command = $manualCommand
} | ConvertTo-Json -Depth 6
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-runner-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3EnterSubmitRuntimeRevalidationRunnerSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.runner_script = read_text(
            cls.repo_root / "scripts/windows/run_issue3_enter_submit_runtime_revalidation.ps1"
        )

    def test_runner_keeps_required_helper_dependencies(self) -> None:
        for snippet in (
            'check_google_form_controls_enter_order_validation_surface.ps1',
            'run_google_form_controls_enter_order_validation.ps1',
            'tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1',
            'Required runtime revalidation helper not found: $path',
        ):
            self.assertIn(snippet, self.runner_script)

    def test_runner_keeps_step_sequence_and_manual_replay(self) -> None:
        for snippet in (
            'Run-Step -Name "google-form-controls-enter-order-surface"',
            'Run-Step -Name "google-form-controls-enter-order"',
            'Run-Step -Name "reduced-google-home-title-probe"',
            'Manual reduced-probe replay',
            'google_home_title_probe.html?google-home-probe=1',
        ):
            self.assertIn(snippet, self.runner_script)

    def test_runner_keeps_skip_switches_and_json_contract(self) -> None:
        for snippet in (
            '[switch]$SkipSharedEnterOrder',
            '[switch]$SkipReducedGoogleProbe',
            '[switch]$LeaveOpen',
            '[switch]$Json',
            'profile = "issue3-enter-submit-runtime-revalidation"',
            'shared_enter_order_port = $SharedEnterOrderPort',
            'reduced_google_probe_port = $ReducedGoogleProbePort',
            'skipped_shared_enter_order = [bool]$SkipSharedEnterOrder',
            'skipped_reduced_google_probe = [bool]$SkipReducedGoogleProbe',
            'leave_open = [bool]$LeaveOpen',
            'manual_reduced_probe_command = $manualCommand',
        ):
            self.assertIn(snippet, self.runner_script)


if __name__ == "__main__":
    unittest.main()
