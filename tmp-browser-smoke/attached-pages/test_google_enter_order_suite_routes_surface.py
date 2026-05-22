import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_suite_block(source: str, suite_name: str) -> str:
    pattern = re.compile(
        rf'\{{\s*\$SuiteName -eq "{re.escape(suite_name)}"\s*\}}\s*\{{(?P<body>.*?)(?=^\s*break\b)',
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find suite block for {suite_name}")
    return match.group("body")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
switch ($true) {
    { $SuiteName -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

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
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
            "Use these when the shared Enter-order ladder is already narrowed and you want the last shared form-controls keypress-before-submit gate reopened on its own surface."
        )
        break
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-enter-order-suite-routes-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleEnterOrderSuiteRoutesSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")

    def test_form_controls_suite_keeps_primary_route_and_shared_follow_up(self) -> None:
        block = extract_suite_block(self.router, "google-form-controls-enter-order")
        self.assertIn(
            'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            block,
        )
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up"', block)
        self.assertIn("show_google_shared_enter_order_validation_flow.ps1", block)
        self.assertIn("run_google_shared_enter_order_validation.ps1", block)

    def test_form_controls_suite_keeps_broader_shared_ladder_note(self) -> None:
        block = extract_suite_block(self.router, "google-form-controls-enter-order")
        self.assertIn(
            "dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface",
            block,
        )

    def test_shared_suite_keeps_primary_route_and_dedicated_follow_up(self) -> None:
        block = extract_suite_block(self.router, "google-shared-enter-order")
        self.assertIn(
            'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)',
            block,
        )
        self.assertIn(
            'Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands)',
            block,
        )
        self.assertIn(
            "last shared form-controls keypress-before-submit gate reopened on its own surface",
            block,
        )

    def test_suite_sections_keep_browser_override_visibility(self) -> None:
        for suite_name in ("google-form-controls-enter-order", "google-shared-enter-order"):
            block = extract_suite_block(self.router, suite_name)
            self.assertIn("if ($isCustomBrowserExe)", block)
            self.assertIn('Write-Host ("Browser exe: {0}" -f $BrowserExe)', block)


if __name__ == "__main__":
    unittest.main()
