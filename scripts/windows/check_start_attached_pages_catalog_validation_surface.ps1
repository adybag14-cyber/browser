[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-ValidationReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet("file", "directory")]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Kind = $Kind
        Purpose = $Purpose
    }
}

function New-ValidationContentExpectation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Snippet = $Snippet
        Purpose = $Purpose
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page note that sends replay through the wrapper-backed sidecar audit before the broader Google-shaped checks."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper that keeps the attached-pages launcher on the same PowerShell surface as the rest of the replay ladder."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Python launcher that drives manifest printing, localhost serving, and sidecar-aware audits for attached pages."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py" -Kind "file" -Purpose "Underlying sidecar-bundle audit helper used to separate incomplete exports from deeper runtime regressions."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader Google attached-page flow helper that stays adjacent to the wrapper-backed sidecar audit route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"' -Purpose "Windows wrapper stays pinned to the repo-local Python launcher instead of a floating external path."),
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherArgs = @($launcherPath, "--repo-root", $resolvedRepoRoot)' -Purpose "Windows wrapper always forwards the resolved repo root to the launcher."),
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherArgs += "--audit-sidecars"' -Purpose "Windows wrapper still exposes the sidecar-bundle audit mode."),
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherArgs += "--allow-missing-sidecars"' -Purpose "Windows wrapper still supports degraded sidecar-audit mode when the current export is incomplete."),
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherArgs += "--require-complete-sidecars"' -Purpose "Windows wrapper can still fail fast before manifest or server launch when sidecar bundles are incomplete."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Snippet '"--audit-sidecars"' -Purpose "Launcher still exposes the sidecar-bundle audit mode used by the Windows wrapper."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Snippet '"--allow-missing-sidecars"' -Purpose "Launcher still supports degraded sidecar-audit mode for incomplete exports."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Snippet '"--require-complete-sidecars"' -Purpose "Launcher still supports strict sidecar gating before manifest or server startup."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Snippet 'load_sidecar_module(repo_root)' -Purpose "Launcher still loads the dedicated sidecar-audit helper before it reports or enforces sidecar state."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -GoogleStyle -AuditSidecars' -Purpose "Issue-specific Google attached-page note still points at the Windows wrapper-backed sidecar audit before the broader Google-shaped checks."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot ''<repo-root>'' -InputPath ''<attached-html-or-folder>'' -GoogleStyle -AuditSidecars' -Purpose "Issue-specific Google attached-page note still shows how to preserve repo-root context on the wrapper-backed sidecar audit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'wrapper-backed sidecar-bundle audit' -Purpose "Issue-specific Google attached-page note still describes the wrapper-backed sidecar audit as the fast first check for incomplete exports.")
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = "reference"
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$contentCache = @{}
$contentResults = foreach ($expectation in $contentExpectations) {
    $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = "content"
            Path = $expectation.Path
            Kind = "content-snippet"
            Purpose = $expectation.Purpose
            Exists = $false
            Snippet = $expectation.Snippet
        }
        continue
    }

    if (-not $contentCache.ContainsKey($fullPath)) {
        $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
    }

    [pscustomobject]@{
        CheckType = "content"
        Path = $expectation.Path
        Kind = "content-snippet"
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$missingReferences = @($referenceResults | Where-Object { -not $_.Exists })
$missingContent = @($contentResults | Where-Object { -not $_.Exists })
$missing = @($missingReferences + $missingContent)

if ($Json) {
    [ordered]@{
        profile = "start-attached-pages-catalog-wrapper"
        repo_root = $resolvedRepoRoot
        checked_count = @($referenceResults).Count + @($contentResults).Count
        reference_count = @($referenceResults).Count
        content_check_count = @($contentResults).Count
        missing_count = @($missing).Count
        references = @($referenceResults)
        content_checks = @($contentResults)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Attached pages catalog wrapper surface check"
Write-Host ""
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Wrapper expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Attached pages catalog wrapper surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached pages catalog wrapper path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the Windows wrapper, the repo-local Python launcher, the sidecar-bundle audit helper, or the issue-specific Google attached-page note before trusting the wrapper-backed sidecar audit route."
exit 1
