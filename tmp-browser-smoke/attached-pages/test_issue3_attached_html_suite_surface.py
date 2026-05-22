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
    [ValidateSet("", "attached-html-target-bundle", "google-attached-html")]
    [string]$SuiteName = "",
    [string]$InputPath = "",
    [string]$PreferredInitialPage = ""
)

function Get-AttachedHtmlRouteCommands {
    param(
        [string]$TargetInputPath,
        [string]$TargetPreferredInitialPage,
        [switch]$GoogleStyle
    )

    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -AuditSidecars",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RequireCompleteSidecars -RequireCompleteAssets -PrintManifest",
        "& `" + "$BrowserExe" + "`" + " browse --headed `"http://127.0.0.1:8235/`""
    )
}

function Get-AttachedHtmlNotes {
    return @(
        "Run the attached-pages sidecar audit first so missing sibling _files directories are visible before the browser is blamed.",
        "Pass -InputPath to pin the audit, manifest, strict manifest, and catalog commands to a specific saved page or bundle folder.",
        "Pass -PreferredInitialPage when one saved page should stay first across the catalog launch and Google-shaped attached-page helper routes."
    )
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1"
    )
}

function Get-Issue3AttachedHtmlFollowUpNotes {
    param(
        [switch]$BundleFocused
    )

    if ($BundleFocused) {
        $notes = @(
            "Use the compact bundle-suite surface first when the top-level router is already narrowed to the known three-page compatibility bundle.",
            "Only drop into the bundle-first helper after the suite surface, broader attached-page flows, and the top-level quickstart are visible, so the pinned bundle route stays easy to reopen."
        )
    } else {
        $notes = @(
            "Use the attached-html change-area quickstart when you want the shorter issue #3 attached-page helper ladder visible after the broader attached-pages catalog route.",
            "Use the compact bundle-suite surface before the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
        )
    }

    $notes += "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."
    return $notes
}

function Write-Section {}
function Write-Route {}

switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        Write-Section $SuiteName
        $useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"
        $bundleFocused = $SuiteName -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        $notes = Get-AttachedHtmlNotes
        if ($useGoogleStyleCatalog) {
            $notes += "Google-style auto-discovery keeps the strongest Google-like saved page first when -InputPath is omitted."
        }
        Write-Route -Name $SuiteName -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-suite-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3AttachedHtmlSuiteSurfaceTest(unittest.TestCase):
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

    def test_suite_names_stay_on_the_router_surface(self) -> None:
        validate_set = re.search(
            r'\[ValidateSet\([^]]*"attached-html-target-bundle"[^]]*"google-attached-html"[^]]*\)\]',
            self.router,
        )
        self.assertIsNotNone(
            validate_set,
            "suite validate set should keep the Google-shaped and pinned bundle route names",
        )

        suite_branch = re.search(
            r'\{\s*\$SuiteName\s+-eq\s+"google-attached-html"\s+-or\s+\$SuiteName\s+-eq\s+"attached-html-target-bundle"\s*\}',
            self.router,
        )
        self.assertIsNotNone(
            suite_branch,
            "router should keep the dedicated suite branch for Google-shaped and pinned bundle attached-page routes",
        )

    def test_suite_branch_reuses_attached_html_catalog_helper(self) -> None:
        route_commands = extract_function_block(self.router, "Get-AttachedHtmlRouteCommands")
        self.assertIn("start_attached_pages_catalog.ps1 -AuditSidecars", route_commands)
        self.assertIn("RequireCompleteSidecars -RequireCompleteAssets -PrintManifest", route_commands)
        self.assertIn('browse --headed', route_commands)

        suite_call = re.search(
            r"Get-AttachedHtmlRouteCommands\s+-TargetInputPath\s+\$InputPath\s+-TargetPreferredInitialPage\s+\$PreferredInitialPage\s+-GoogleStyle:\$useGoogleStyleCatalog",
            self.router,
        )
        self.assertIsNotNone(
            suite_call,
            "suite branch should preserve the shared attached-pages catalog helper with Google-style routing toggle",
        )

    def test_suite_branch_keeps_issue3_follow_up_routes_visible(self) -> None:
        follow_up = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpCommands")
        for helper in (
            "check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
            "show_google_issue3_attached_html_change_area_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
        ):
            self.assertIn(helper, follow_up)

        surfaced_follow_up = re.search(
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)',
            self.router,
        )
        self.assertIsNotNone(
            surfaced_follow_up,
            "suite branch should keep the issue #3 follow-up helper surface visible",
        )

    def test_google_and_bundle_notes_keep_their_narrowing_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        self.assertIn("known three-page compatibility bundle", notes_block)
        self.assertIn("pinned bundle route stays easy to reopen", notes_block)
        self.assertIn("shorter issue #3 attached-page helper ladder", notes_block)
        self.assertIn("validation-router attached-html surface checker", notes_block)

        google_autodiscovery = re.search(
            r'Google-style auto-discovery keeps the strongest Google-like saved page first when -InputPath is omitted\.',
            self.router,
        )
        self.assertIsNotNone(
            google_autodiscovery,
            "Google-shaped suite should keep the auto-discovery note that protects the preferred saved-page route",
        )

        bundle_notes_call = re.search(
            r"Get-Issue3AttachedHtmlFollowUpNotes\s+-BundleFocused:\$bundleFocused",
            self.router,
        )
        self.assertIsNotNone(
            bundle_notes_call,
            "suite branch should keep the bundle-focused note toggle wired into the issue #3 follow-up notes",
        )


if __name__ == "__main__":
    unittest.main()
