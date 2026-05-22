import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
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
    [string]$StagingRoot,
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

function Resolve-OrderedAttachedHtmlInputs {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RawInputPath,
        [string]$PreferredPage
    )

    $resolvedInputs = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $htmlFiles = Get-ChildItem -LiteralPath $item.FullName -Recurse -File |
        Where-Object { Test-HtmlExportPath -Path $_.FullName } |
        Sort-Object FullName

    if ([string]::IsNullOrWhiteSpace($PreferredPage)) {
        return @($resolvedInputs.ToArray())
    }

    if (Test-Path -LiteralPath $PreferredPage) {
        $resolvedPreferredPath = (Resolve-Path -LiteralPath $PreferredPage).Path
    }

    $availableNames = ($resolvedInputs | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ", "
    throw "Preferred initial page '$PreferredPage' did not match any selected attached HTML file. Available files: $availableNames"
}

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

$launcherPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source
$launcherArgs = @($launcherPath, "--repo-root", $resolvedRepoRoot)

if ($PSCmdlet.ParameterSetName -eq "InputPath") {
    $orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage
    foreach ($path in $orderedInputs) {
        $launcherArgs += @("--input", $path)
    }
}

if ($PreferredInitialPage) {
    $launcherArgs += @("--preferred-initial-page", $PreferredInitialPage)
}

if ($GoogleStyle) {
    $launcherArgs += "--google-style"
}

if (-not [string]::IsNullOrWhiteSpace($StagingRoot)) {
    $launcherArgs += @("--staging-root", $StagingRoot)
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
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-pages-catalog-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class StartAttachedPagesCatalogSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.source = read_text(cls.repo_root / "scripts/windows/start_attached_pages_catalog.ps1")

    def test_parameter_surface_keeps_catalog_and_audit_switches(self) -> None:
        for fragment in (
            '[switch]$GoogleStyle',
            '[switch]$PrintManifest',
            '[switch]$AuditAssets',
            '[switch]$AuditAssetsJson',
            '[switch]$AllowMissingAssets',
            '[switch]$AuditSidecars',
            '[switch]$AuditSidecarsJson',
            '[switch]$AllowMissingSidecars',
            '[switch]$RequireCompleteSidecars',
            '[switch]$RequireCompleteAssets',
        ):
            self.assertIn(fragment, self.source)

    def test_mutual_exclusion_guards_keep_helpful_error_messages(self) -> None:
        for fragment in (
            'Choose either -PrintManifest, -AuditAssets, or -AuditSidecars.',
            'Choose either -AuditAssets or -AuditSidecars.',
            '-AuditAssetsJson requires -AuditAssets.',
            '-AllowMissingAssets is only supported with -AuditAssets.',
            '-AuditSidecarsJson requires -AuditSidecars.',
            '-AllowMissingSidecars is only supported with -AuditSidecars.',
            '-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes.',
            '-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes.',
            'Run the sidecar audit first',
            'Run the asset audit first',
        ):
            self.assertIn(fragment, self.source)

    def test_launcher_path_and_python_resolution_stay_explicit(self) -> None:
        self.assertIn(
            'Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"',
            self.source,
        )
        self.assertIn('(Get-Command $PythonExe -ErrorAction Stop).Source', self.source)
        self.assertIn('@($launcherPath, "--repo-root", $resolvedRepoRoot)', self.source)

    def test_input_ordering_and_preferred_page_flow_stay_visible(self) -> None:
        self.assertIn('Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage', self.source)
        self.assertIn('Get-ChildItem -LiteralPath $item.FullName -Recurse -File', self.source)
        self.assertIn('Where-Object { Test-HtmlExportPath -Path $_.FullName }', self.source)
        self.assertIn('@("--input", $path)', self.source)
        self.assertIn('@("--preferred-initial-page", $PreferredInitialPage)', self.source)
        self.assertIn("Available files: $availableNames", self.source)

    def test_catalog_launcher_preserves_google_style_manifest_and_audit_modes(self) -> None:
        for fragment in (
            '--google-style',
            '--print-manifest',
            '--audit-assets',
            '--audit-assets-json',
            '--allow-missing-assets',
            '--audit-sidecars',
            '--audit-sidecars-json',
            '--allow-missing-sidecars',
            '--require-complete-sidecars',
            '--require-complete-assets',
        ):
            self.assertIn(fragment, self.source)

    def test_default_launch_mode_keeps_bind_and_port_arguments(self) -> None:
        self.assertRegex(
            self.source,
            re.compile(r'\$launcherArgs \+= @\("--bind", \$Bind, "--port", "\$Port"\)'),
        )
        self.assertIn('if (-not [string]::IsNullOrWhiteSpace($StagingRoot)) {', self.source)
        self.assertIn('@("--staging-root", $StagingRoot)', self.source)


if __name__ == "__main__":
    unittest.main()
