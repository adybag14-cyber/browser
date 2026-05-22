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

function Get-AttachedHtmlRouteCommands {
    param([string]$TargetInputPath, [string]$TargetPreferredInitialPage, [switch]$GoogleStyle)
    return @("powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1")
}

function Get-Issue3AttachedHtmlFollowUpNotes {
    param([switch]$BundleFocused)
    if ($BundleFocused) {
        $notes = @(
            "Use the compact bundle-suite surface first when the top-level router is already narrowed to the known three-page compatibility bundle.",
            "Keep the broader attached-page flow, the dedicated Google-shaped attached-page flow, and the top-level attached-page quickstart visible until the current pages are clearly still the pinned bundle.",
            "Only drop into the bundle-first helper after the suite surface, broader attached-page flows, and the top-level quickstart are visible, so the pinned bundle route stays easy to reopen."
        )
    }
    return $notes
}

Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
""",
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlOverallRecommendation {
    param(
        [object[]]$Hints,
        [bool]$GoogleStyle,
        $BundleRecommendation
    )

    if ($BundleRecommendation -and $BundleRecommendation.overall_recommendation -and $BundleRecommendation.overall_recommendation.bundle_validation_profile) {
        $bundleOverall = $BundleRecommendation.overall_recommendation
        return [ordered]@{
            change_area = "attached-html-target-bundle"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
            follow_up = $bundleOverall.bundle_surface_check
            summary = "Known three-page attached HTML compatibility bundle detected. Keep the bundle-aware route pinned before the broader generic attached-page flow."
            bundle_validation_profile = $bundleOverall.bundle_validation_profile
            bundle_locked_input_count = $bundleOverall.bundle_locked_input_count
            bundle_surface_check = $bundleOverall.bundle_surface_check
            bundle_asset_closure = $bundleOverall.bundle_asset_closure
            bundle_flow = $bundleOverall.bundle_flow
            bundle_runner = $bundleOverall.bundle_runner
            bundle_summary = $bundleOverall.bundle_summary
        }
    }
}
""",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$surface = [ordered]@{
    known_bundle_files = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    preferred_initial_page_hint = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
    suite_commands = [ordered]@{
        attached_html_target_bundle = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
        attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        google_attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html"
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1"
        google_attached_html_asset_closure = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
        broader_attached_html_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
        google_attached_html_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
        google_issue3_attached_html_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
        google_issue3_attached_html_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1"
        bundle_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1"
        bundle_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1"
        bundle_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1"
        bundle_runner = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait"
        bundle_proof_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
        top_level_attached_html_bridge = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1"
        bundle_first_entrypoint = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
        replay_route = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1"
        replay_shortcuts = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1"
    }
    notes = @(
        'Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle and you want the compact suite surface first.',
        'Keep the attached_html suite command nearby when the replay may still need the broader attached-page fallback before it locks onto the pinned bundle branch.',
        'Keep the google_attached_html suite command nearby when the current inputs include a Google-like attached page and the narrower issue-specific Google attached-page chain still matters before bundle-first replay.',
        'When the replay should stay pinned to the known three-page compatibility bundle, use the exact saved filenames printed on this surface and prefer the Google Safety Centre export as -PreferredInitialPage when one Google-like page should stay first.',
        'Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Pass -PreferredInitialPage when the suite surface should keep the same Google-like page first across the broader attached-page lane, the narrower issue #3 re-entry helpers, and the compact bundle-first follow-up.'
    )
}
$surface.recommended_next_key = 'bundle_surface_check'
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    broader_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
    google_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-attached-html"
    windows_replay_attached_html_quickstart_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1"
    top_level_attached_html_quickstart_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1"
    attached_html_shortcut_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1"
    attached_html_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    google_attached_html_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
    bundle_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1"
    bundle_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1"
    suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
    bundle_flow_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1"
    bundle_runner_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait"
    bundle_proof_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
    bundle_proof_entrypoint_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1"
    local_html_fixture_surface_check_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1"
    local_html_fixture_probe_command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"
    replay_shortcuts_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1"
    return_to_safe_route_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1"
    notes = @(
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Start with bundle_surface_check_command so the pinned bundle reference note, bundle quickstart, written proof note, pinned manual checklist, checker, helper, runner, and delegated attached-html surfaces fail fast before localhost replay.',
        'Run bundle_check_command next when you want the current saved-page set revalidated as the same three-page compatibility bundle before you trust the printed flow helper or runner.',
        'Use suite_router_command when you want the attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers, the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, the bundle checker, the proof-note surface, and the bundle flow helper before the delegated localhost runner.',
        'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.',
        'Use replay_shortcuts_command after the bundle replay when you want the broader issue #3 discovery bridge, attached-bundle branch, and safe-route shortcuts printed together before choosing whether to stay broad or narrow next.'
    )
}
""",
    "scripts/windows/check_attached_html_target_bundle.ps1": r"""
function Get-AttachedBundleTargetSpec {
    return @(
        [pscustomobject]@{
            Name = "google-safety-centre"
            DisplayName = "Control your online safety and privacy – Google Safety Centre"
            Purpose = "Google-branded policy and content-heavy compatibility target."
        }
        [pscustomobject]@{
            Name = "anthropic-job-application"
            DisplayName = "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic"
            Purpose = "Form-heavy application page compatibility target."
        }
        [pscustomobject]@{
            Name = "uap-encounters"
            DisplayName = "Presidential Unsealing and Reporting System for UAP Encounters"
            Purpose = "Dense document and script-heavy compatibility target."
        }
    )
}

