[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning,
    [switch]$AllowMissingLocalAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Invoke-BundleSurfaceCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckPath,
        [string]$RepoRoot
    )

    $surfaceCheckArgs = @{}
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        $surfaceCheckArgs.RepoRoot = $RepoRoot
    }

    & $SurfaceCheckPath @surfaceCheckArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Invoke-BundleChecker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckerPath,
        [string]$RepoRoot,
        [string[]]$InputPath
    )

    $checkerArgs = @{ Json = $true }
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        $checkerArgs.RepoRoot = $RepoRoot
    }
    if ($InputPath -and $InputPath.Count -gt 0) {
        $checkerArgs.InputPath = $InputPath
    }

    $bundleJson = (& $CheckerPath @checkerArgs) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    return $bundleJson | ConvertFrom-Json -Depth 12
}

function Resolve-BundleRunnerMetadata {
    param(
        [Parameter(Mandatory = $true)]
        $Bundle,
        [string]$PreferredInitialPage
    )

    $overall = $Bundle.overall_recommendation
    if (-not $overall) {
        throw "Attached HTML target bundle checker did not return an overall recommendation."
    }
    if (-not $overall.bundle_validation_profile) {
        throw "Attached HTML target bundle checker did not return bundle validation metadata."
    }

    $resolvedTargets = @($Bundle.targets | Where-Object { $_.status -eq "found" -and $_.path })
    if ($resolvedTargets.Count -eq 0) {
        throw "No attached HTML bundle targets were resolved, so the bundle-aware runner cannot launch."
    }

    $resolvedInputPath = @($resolvedTargets | ForEach-Object { $_.path })
    $resolvedPreferredInitialPage = if ($PreferredInitialPage) {
        Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
    } elseif ($overall.preferred_initial_page) {
        $overall.preferred_initial_page
    } else {
        $null
    }

    $runnerLeaf = switch ($overall.bundle_validation_profile) {
        "google-attached-html" { "run_google_attached_html_validation.ps1" }
        "attached-html" { "run_attached_html_localhost_validation.ps1" }
        default {
            throw "Unsupported attached HTML bundle validation profile '$($overall.bundle_validation_profile)'."
        }
    }

    return [pscustomobject]@{
        validation_profile = $overall.bundle_validation_profile
        summary = $overall.bundle_summary
        preferred_initial_page = $resolvedPreferredInitialPage
        resolved_input_path = $resolvedInputPath
        runner_leaf = $runnerLeaf
    }
}

$bundleSurfaceCheckPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle_validation_surface.ps1"
if (-not (Test-Path -LiteralPath $bundleSurfaceCheckPath -PathType Leaf)) {
    throw "Attached HTML target-bundle validation surface checker not found: $bundleSurfaceCheckPath"
}

$bundleCheckerPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
if (-not (Test-Path -LiteralPath $bundleCheckerPath -PathType Leaf)) {
    throw "Attached HTML target bundle checker not found: $bundleCheckerPath"
}

Invoke-BundleSurfaceCheck -SurfaceCheckPath $bundleSurfaceCheckPath -RepoRoot $RepoRoot
$bundle = Invoke-BundleChecker -CheckerPath $bundleCheckerPath -RepoRoot $RepoRoot -InputPath $InputPath
$runnerMetadata = Resolve-BundleRunnerMetadata -Bundle $bundle -PreferredInitialPage $PreferredInitialPage
$runnerPath = Join-Path $PSScriptRoot $runnerMetadata.runner_leaf
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "Attached HTML bundle runner target not found: $runnerPath"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$runnerArgs = @{
    RepoRoot = $resolvedRepoRoot
    InputPath = $runnerMetadata.resolved_input_path
    Host = $Host
    Port = $Port
}
if ($runnerMetadata.preferred_initial_page) {
    $runnerArgs.PreferredInitialPage = $runnerMetadata.preferred_initial_page
}
if ($BrowserExe) {
    $runnerArgs.BrowserExe = $BrowserExe
}
if ($SummaryOnly) {
    $runnerArgs.SummaryOnly = $true
}
if ($Wait) {
    $runnerArgs.Wait = $true
}
if ($LeaveServerRunning) {
    $runnerArgs.LeaveServerRunning = $true
}
if ($AllowMissingLocalAssets) {
    $runnerArgs.AllowMissingLocalAssets = $true
}

if (-not $SummaryOnly) {
    Write-Host "Attached HTML target bundle validation"
    Write-Host ""
    Write-Host ("Validation profile: {0}" -f $runnerMetadata.validation_profile)
    Write-Host ("Locked input count: {0}" -f $runnerMetadata.resolved_input_path.Count)
    if ($runnerMetadata.preferred_initial_page) {
        Write-Host ("Preferred initial page: {0}" -f (Convert-ToDisplayPath -Path $runnerMetadata.preferred_initial_page -RepoRoot $resolvedRepoRoot))
    }
    Write-Host ("Bundle summary: {0}" -f $runnerMetadata.summary)
    Write-Host ("Delegated runner: .\scripts\windows\{0}" -f $runnerMetadata.runner_leaf)
    if ($AllowMissingLocalAssets) {
        Write-Host "Attached asset policy: degraded mode allowed"
    }
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $runnerMetadata.resolved_input_path -RepoRoot $resolvedRepoRoot -GoogleStyle:($runnerMetadata.validation_profile -eq "google-attached-html")
    Write-Host ""
}

& $runnerPath @runnerArgs
exit $LASTEXITCODE
