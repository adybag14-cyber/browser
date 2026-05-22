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
function Get-AttachedHtmlNotes {
    $notes = @(
        "Run the attached-pages sidecar audit first so missing sibling _files directories are visible before the browser is blamed.",
        "Run the attached-pages asset audit second so missing local assets stay visible before the browser is blamed.",
        "After the sidecar audit passes, reuse -RequireCompleteSidecars when you want the manifest or localhost catalog launch to fail fast on incomplete saved-page bundles.",
        "After the asset audit passes, reuse -RequireCompleteAssets when you want the manifest or localhost catalog launch to fail fast on incomplete saved-page asset sets.",
        "Pair -RequireCompleteSidecars with -RequireCompleteAssets when both bundle structure and local asset closure must be complete before replay.",
        "Use the attached-pages catalog wrapper to pin the current HTML bundle and expose short localhost routes at /, /manifest.json, /pages/<n>, /named/<slug>, and /raw/... .",
        "The broader attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1.",
        "The Google-shaped attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1.",
        "The issue #3 top-level attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1.",
        "The shorter issue #3 attached-page change-area quickstart remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1.",
        "The dedicated issue #3 validation-router attached-html surface checker remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1.",
        "The manual-html change area still reuses this attached-pages catalog route when you want a direct saved-page replay without a narrower bounded family.",
        "Start the catalog in one shell, then open the generated catalog or a manifest-backed short route from a second shell."
    )
    $notes += "Pass -InputPath to pin the audit, manifest, strict manifest, and catalog commands to a specific saved page or bundle folder."
    $notes += "Pass -PreferredInitialPage when one saved page should stay first across the catalog launch and Google-shaped attached-page helper routes."
    return $notes
}

function Get-AttachedHtmlCatalogCommand {}

function Get-AttachedHtmlRouteCommands {
    return @(
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('AuditSidecars')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('AuditAssets')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteSidecars', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteSidecars')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteAssets')),
        (Get-AttachedHtmlCatalogCommand -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets')),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1"
    )
}

function Get-Issue3AttachedHtmlFollowUpNotes {
    param([switch]$BundleFocused)
    $notes = @(
        "Use the attached-html change-area quickstart when you want the shorter issue #3 attached-page helper ladder visible after the broader attached-pages catalog route.",
        "Use the top-level attached-page quickstart when the next replay should stay inside that shorter issue #3 attached-page ladder before you drop into the bundle-only or shortcut-first helpers.",
        "Keep the broader attached-page flow visible when the replay may still widen back out beyond the shorter issue #3 attached-page ladder.",
        "Keep the dedicated Google-shaped attached-page flow visible when the replay still looks Google-like before you narrow into the bundle-only or shortcut-first helpers.",
        "Use the compact bundle-suite surface before the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
    )
    if ($BundleFocused) {
        $notes += "Use the compact bundle-suite surface first when the top-level router is already narrowed to the known three-page compatibility bundle."
    }
    return $notes
}

Write-Route -Name "attached-html" -Commands $commands -Notes $notes
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)
Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes
Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
$notes += "Google-style auto-discovery keeps the strongest Google-like saved page first when -InputPath is omitted."
""",
    "scripts/windows/start_attached_pages_catalog.ps1": r"""
