import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_validate_set(source: str, parameter_name: str) -> list[str]:
    parameter_marker = f"[string]${parameter_name}"
    parameter_index = source.find(parameter_marker)
    if parameter_index == -1:
        raise AssertionError(f"Could not find parameter {parameter_name}")

    validate_start = source.rfind("[ValidateSet(", 0, parameter_index)
    if validate_start == -1:
        raise AssertionError(f"Could not find ValidateSet for {parameter_name}")

    body_start = validate_start + len("[ValidateSet(")
    body_end = source.find(")]", body_start)
    if body_end == -1 or body_end > parameter_index:
        raise AssertionError(f"Could not parse ValidateSet for {parameter_name}")

    return re.findall(r'"(.*?)"', source[body_start:body_end])


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
[CmdletBinding()]
param(
    [ValidateSet("", "attached-html-target-bundle", "google-attached-html", "google-form-controls-enter-order", "google-recommended", "google-shared-enter-order")]
    [string]$SuiteName = "",
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "browser-shell", "google-attached-html", "google-form-controls-enter-order", "google-input", "google-shared-enter-order", "input", "manual-html", "navigation", "network", "popup", "rendering", "stop-loading")]
    [string]$ChangeArea = "",
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$SummaryPath = "",
    [string]$InputPath = "",
    [string]$PreferredInitialPage = ""
)

function Show-DefaultRoutes {
    Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
    Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)
    Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
    Write-Route -Name "network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)
    Write-Route -Name "browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
    Write-Route -Name "popup" -Commands (Get-PopupRouteCommands) -Notes (Get-PopupRouteNotes)
    Write-Route -Name "google-recommended" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
    ) -Notes @(
        "Use the shared Enter-submit probe first, then the dedicated Google form-controls Enter-order gate, then verify Google homepage typing, focus retention, and Enter submit manually."
    )
}

switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        break
    }
    { $SuiteName -eq "google-form-controls-enter-order" } {
        break
    }
    { $SuiteName -eq "google-shared-enter-order" } {
        break
    }
    { $SuiteName -eq "google-recommended" } {
        break
    }
    { $ChangeArea -eq "browser-shell" } {
        Write-Route -Name "bounded-browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)
        break
    }
    { $ChangeArea -eq "popup" } {
        Write-Route -Name "bounded-popup" -Commands (Get-PopupRouteCommands) -Notes (Get-PopupRouteNotes)
        break
    }
    { $ChangeArea -eq "rendering" } {
        Write-Route -Name "bounded-rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
        break
    }
    { $ChangeArea -eq "network" } {
        Write-Route -Name "bounded-network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands)
        break
    }
    default {
        Show-DefaultRoutes
        break
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-headed-suite-selection-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class HeadedValidationSuiteSelectionSurfaceTest(unittest.TestCase):
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

    def test_suite_name_validate_set_keeps_headed_google_and_attached_entrypoints(self) -> None:
        suite_names = extract_validate_set(self.router, "SuiteName")
        expected = {
            "",
            "attached-html-target-bundle",
            "google-attached-html",
            "google-form-controls-enter-order",
            "google-recommended",
            "google-shared-enter-order",
        }
        self.assertEqual(expected, set(suite_names))

    def test_change_area_validate_set_keeps_bounded_headed_routes(self) -> None:
        change_areas = extract_validate_set(self.router, "ChangeArea")
        expected = {
            "",
            "attached-html",
            "attached-html-target-bundle",
            "browser-shell",
            "google-attached-html",
            "google-form-controls-enter-order",
            "google-input",
            "google-shared-enter-order",
            "input",
            "manual-html",
            "navigation",
            "network",
            "popup",
            "rendering",
            "stop-loading",
        }
        self.assertEqual(expected, set(change_areas))

    def test_default_router_keeps_high_value_headed_route_names(self) -> None:
        default_block = re.search(
            r"function Show-DefaultRoutes \{(?P<body>.*?)^\}",
            self.router,
            re.MULTILINE | re.DOTALL,
        )
        self.assertIsNotNone(default_block, "Show-DefaultRoutes should exist")
        body = default_block.group("body")
        for route_name in (
            "google-form-controls-enter-order",
            "google-shared-enter-order",
            "rendering",
            "network",
            "browser-shell",
            "popup",
            "google-recommended",
        ):
            self.assertIn(f'Write-Route -Name "{route_name}"', body)

    def test_suite_specific_switch_cases_keep_specialized_entrypoints(self) -> None:
        for fragment in (
            '$SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle"',
            '$SuiteName -eq "google-form-controls-enter-order"',
            '$SuiteName -eq "google-shared-enter-order"',
            '$SuiteName -eq "google-recommended"',
        ):
            self.assertIn(fragment, self.router)

    def test_change_area_switch_cases_keep_bounded_route_families(self) -> None:
        expected_blocks = (
            ('$ChangeArea -eq "browser-shell"', 'Write-Route -Name "bounded-browser-shell"'),
            ('$ChangeArea -eq "popup"', 'Write-Route -Name "bounded-popup"'),
            ('$ChangeArea -eq "rendering"', 'Write-Route -Name "bounded-rendering"'),
            ('$ChangeArea -eq "network"', 'Write-Route -Name "bounded-network"'),
        )
        for selector, route_line in expected_blocks:
            self.assertIn(selector, self.router)
            self.assertIn(route_line, self.router)

        attached_cluster = (
            '$ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" '
            '-or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html"'
        )
        self.assertIn(attached_cluster, self.router)
        self.assertIn('Write-Route -Name "attached-pages-catalog-follow-up"', self.router)


if __name__ == "__main__":
    unittest.main()
