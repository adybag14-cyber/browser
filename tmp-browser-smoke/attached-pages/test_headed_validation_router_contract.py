import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_validate_set_options(source: str, variable_name: str) -> list[str]:
    marker = f"[string]${variable_name}"
    marker_index = source.find(marker)
    if marker_index == -1:
        raise AssertionError(f"Could not find ValidateSet for ${variable_name}")
    validate_start = source.rfind("[ValidateSet(", 0, marker_index)
    if validate_start == -1:
        raise AssertionError(f"Could not find ValidateSet start for ${variable_name}")
    validate_end = source.find(")]", validate_start, marker_index)
    if validate_end == -1:
        raise AssertionError(f"Could not find ValidateSet end for ${variable_name}")
    body = source[validate_start + len("[ValidateSet(") : validate_end]
    return re.findall(r'"([^"]*)"', body)


def extract_switch_branch(source: str, header_pattern: str) -> str:
    match = re.search(header_pattern, source)
    if not match:
        raise AssertionError(f"Could not find switch branch matching: {header_pattern}")
    branch_start = source.find("{", match.end())
    if branch_start == -1:
        raise AssertionError(f"Could not find branch start for: {header_pattern}")

    depth = 0
    for index in range(branch_start, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[branch_start : index + 1]

    raise AssertionError(f"Could not find branch end for: {header_pattern}")


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

function Get-AttachedHtmlNotes {
    $notes = @(
        "Pass -InputPath to pin the audit, manifest, strict manifest, and catalog commands to a specific saved page or bundle folder.",
        "Pass -PreferredInitialPage when one saved page should stay first across the catalog launch and Google-shaped attached-page helper routes."
    )
    return $notes
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
    )
}

function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1"
    )
}

function Get-GoogleSharedEnterOrderCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1"
    )
}

function Show-DefaultRoutes {
    Write-Route -Name "navigation" -Commands @()
    Write-Route -Name "stop-loading" -Commands @()
    Write-Route -Name "input" -Commands @()
    Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
    Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)
    Write-Route -Name "rendering" -Commands @()
    Write-Route -Name "network" -Commands @()
    Write-Route -Name "browser-shell" -Commands @()
    Write-Route -Name "popup" -Commands @()
    Write-Route -Name "attached-html" -Commands @() -Notes (Get-AttachedHtmlNotes)
    Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
    Write-Route -Name "google-recommended" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
        "& `"$BrowserExe`" browse --headed `"https://www.google.com/`"",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
    ) -Notes @(
        "Pass -InputPath when you already want the attached-page helpers pinned to a saved page or the current three-page compatibility bundle.",
        "Keep the same preferred starting page pinned by rerunning this router with -PreferredInitialPage before switching to the Google-shaped attached-page helper route.",
        "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder.",
        "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
    )
}

switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        Write-Route -Name $SuiteName -Commands @()
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
        break
    }
    { $SuiteName -eq "google-form-controls-enter-order" } {
        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @()
        break
    }
    { $SuiteName -eq "google-shared-enter-order" } {
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands)
        break
    }
    { $SuiteName -eq "google-recommended" } {
        Write-Route -Name "google-recommended" -Commands @()
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
        break
    }
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Route -Name "bounded-input" -Commands @()
        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
        Write-Route -Name "manual-google" -Commands @(
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        )
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
        break
    }
    { $ChangeArea -eq "google-form-controls-enter-order" } {
        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @()
        break
    }
    { $ChangeArea -eq "google-shared-enter-order" } {
        Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands)
        Write-Route -Name "dedicated-form-controls-follow-up" -Commands (Get-GoogleFormControlsEnterOrderCommands)
        break
    }
    { $ChangeArea -eq "rendering" } {
        Write-Route -Name "bounded-rendering" -Commands @()
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands @() -Notes (Get-AttachedHtmlNotes)
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
        break
    }
    { $ChangeArea -eq "network" } {
        Write-Route -Name "bounded-network" -Commands @()
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands @() -Notes (Get-AttachedHtmlNotes)
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
        break
    }
    { $ChangeArea -eq "browser-shell" } {
        Write-Route -Name "bounded-browser-shell" -Commands @()
        break
    }
    { $ChangeArea -eq "popup" } {
        Write-Route -Name "bounded-popup" -Commands @()
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands @() -Notes (Get-AttachedHtmlNotes)
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands)
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
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-router-contract-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class HeadedValidationRouterContractTest(unittest.TestCase):
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

    def test_suite_name_validate_set_keeps_supported_specialized_views(self) -> None:
        self.assertEqual(
            extract_validate_set_options(self.router, "SuiteName"),
            [
                "",
                "attached-html-target-bundle",
                "google-attached-html",
                "google-form-controls-enter-order",
                "google-recommended",
                "google-shared-enter-order",
            ],
        )

    def test_change_area_validate_set_keeps_supported_top_level_routes(self) -> None:
        self.assertEqual(
            extract_validate_set_options(self.router, "ChangeArea"),
            [
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
            ],
        )

    def test_default_surface_keeps_all_main_headed_routes_visible(self) -> None:
        self.assertIn("Show-DefaultRoutes", self.router)
        default_block = extract_switch_branch(self.router, r"default")
        self.assertIn("Show-DefaultRoutes", default_block)

        show_default_routes = extract_switch_branch(self.router, r"function Show-DefaultRoutes")
        expected_routes = (
            'Write-Route -Name "navigation"',
            'Write-Route -Name "stop-loading"',
            'Write-Route -Name "input"',
            'Write-Route -Name "google-form-controls-enter-order"',
            'Write-Route -Name "google-shared-enter-order"',
            'Write-Route -Name "rendering"',
            'Write-Route -Name "network"',
            'Write-Route -Name "browser-shell"',
            'Write-Route -Name "popup"',
            'Write-Route -Name "attached-html"',
            'Write-Route -Name "issue3-attached-html-follow-up"',
            'Write-Route -Name "google-recommended"',
        )
        for route in expected_routes:
            self.assertIn(route, show_default_routes)

    def test_google_recommended_default_route_keeps_google_and_issue3_ladder(self) -> None:
        self.assertIn(r'show_headed_validation_suites.ps1 -ChangeArea input', self.router)
        self.assertIn(r'show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order', self.router)
        self.assertIn('browse --headed `"https://www.google.com/`"', self.router)
        for helper in (
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(helper, self.router)

    def test_google_recommended_notes_keep_pinning_arguments_visible(self) -> None:
        for fragment in (
            "Pass -InputPath",
            "-PreferredInitialPage",
            "-SummaryPath",
            "-BrowserExe",
        ):
            self.assertIn(fragment, self.router)

    def test_google_input_branch_keeps_manual_google_and_issue3_follow_up(self) -> None:
        branch = extract_switch_branch(
            self.router,
            r'\{\s*\$ChangeArea -eq "input" -or \$ChangeArea -eq "google-input"\s*\}',
        )
        self.assertIn('Write-Route -Name "bounded-input"', branch)
        self.assertIn('Write-Route -Name "google-form-controls-enter-order"', branch)
        self.assertIn('Write-Route -Name "manual-google"', branch)
        self.assertIn('browse --headed `"https://www.google.com/`"', branch)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', branch)

    def test_specialized_suite_views_keep_cross_links_to_follow_up_ladders(self) -> None:
        form_controls_branch = extract_switch_branch(
            self.router,
            r'\{\s*\$SuiteName -eq "google-form-controls-enter-order"\s*\}',
        )
        self.assertIn('Write-Route -Name "shared-enter-order-follow-up"', form_controls_branch)

        shared_branch = extract_switch_branch(
            self.router,
            r'\{\s*\$SuiteName -eq "google-shared-enter-order"\s*\}',
        )
        self.assertIn('Write-Route -Name "dedicated-form-controls-follow-up"', shared_branch)

        google_recommended_branch = extract_switch_branch(
            self.router,
            r'\{\s*\$SuiteName -eq "google-recommended"\s*\}',
        )
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', google_recommended_branch)

        attached_bundle_branch = extract_switch_branch(
            self.router,
            r'\{\s*\$SuiteName -eq "google-attached-html" -or \$SuiteName -eq "attached-html-target-bundle"\s*\}',
        )
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', attached_bundle_branch)

    def test_change_area_views_keep_attached_html_follow_up_where_expected(self) -> None:
        for condition in (
            r'\{\s*\$ChangeArea -eq "rendering"\s*\}',
            r'\{\s*\$ChangeArea -eq "network"\s*\}',
            r'\{\s*\$ChangeArea -eq "attached-html" -or \$ChangeArea -eq "attached-html-target-bundle" -or \$ChangeArea -eq "google-attached-html" -or \$ChangeArea -eq "manual-html"\s*\}',
        ):
            branch = extract_switch_branch(self.router, condition)
            self.assertIn('Write-Route -Name "attached-pages-catalog-follow-up"', branch)
            self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', branch)


if __name__ == "__main__":
    unittest.main()