function Get-OverallBundleRecommendation {
    return [ordered]@{
        summary = "Keep the strongest Google-style target first so the bundle stays aligned with the issue #3 localhost-first follow-up before the broader attached-page replay."
        bundle_validation_profile = "google-attached-html"
        bundle_locked_input_count = 3
        bundle_surface_check = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1"
        bundle_asset_closure = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1"
        bundle_flow = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
        bundle_runner = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait"
        bundle_summary = "Keep the current compatibility bundle locked into the Google-style attached HTML route, with the strongest Google-style page pinned first for the issue #3 localhost-first follow-up."
    }
}

Write-Host "Known attached HTML compatibility bundle is present."
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-target-bundle-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlTargetBundleValidationSurfaceTest(unittest.TestCase):
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
        cls.attached_flow = read_text(
            cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1"
        )
        cls.bundle_suite_surface = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first_entrypoint = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )
        cls.bundle_checker = read_text(
            cls.repo_root / "scripts/windows/check_attached_html_target_bundle.ps1"
        )

    def test_router_keeps_bundle_surface_in_validate_sets(self) -> None:
        self.assertIn('"attached-html-target-bundle"', self.router)
        self.assertIn('"manual-html"', self.router)

    def test_router_keeps_bundle_focused_follow_up_notes(self) -> None:
        notes_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        expected_fragments = (
            "compact bundle-suite surface first",
            "pinned bundle",
            "bundle-first helper",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, notes_block)

    def test_attached_html_flow_keeps_bundle_overall_recommendation(self) -> None:
        overall_block = extract_function_block(
            self.attached_flow, "Get-AttachedHtmlOverallRecommendation"
        )
        expected_fragments = (
            'change_area = "attached-html-target-bundle"',
            'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle',
            "Known three-page attached HTML compatibility bundle detected",
            "bundle_validation_profile",
            "bundle_locked_input_count",
            "bundle_surface_check",
            "bundle_asset_closure",
            "bundle_flow",
            "bundle_runner",
            "bundle_summary",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, overall_block)

    def test_bundle_suite_surface_keeps_known_files_and_parallel_routes(self) -> None:
        expected_fragments = (
            "Control your online safety and privacy",
            "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic",
            "Presidential Unsealing and Reporting System for UAP Encounters",
            "preferred_initial_page_hint",
            "attached_html_target_bundle",
            "attached_html =",
            "google_attached_html =",
            "broader_attached_html_flow",
            "google_attached_html_flow",
            "bundle_surface_check",
            "bundle_check",
            "bundle_flow",
            "bundle_runner",
            "bundle_proof_entrypoint",
            "bundle_first_entrypoint",
            "replay_shortcuts",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_pinning_and_revalidation_guidance(self) -> None:
        expected_fragments = (
            "compact suite surface first",
            "broader attached-page fallback",
            "Google-like attached page",
            "-PreferredInitialPage",
            "Run bundle_surface_check before trusting the bundle-only replay",
            "Pass -BrowserExe",
            "recommended_next_key",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_suite_surface)

    def test_bundle_first_entrypoint_keeps_reentry_bundle_and_proof_paths(self) -> None:
        expected_fragments = (
            "broader_attached_html_suite_router_command",
            "google_attached_html_suite_router_command",
            "windows_replay_attached_html_quickstart_command",
            "top_level_attached_html_quickstart_command",
            "attached_html_shortcut_command",
            "attached_html_flow_command",
            "google_attached_html_flow_command",
            "bundle_surface_check_command",
            "bundle_check_command",
            "suite_router_command",
            "bundle_flow_command",
            "bundle_runner_command",
            "bundle_proof_surface_check_command",
            "bundle_proof_entrypoint_command",
            "local_html_fixture_surface_check_command",
            "local_html_fixture_probe_command",
            "replay_shortcuts_command",
            "return_to_safe_route_command",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_keeps_bundle_lane_guidance(self) -> None:
        expected_fragments = (
            "wider attached-page router",
            "Google-shaped attached-page route",
            "pinned manual checklist",
            "three-page compatibility bundle",
            "delegated localhost runner",
            "written proof note",
            "replay_shortcuts_command",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.bundle_first_entrypoint)

    def test_bundle_checker_keeps_targets_and_bundle_pinned_recommendation(self) -> None:
        target_block = extract_function_block(self.bundle_checker, "Get-AttachedBundleTargetSpec")
        for fragment in (
            "google-safety-centre",
            "anthropic-job-application",
            "uap-encounters",
            "Google-branded policy and content-heavy compatibility target.",
            "Form-heavy application page compatibility target.",
            "Dense document and script-heavy compatibility target.",
        ):
            self.assertIn(fragment, target_block)

        recommendation_block = extract_function_block(
            self.bundle_checker, "Get-OverallBundleRecommendation"
        )
        for fragment in (
            "Keep the strongest Google-style target first",
            'bundle_validation_profile = "google-attached-html"',
            "bundle_locked_input_count = 3",
            "bundle_surface_check",
            "bundle_asset_closure",
            "bundle_flow",
            "bundle_runner",
            "bundle_summary",
        ):
            self.assertIn(fragment, recommendation_block)

        self.assertIn("Known attached HTML compatibility bundle is present.", self.bundle_checker)


if __name__ == "__main__":
    unittest.main()