function Resolve-OrderedAttachedHtmlInputs {}
if ($PrintManifest -and ($AuditAssets -or $AuditSidecars)) {
    throw "Choose either -PrintManifest, -AuditAssets, or -AuditSidecars. The attached-pages helper cannot combine manifest and audit modes in the same invocation."
}
if ($AuditAssets -and $AuditSidecars) {
    throw "Choose either -AuditAssets or -AuditSidecars. The attached-pages helper can only run one audit mode per invocation."
}
if ($RequireCompleteSidecars -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes. Run the sidecar audit first, then rerun with -RequireCompleteSidecars when you want the manifest or localhost server to fail fast on incomplete bundles."
}
if ($RequireCompleteAssets -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes. Run the asset audit first, then rerun with -RequireCompleteAssets when you want the manifest or localhost server to fail fast on incomplete bundles."
}
$launcherPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source
if ($PreferredInitialPage) {
    $launcherArgs += @("--preferred-initial-page", $PreferredInitialPage)
}
if ($GoogleStyle) {
    $launcherArgs += "--google-style"
}
if ($PrintManifest) {
    $launcherArgs += "--print-manifest"
} elseif ($AuditAssets) {
    $launcherArgs += "--audit-assets"
    if ($AuditAssetsJson) {
        $launcherArgs += "--audit-assets-json"
    }
} elseif ($AuditSidecars) {
    $launcherArgs += "--audit-sidecars"
    if ($AuditSidecarsJson) {
        $launcherArgs += "--audit-sidecars-json"
    }
} else {
    $launcherArgs += @("--bind", $Bind, "--port", "$Port")
}
if ($RequireCompleteSidecars) {
    $launcherArgs += "--require-complete-sidecars"
}
if ($RequireCompleteAssets) {
    $launcherArgs += "--require-complete-assets"
}
& $resolvedPython @launcherArgs
""",
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlValidationHint {}
function Get-AttachedHtmlTargetBundleRecommendation {}
function Get-AttachedHtmlOverallRecommendation {
    if ($BundleRecommendation -and $BundleRecommendation.overall_recommendation -and $BundleRecommendation.overall_recommendation.bundle_validation_profile) {
        return [ordered]@{
            change_area = "attached-html-target-bundle"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
        }
    }
    if ($GoogleStyle -or ($Hints | Where-Object { $_.change_area -eq "google-attached-html" })) {
        return [ordered]@{
            change_area = "google-attached-html"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
        }
    }
    if ($Hints | Where-Object { $_.change_area -eq "input" }) {
        return [ordered]@{
            change_area = "input"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
        }
    }
    if ($Hints | Where-Object { $_.change_area -eq "rendering" }) {
        return [ordered]@{
            change_area = "rendering"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
        }
    }
    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
    }
}
$assetClosureChecker = Join-Path $repoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"
$helperPath = Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
Write-Host "Per-page bounded validation hints:"
Write-Host ("Overall first bounded step: {0}" -f $overallRecommendation.first_step)
Write-Host ("Overall follow-up: {0}" -f $overallRecommendation.follow_up)
""",
    "scripts/windows/show_google_attached_html_validation_flow.ps1": r"""
$surfaceCheck = '.\\scripts\\windows\\check_google_attached_html_validation_surface.ps1'
$attachedHtmlSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html"
$attachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
$attachedHtmlBundleSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
$sidecarAuditCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars"
$assetClosureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
$guideDocPath = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
$windowsRunbookPath = "docs/WINDOWS_FULL_USE.md"
$googleAttachedHtmlMetadata.broader_attached_html_route = [ordered]@{
    suite_router_command = $attachedHtmlSuiteRouterCommand
    flow_command = $attachedHtmlFlowCommand
    bundle_suite_router_command = $attachedHtmlBundleSuiteRouterCommand
}
Write-Host "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:"
Write-Host ("- {0}" -f $surfaceCheckCommand)
Write-Host ("- {0}" -f $sidecarAuditCommand)
Write-Host ("- {0}" -f $assetClosureCommand)
Write-Host "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:"
Write-Host ("- {0}" -f $attachedHtmlSuiteRouterCommand)
Write-Host ("- {0}" -f $attachedHtmlFlowCommand)
Write-Host ("- {0}" -f $attachedHtmlBundleSuiteRouterCommand)
Write-Host "Override: use -PreferredInitialPage to keep one Google-like page first, or pass -PageRoot / -InputPath to skip auto-discovery."
Write-Host ("Helper: {0}" -f $handoffCommands.helper_command)
Write-Host ("Runner: {0}" -f $handoffCommands.runner_command)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlCatalogValidationSurfaceTest(unittest.TestCase):
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
        cls.catalog = read_text(cls.repo_root / "scripts/windows/start_attached_pages_catalog.ps1")
        cls.attached_flow = read_text(cls.repo_root / "scripts/windows/show_attached_html_validation_flow.ps1")
        cls.google_flow = read_text(cls.repo_root / "scripts/windows/show_google_attached_html_validation_flow.ps1")

    def test_router_keeps_attached_catalog_modes_and_localhost_launch(self) -> None:
        commands = extract_function_block(self.router, "Get-AttachedHtmlRouteCommands")
        for fragment in (
            "AuditSidecars",
            "AuditAssets",
            "PrintManifest",
            "RequireCompleteSidecars",
            "RequireCompleteAssets",
            'browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`"',
        ):
            self.assertIn(fragment, commands)

    def test_router_notes_keep_audit_and_follow_up_guidance(self) -> None:
        notes = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        for fragment in (
            "attached-pages sidecar audit first",
            "attached-pages asset audit second",
            "-RequireCompleteSidecars",
            "-RequireCompleteAssets",
            "catalog wrapper",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "manual-html change area still reuses this attached-pages catalog route",
            "Pass -InputPath",
            "Pass -PreferredInitialPage",
        ):
            self.assertIn(fragment, notes)

    def test_router_keeps_attached_html_and_issue3_follow_up_routes(self) -> None:
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"attached-pages-catalog-follow-up"\s+-Commands',
        )
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)',
        )
        follow_up = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpCommands")
        for helper in (
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(helper, follow_up)

    def test_router_keeps_bundle_and_google_style_follow_up_notes(self) -> None:
        notes = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        for fragment in (
            "shorter issue #3 attached-page helper ladder",
            "broader attached-page flow visible",
            "dedicated Google-shaped attached-page flow visible",
            "compact bundle-suite surface",
            "known three-page compatibility bundle",
        ):
            self.assertIn(fragment, notes)
        self.assertIn("Google-style auto-discovery keeps the strongest Google-like saved page first", self.router)

    def test_catalog_helper_keeps_mode_gates_and_launcher_flags(self) -> None:
        for fragment in (
            "Choose either -PrintManifest, -AuditAssets, or -AuditSidecars",
            "Choose either -AuditAssets or -AuditSidecars",
            "-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes",
            "-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes",
            "start_attached_pages_catalog.py",
            "(Get-Command $PythonExe -ErrorAction Stop).Source",
            "--preferred-initial-page",
            "--google-style",
            "--print-manifest",
            "--audit-assets",
            "--audit-sidecars",
            "--require-complete-sidecars",
            "--require-complete-assets",
        ):
            self.assertIn(fragment, self.catalog)
        self.assertIn("Resolve-OrderedAttachedHtmlInputs", self.catalog)

    def test_general_attached_flow_keeps_recommendation_ladder(self) -> None:
        for fragment in (
            'change_area = "attached-html-target-bundle"',
            'change_area = "google-attached-html"',
            'change_area = "input"',
            'change_area = "rendering"',
            'change_area = "attached-html"',
            "check_attached_html_local_asset_closure.ps1",
            "show_localhost_html_validation_flow.ps1",
            "Per-page bounded validation hints:",
            "Overall first bounded step",
            "Overall follow-up",
        ):
            self.assertIn(fragment, self.attached_flow)

    def test_google_attached_flow_keeps_surface_checks_and_broader_fallback(self) -> None:
        for fragment in (
            "check_google_attached_html_validation_surface.ps1",
            "start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars",
            "check_attached_html_local_asset_closure.ps1 -GoogleStyle",
            'show_headed_validation_suites.ps1 -ChangeArea attached-html',
            'show_attached_html_validation_flow.ps1',
            'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle',
            "broader_attached_html_route",
            "surface check, sidecar-bundle audit, and deep asset-closure audit",
            "Override: use -PreferredInitialPage",
            "Helper:",
            "Runner:",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/WINDOWS_FULL_USE.md",
        ):
            self.assertIn(fragment, self.google_flow)


if __name__ == "__main__":
    unittest.main()
