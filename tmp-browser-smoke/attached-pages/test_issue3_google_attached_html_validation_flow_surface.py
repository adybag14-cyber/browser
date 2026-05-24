from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md": """
    # Issue #3 Google Attached HTML Validation Flow

    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
    docs/WINDOWS_FULL_USE.md
    docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md
    docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md
    docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md
    docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md
    docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md
    docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md
    docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md
    docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md
    docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md
    docs/ISSUE3_REPLAY_ROUTE.md
    docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md
    docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md
    docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md
    docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md
    docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md
    docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md
    tmp-browser-smoke/attached-pages/README.md
    scripts\\windows\\show_google_attached_html_validation_flow.ps1
    scripts\\windows\\start_attached_pages_catalog.ps1
    -AuditSidecars
    -AuditAssets
    -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest
    Control your online safety and privacy – Google Safety Centre
    python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait
    """,
    "docs/WINDOWS_FULL_USE.md": """
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1
    """,
    "scripts/windows/check_google_attached_html_validation_surface.ps1": """
    docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md
    docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md
    docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md
    docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md
    docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md
    docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md
    docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md
    docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md
    docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md
    docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md
    docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md
    tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py
    tmp-browser-smoke/attached-pages/test_attached_pages_sidecar_audit.py
    scripts/windows/show_google_attached_html_validation_flow.ps1
    scripts/windows/run_google_attached_html_validation.ps1
    function Get-SidecarAuditCommand {
    sidecar_audit_command = $SidecarAuditCommand
    $surfaceCheck = '.\\scripts\\windows\\check_google_attached_html_validation_surface.ps1'
    $attachedHtmlBundleSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
    $googleAttachedHtmlMetadata.broader_attached_html_route = [ordered]@{
    Write-Host "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:"
    Write-Host ("- {0}" -f $sidecarAuditCommand)
    Write-Host "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:"
    Write-Host ("- {0}" -f $attachedHtmlBundleSuiteRouterCommand)
    Write-Host ("Helper: {0}" -f $handoffCommands.helper_command)
    Write-Host ("Runner: {0}" -f $handoffCommands.runner_command)
    """,
    "scripts/windows/show_google_attached_html_validation_flow.ps1": """
    function Get-SidecarAuditCommand {
    powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars
    function Get-GoogleAttachedHtmlHandoffCommands {
    helper_command = $helperCommand
    runner_command = $RunnerCommand
    function Get-GoogleAttachedHtmlFlowMetadata {
    validation_mode = "google-style"
    sidecar_audit_command = $SidecarAuditCommand
    asset_closure_command = $AssetClosureCommand
    helper_command = $HelperCommand
    runner_command = $RunnerCommand
    search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }
    $surfaceCheck = '.\\scripts\\windows\\check_google_attached_html_validation_surface.ps1'
    $guideDocPath = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
    $windowsRunbookPath = "docs/WINDOWS_FULL_USE.md"
    $attachedHtmlSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html"
    $attachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
    $attachedHtmlBundleSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
    $googleAttachedHtmlMetadata.broader_attached_html_route = [ordered]@{
    Write-Host "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:"
    Write-Host ("- {0}" -f $sidecarAuditCommand)
    Write-Host "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:"
    Write-Host ("- {0}" -f $attachedHtmlSuiteRouterCommand)
    Write-Host ("- {0}" -f $attachedHtmlFlowCommand)
    Write-Host ("- {0}" -f $attachedHtmlBundleSuiteRouterCommand)
    Write-Host ("Helper: {0}" -f $handoffCommands.helper_command)
    Write-Host ("Runner: {0}" -f $handoffCommands.runner_command)
    show_saved_page_google_validation_flow.ps1
    Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
    No Google-style attached HTML files were found under:
    """,
    "scripts/windows/run_google_attached_html_validation.ps1": """
    check_google_attached_html_validation_surface.ps1
    check_attached_html_local_asset_closure.ps1
    validation_mode = "google-style"
    deep_asset_closure_checked = $AssetClosureChecked
    missing_asset_audit = $normalizedAssetAudit
    search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }
    Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
    No Google-style attached HTML files were found under:
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot
    Show-MissingLocalFixtureAssetWarnings -AssetAudit $missingAssetAudit -RepoRoot $resolvedRepoRoot
    Write-Host "Preflight: deep attached-asset closure audit passed before launch."
    Write-Host "Runner: .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -GoogleStyle"
    run_localhost_html_validation_recommended.ps1
    """,
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py": """
    def discover_attached_html_candidates(repo_root: Path, *, cwd: Path | None = None) -> list[Path]:
    def google_style_fixture_summary(path: Path) -> dict[str, object]:
    def is_google_style_fixture(path: Path) -> bool:
    def select_attached_html_inputs(
    google_style: bool = False,
    preferred_initial_page: str | None = None,
    if google_style:
    google_candidates = [path for path in selected if is_google_style_fixture(path)]
    selected = sorted(
    key=lambda path: (-int(google_style_fixture_summary(path)["score"]), str(path)),
    def load_sidecar_module(repo_root: Path) -> ModuleType:
    def render_strict_sidecar_failure(report: str) -> str:
    --audit-sidecars
    --allow-missing-sidecars
    --require-complete-sidecars
    --google-style
    Mode:
    Inputs pinned:
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-attached-html-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3GoogleAttachedHtmlValidationFlowSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_doc = read_text(
            cls.repo_root / "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
        )
        cls.windows_guide = read_text(cls.repo_root / "docs/WINDOWS_FULL_USE.md")
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/windows/check_google_attached_html_validation_surface.ps1"
        )
        cls.flow_helper = read_text(
            cls.repo_root / "scripts/windows/show_google_attached_html_validation_flow.ps1"
        )
        cls.runner = read_text(
            cls.repo_root / "scripts/windows/run_google_attached_html_validation.ps1"
        )
        cls.catalog_helper = read_text(
            cls.repo_root / "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
        )

    def test_route_doc_keeps_google_attached_html_preflight_and_handoff_visible(self) -> None:
        for fragment in (
            "show_google_attached_html_validation_flow.ps1",
            "docs/WINDOWS_FULL_USE.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
            "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            "docs/ISSUE3_REPLAY_ROUTE.md",
            "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
            "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
            "tmp-browser-smoke/attached-pages/README.md",
            "start_attached_pages_catalog.ps1",
            "-AuditSidecars",
            "-AuditAssets",
            "-RequireCompleteSidecars -RequireCompleteAssets -PrintManifest",
            "Control your online safety and privacy – Google Safety Centre",
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars",
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1 -GoogleStyle",
            "run_google_attached_html_validation.ps1 -Wait",
        ):
            self.assertIn(fragment, self.route_doc)

    def test_windows_guide_keeps_google_attached_html_reentry_visible(self) -> None:
        for fragment in (
            "show_google_issue3_windows_full_use_attached_html_route.ps1",
            "show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1",
            "show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
            "show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            "show_google_attached_html_validation_flow.ps1",
        ):
            self.assertIn(fragment, self.windows_guide)

    def test_surface_checker_keeps_broader_route_sidecar_and_runner_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md",
            "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md",
            "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md",
            "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md",
            "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md",
            "tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py",
            "tmp-browser-smoke/attached-pages/test_attached_pages_sidecar_audit.py",
            "scripts/windows/show_google_attached_html_validation_flow.ps1",
            "scripts/windows/run_google_attached_html_validation.ps1",
            "function Get-SidecarAuditCommand {",
            "sidecar_audit_command = $SidecarAuditCommand",
            "check_google_attached_html_validation_surface.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "$googleAttachedHtmlMetadata.broader_attached_html_route = [ordered]@{",
            "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:",
            "Write-Host (\"- {0}\" -f $sidecarAuditCommand)",
            "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:",
            "Write-Host (\"- {0}\" -f $attachedHtmlBundleSuiteRouterCommand)",
            "Write-Host (\"Helper: {0}\" -f $handoffCommands.helper_command)",
            "Write-Host (\"Runner: {0}\" -f $handoffCommands.runner_command)",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_flow_helper_keeps_sidecar_audit_broader_fallback_and_handoff_metadata_visible(self) -> None:
        for fragment in (
            "function Get-SidecarAuditCommand {",
            "start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars",
            "function Get-GoogleAttachedHtmlHandoffCommands {",
            "helper_command = $helperCommand",
            "runner_command = $RunnerCommand",
            "function Get-GoogleAttachedHtmlFlowMetadata {",
            'validation_mode = "google-style"',
            "sidecar_audit_command = $SidecarAuditCommand",
            "asset_closure_command = $AssetClosureCommand",
            "helper_command = $HelperCommand",
            "runner_command = $RunnerCommand",
            'search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }',
            "check_google_attached_html_validation_surface.ps1",
            '$guideDocPath = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"',
            '$windowsRunbookPath = "docs/WINDOWS_FULL_USE.md"',
            "show_headed_validation_suites.ps1 -ChangeArea attached-html",
            "show_attached_html_validation_flow.ps1",
            "show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "$googleAttachedHtmlMetadata.broader_attached_html_route = [ordered]@{",
            "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:",
            'Write-Host ("- {0}" -f $sidecarAuditCommand)',
            "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:",
            'Write-Host ("- {0}" -f $attachedHtmlSuiteRouterCommand)',
            'Write-Host ("- {0}" -f $attachedHtmlFlowCommand)',
            'Write-Host ("- {0}" -f $attachedHtmlBundleSuiteRouterCommand)',
            'Write-Host ("Helper: {0}" -f $handoffCommands.helper_command)',
            'Write-Host ("Runner: {0}" -f $handoffCommands.runner_command)',
            "show_saved_page_google_validation_flow.ps1",
            "Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle",
            "Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath",
            "No Google-style attached HTML files were found under:",
        ):
            self.assertIn(fragment, self.flow_helper)

    def test_runner_and_catalog_helper_keep_google_style_auto_discovery_and_strict_bundle_preflight_visible(self) -> None:
        for fragment in (
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1",
            'validation_mode = "google-style"',
            "deep_asset_closure_checked = $AssetClosureChecked",
            "missing_asset_audit = $normalizedAssetAudit",
            'search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }',
            "Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle",
            "Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath",
            "No Google-style attached HTML files were found under:",
            "Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot",
            "Show-MissingLocalFixtureAssetWarnings -AssetAudit $missingAssetAudit -RepoRoot $resolvedRepoRoot",
            "Preflight: deep attached-asset closure audit passed before launch.",
            "run_localhost_html_validation_recommended.ps1 -GoogleStyle",
            "run_localhost_html_validation_recommended.ps1",
        ):
            self.assertIn(fragment, self.runner)

        for fragment in (
            "discover_attached_html_candidates",
            "google_style_fixture_summary",
            "is_google_style_fixture",
            "select_attached_html_inputs",
            "google_style: bool = False",
            "preferred_initial_page: str | None = None",
            "if google_style:",
            "google_candidates = [path for path in selected if is_google_style_fixture(path)]",
            "key=lambda path: (-int(google_style_fixture_summary(path)[\"score\"]), str(path))",
            "load_sidecar_module",
            "render_strict_sidecar_failure",
            "--audit-sidecars",
            "--allow-missing-sidecars",
            "--require-complete-sidecars",
            "--google-style",
            "Mode:",
            "Inputs pinned:",
        ):
            self.assertIn(fragment, self.catalog_helper)


if __name__ == "__main__":
    unittest.main()
