import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_attached_html_validation_flow.ps1": r"""
function Get-AssetClosureCommand {
    $base = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
    if ($AllowMissingLocalAssets) {
        $base += " -AllowMissingAssets"
    }
}

function Get-SidecarAuditCommand {
    $base = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars"
    if ($AllowMissingLocalAssets) {
        $base += " -AllowMissingSidecars"
    }
}

$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1"
$attachedHtmlSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html"
$attachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
$attachedHtmlBundleSuiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
$guideDocPath = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
$windowsRunbookPath = "docs/WINDOWS_FULL_USE.md"
Write-Host "Start with the dedicated surface check, sidecar-bundle audit, and deep asset-closure audit before the printed flow or runner:"
Write-Host "Keep the broader attached-page fallback visible when the route should stay general longer or the current inputs are still the pinned bundle:"
Write-Host "Override: use -PreferredInitialPage to keep one Google-like page first, or pass -PageRoot / -InputPath to skip auto-discovery."
Write-Host "Helper:"
Write-Host "Runner:"
""",
    "scripts/windows/run_attached_html_localhost_validation.ps1": r"""
$runnerPath = Join-Path $RepoRoot "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1"
$surfaceChecker = Join-Path $RepoRoot "scripts/windows/check_attached_html_validation_surface.ps1"
$assetClosureChecker = Join-Path $RepoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"
$runnerArgs["SummaryOnly"] = $true
$runnerArgs["Wait"] = $true
$runnerArgs["LeaveServerRunning"] = $true
Write-Host "Attached HTML localhost validation"
Write-Host "Runner: .\\scripts\\windows\\run_sanitized_saved_page_localhost_validation.ps1"
Write-Host "Preflight: attached HTML validation surface and deep attached-asset closure audit passed before launch."
Write-Host "Preflight: attached HTML validation surface passed and deep attached-asset closure audit is advisory in degraded localhost mode."
Show-MissingLocalFixtureAssetWarnings -AssetAudit $attachedAssetAudit -RepoRoot $RepoRoot
""",
    "tmp-browser-smoke/attached-pages/README.md": """
# Attached Pages Localhost Harness

- `scripts/windows/start_attached_pages_catalog.ps1`
- `tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py`
- `scripts/windows/show_attached_pages_preflight_report.ps1`
- `ready_for_launch`
- the recommended next step
- direct sidecar and broader asset audit route URLs
- the selected fixture summary from the current attached-pages input set

## Sidecar-first preflight

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \\
  --input /path/to/saved-pages-dir \\
  --audit-sidecars

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 \\
  -InputPath "C:\\path\\to\\saved-pages-dir" \\
  -AuditSidecars

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \\
  --input /path/to/saved-pages-dir \\
  --audit-sidecars \\
  --allow-missing-sidecars

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 \\
  -InputPath "C:\\path\\to\\saved-pages-dir" \\
  -AuditSidecars \\
  -AllowMissingSidecars

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \\
  --input /path/to/saved-pages-dir \\
  --require-complete-sidecars \\
  --print-manifest

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 \\
  -InputPath "C:\\path\\to\\saved-pages-dir" \\
  -RequireCompleteSidecars \\
  -PrintManifest

## Asset audit

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \\
  --input /path/to/saved-pages-dir \\
  --audit-assets

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 \\
  -InputPath "C:\\path\\to\\saved-pages-dir" \\
  -AuditAssets

python tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py \\
  --input /path/to/saved-pages-dir \\
  --require-complete-assets \\
  --print-manifest

powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 \\
  -InputPath "C:\\path\\to\\saved-pages-dir" \\
  -RequireCompleteAssets \\
  -PrintManifest

## Issue #3 Google-style follow-up

- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/WINDOWS_FULL_USE.md`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1`
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath "C:\\path\\to\\saved-pages-dir"`

Use the companion helper keeps the wrapper-side sidecar audit, the broader asset audit, the strict sidecar gate, the strict asset gate, and the pinned proof checker plus proof entrypoint together on one smaller surface.
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-google-attached-preflight-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleAttachedHtmlPreflightSurfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.google_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_attached_html_validation_flow.ps1"
        )
        cls.localhost_runner = read_text(
            cls.repo_root / "scripts/windows/run_attached_html_localhost_validation.ps1"
        )
        cls.readme = read_text(
            cls.repo_root / "tmp-browser-smoke/attached-pages/README.md"
        )

    def test_google_flow_keeps_surface_sidecar_asset_and_broader_route_guidance(self) -> None:
        expected_fragments = (
            r".\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle",
            r".\\scripts\\windows\\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars",
            "-AllowMissingAssets",
            "-AllowMissingSidecars",
            r".\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
            r".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html",
            r".\\scripts\\windows\\show_attached_html_validation_flow.ps1",
            r".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/WINDOWS_FULL_USE.md",
            "sidecar-bundle audit",
            "deep asset-closure audit",
            "Keep the broader attached-page fallback visible",
            "Override: use -PreferredInitialPage",
            "Helper:",
            "Runner:",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.google_flow)

    def test_localhost_runner_keeps_surface_checker_asset_closure_and_degraded_mode(self) -> None:
        expected_fragments = (
            'Join-Path $RepoRoot "scripts/windows/check_attached_html_validation_surface.ps1"',
            'Join-Path $RepoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"',
            'Join-Path $RepoRoot "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1"',
            '$runnerArgs["SummaryOnly"] = $true',
            '$runnerArgs["Wait"] = $true',
            '$runnerArgs["LeaveServerRunning"] = $true',
            "Attached HTML localhost validation",
            r"Runner: .\\scripts\\windows\\run_sanitized_saved_page_localhost_validation.ps1",
            "Preflight: attached HTML validation surface and deep attached-asset closure audit passed before launch.",
            "Preflight: attached HTML validation surface passed and deep attached-asset closure audit is advisory in degraded localhost mode.",
            "Show-MissingLocalFixtureAssetWarnings",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.localhost_runner)

    def test_readme_keeps_sidecar_first_asset_audit_and_google_follow_up(self) -> None:
        expected_fragments = (
            "start_attached_pages_catalog.ps1",
            "attached_pages_preflight_report.py",
            "show_attached_pages_preflight_report.ps1",
            "ready_for_launch",
            "recommended next step",
            "direct sidecar and broader asset audit route URLs",
            "selected fixture summary",
            "--audit-sidecars",
            "-AuditSidecars",
            "--allow-missing-sidecars",
            "-AllowMissingSidecars",
            "--require-complete-sidecars",
            "-RequireCompleteSidecars",
            "--audit-assets",
            "-AuditAssets",
            "--require-complete-assets",
            "-RequireCompleteAssets",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/WINDOWS_FULL_USE.md",
            "show_google_attached_html_validation_flow.ps1",
            "check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
            "show_google_issue3_attached_pages_launcher_companion.ps1",
            "wrapper-side sidecar audit",
            "broader asset audit",
            "strict sidecar gate",
            "strict asset gate",
            "pinned proof checker",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.readme)


if __name__ == "__main__":
    unittest.main()
