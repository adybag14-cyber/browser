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
    return $notes
}

function Get-AttachedHtmlRouteCommands {
    param(
        [string]$TargetInputPath,
        [string]$TargetPreferredInitialPage,
        [switch]$GoogleStyle
    )

    return @(
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets')),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}
""",
    "scripts/windows/show_attached_html_validation_flow.ps1": r"""
function Get-AttachedHtmlValidationHint {
    param(
        [string]$Path,
        [bool]$GoogleStyle
    )

    return [ordered]@{
        fixture = "General Page.html"
        change_area = "attached-html"
        summary = "General attached page. Start with the closest bounded suite for the subsystem you changed, then use the attached-page localhost flow."
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

function Get-AttachedHtmlOverallRecommendation {
    param(
        [object[]]$Hints,
        [bool]$GoogleStyle,
        $BundleRecommendation
    )

    if ($BundleRecommendation -and $BundleRecommendation.overall_recommendation -and $BundleRecommendation.overall_recommendation.bundle_validation_profile) {
        return [ordered]@{
            change_area = "attached-html-target-bundle"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
            follow_up = $bundleOverall.bundle_surface_check
            summary = "Known three-page attached HTML compatibility bundle detected. Keep the bundle-aware route pinned before the broader generic attached-page flow."
        }
    }

    if ($GoogleStyle -or ($Hints | Where-Object { $_.change_area -eq "google-attached-html" })) {
        return [ordered]@{
            change_area = "google-attached-html"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "input" }) {
        return [ordered]@{
            change_area = "input"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "rendering" }) {
        return [ordered]@{
            change_area = "rendering"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
    }
}

$helperPath = if ($GoogleStyle) {
    Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
}
""",
    "scripts/windows/start_attached_pages_catalog.ps1": r"""
[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [string]$Bind = "127.0.0.1",
    [int]$Port = 8235,
    [switch]$GoogleStyle,
    [switch]$PrintManifest,
    [switch]$AuditAssets,
    [switch]$AuditAssetsJson,
    [switch]$AllowMissingAssets,
    [switch]$AuditSidecars,
    [switch]$AuditSidecarsJson,
    [switch]$AllowMissingSidecars,
    [switch]$RequireCompleteSidecars,
    [switch]$RequireCompleteAssets
)

if ($PrintManifest -and ($AuditAssets -or $AuditSidecars)) {
    throw "Choose either -PrintManifest, -AuditAssets, or -AuditSidecars. The attached-pages helper cannot combine manifest and audit modes in the same invocation."
}
if ($AuditAssets -and $AuditSidecars) {
    throw "Choose either -AuditAssets or -AuditSidecars. The attached-pages helper can only run one audit mode per invocation."
}
if ($AuditAssetsJson -and -not $AuditAssets) {
    throw "-AuditAssetsJson requires -AuditAssets."
}
if ($AllowMissingAssets -and -not $AuditAssets) {
    throw "-AllowMissingAssets is only supported with -AuditAssets."
}
if ($AuditSidecarsJson -and -not $AuditSidecars) {
    throw "-AuditSidecarsJson requires -AuditSidecars."
}
if ($AllowMissingSidecars -and -not $AuditSidecars) {
    throw "-AllowMissingSidecars is only supported with -AuditSidecars."
}
if ($RequireCompleteSidecars -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes. Run the sidecar audit first, then rerun with -RequireCompleteSidecars when you want the manifest or localhost server to fail fast on incomplete bundles."
}
if ($RequireCompleteAssets -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes. Run the asset audit first, then rerun with -RequireCompleteAssets when you want the manifest or localhost server to fail fast on incomplete bundles."
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
    if ($AllowMissingAssets) {
        $launcherArgs += "--allow-missing-assets"
    }
} elseif ($AuditSidecars) {
    $launcherArgs += "--audit-sidecars"
    if ($AuditSidecarsJson) {
        $launcherArgs += "--audit-sidecars-json"
    }
    if ($AllowMissingSidecars) {
        $launcherArgs += "--allow-missing-sidecars"
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
""",
    "scripts/windows/show_localhost_html_validation_flow.ps1": r"""
$attachedHelper = '.\scripts\windows\run_attached_html_localhost_validation.ps1'
$googleAttachedFlowHelper = '.\scripts\windows\show_google_attached_html_validation_flow.ps1'

$flow = [ordered]@{
    steps = @(
        [ordered]@{
            name = "suite-map"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea manual-html"
        }
        [ordered]@{
            name = "attached-auto"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_localhost_validation.ps1 -Port 8123 -Wait"
        }
        [ordered]@{
            name = "google-flow"
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -Port 8123"
        }
    )
    notes = @(
        "Use attached-auto when the current run already has HTML snapshots under agent_files and you want the helper to auto-discover the inputs and preferred first page before the manual headed follow-up.",
        "Use google-flow before google-manual when the saved-page follow-up is part of the Google-style headed typing investigation.",
        "When PreferredInitialPage is set, the attached-auto, summary, direct, staged, sanitized, Google-style flow, and Google manual commands keep that page as the first headed target instead of falling back to a generated index or another arbitrary file."
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-pages-catalog-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedPagesCatalogValidationSurfaceTest(unittest.TestCase):
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
        cls.catalog_launcher = read_text(
            cls.repo_root / "scripts/windows/start_attached_pages_catalog.ps1"
        )
        cls.localhost_flow = read_text(
            cls.repo_root / "scripts/windows/show_localhost_html_validation_flow.ps1"
        )

    def test_attached_html_notes_keep_audit_and_follow_up_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        expected_fragments = (
            "sidecar audit first",
            "asset audit second",
            "-RequireCompleteSidecars",
            "-RequireCompleteAssets",
            "attached-pages catalog wrapper",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "manual-html change area still reuses this attached-pages catalog route",
            "Start the catalog in one shell",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, notes_block)

    def test_attached_html_route_commands_keep_audits_manifest_and_launch(self) -> None:
        commands_block = extract_function_block(self.router, "Get-AttachedHtmlRouteCommands")
        expected_fragments = (
            "@('AuditSidecars')",
            "@('AuditAssets')",
            "@('PrintManifest')",
            "@('RequireCompleteSidecars', 'PrintManifest')",
            "@('RequireCompleteAssets', 'PrintManifest')",
            "@('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')",
            "@('RequireCompleteSidecars')",
            "@('RequireCompleteAssets')",
            "@('RequireCompleteSidecars', 'RequireCompleteAssets')",
            'browse --headed --window_width 1366 --window_height 900',
            'http://127.0.0.1:8235/',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, commands_block)

    def test_attached_html_flow_keeps_general_bundle_google_and_rendering_recommendations(self) -> None:
        hint_block = extract_function_block(self.attached_flow, "Get-AttachedHtmlValidationHint")
        self.assertIn('change_area = "attached-html"', hint_block)
        self.assertIn(r'show_headed_validation_suites.ps1 -ChangeArea attached-html', hint_block)
        self.assertIn(r'show_attached_html_validation_flow.ps1', hint_block)

        overall_block = extract_function_block(
            self.attached_flow, "Get-AttachedHtmlOverallRecommendation"
        )
        expected_fragments = (
            'change_area = "attached-html-target-bundle"',
            'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle',
            'Known three-page attached HTML compatibility bundle detected',
            'change_area = "google-attached-html"',
            'show_google_attached_html_validation_flow.ps1',
            'run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle',
            'change_area = "input"',
            'show_headed_validation_suites.ps1 -ChangeArea input',
            'change_area = "rendering"',
            'show_headed_validation_suites.ps1 -ChangeArea rendering',
            'show_headed_validation_suites.ps1 -ChangeArea network',
            'change_area = "attached-html"',
            'run_localhost_html_validation_recommended.ps1 -Wait',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, overall_block)

        self.assertIn(
            'Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"',
            self.attached_flow,
        )
        self.assertIn(
            'Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"',
            self.attached_flow,
        )

    def test_catalog_launcher_keeps_mode_guards_and_launcher_flags(self) -> None:
        expected_fragments = (
            'Choose either -PrintManifest, -AuditAssets, or -AuditSidecars.',
            'Choose either -AuditAssets or -AuditSidecars.',
            '-AuditAssetsJson requires -AuditAssets.',
            '-AllowMissingAssets is only supported with -AuditAssets.',
            '-AuditSidecarsJson requires -AuditSidecars.',
            '-AllowMissingSidecars is only supported with -AuditSidecars.',
            '-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes.',
            '-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes.',
            '$launcherArgs += "--google-style"',
            '$launcherArgs += "--print-manifest"',
            '$launcherArgs += "--audit-assets"',
            '$launcherArgs += "--audit-assets-json"',
            '$launcherArgs += "--allow-missing-assets"',
            '$launcherArgs += "--audit-sidecars"',
            '$launcherArgs += "--audit-sidecars-json"',
            '$launcherArgs += "--allow-missing-sidecars"',
            '$launcherArgs += @("--bind", $Bind, "--port", "$Port")',
            '$launcherArgs += "--require-complete-sidecars"',
            '$launcherArgs += "--require-complete-assets"',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.catalog_launcher)

    def test_localhost_flow_keeps_attached_auto_and_google_bridge(self) -> None:
        self.assertIn('name = "suite-map"', self.localhost_flow)
        self.assertIn(
            r'command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea manual-html"',
            self.localhost_flow,
        )
        self.assertIn('name = "attached-auto"', self.localhost_flow)
        self.assertIn(r'run_attached_html_localhost_validation.ps1', self.localhost_flow)
        self.assertIn('name = "google-flow"', self.localhost_flow)
        self.assertIn(r'show_google_attached_html_validation_flow.ps1', self.localhost_flow)
        self.assertIn("Use attached-auto when the current run already has HTML snapshots under agent_files", self.localhost_flow)
        self.assertIn("Use google-flow before google-manual", self.localhost_flow)
        self.assertIn("When PreferredInitialPage is set", self.localhost_flow)


if __name__ == "__main__":
    unittest.main()
