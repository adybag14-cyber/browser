[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8168,
    [switch]$AllowMissingLocalAssets,
    [switch]$AllowPartialBundle
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Invoke-JsonScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [hashtable]$Arguments
    )

    $json = (& $ScriptPath @Arguments) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if ([string]::IsNullOrWhiteSpace($json)) {
        throw "Expected JSON output from $ScriptPath"
    }

    return $json | ConvertFrom-Json -Depth 12
}

function Assert-BundleTargetsResolved {
    param(
        [Parameter(Mandatory = $true)]
        $Bundle,
        [switch]$AllowPartialBundle
    )

    $targets = @($Bundle.targets)
    $resolvedTargets = @($targets | Where-Object { $_.status -eq "found" -and $_.path })
    if ($resolvedTargets.Count -eq 0) {
        throw "No attached HTML bundle targets resolved for the fixed-list proof pass."
    }

    if ($AllowPartialBundle) {
        return
    }

    $missingTargets = @($targets | Where-Object { $_.status -ne "found" -or -not $_.path })
    if ($missingTargets.Count -eq 0) {
        return
    }

    $missingSummary = @(
        $missingTargets |
            ForEach-Object { $_.display_name } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    ) -join "; "
    if ([string]::IsNullOrWhiteSpace($missingSummary)) {
        $missingSummary = "$($missingTargets.Count) unresolved target(s)"
    }

    throw (
        "Attached HTML target bundle proof expects the full pinned three-page compatibility set by default. " +
        "Missing: $missingSummary. Pass -AllowPartialBundle only when you intentionally want a narrower proof run."
    )
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$bundleSurfaceCheckPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle_validation_surface.ps1"
$bundleCheckerPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
$fixtureSurfaceCheckPath = Join-Path $PSScriptRoot "check_local_html_fixture_validation_surface.ps1"
$fixtureProbePath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"

foreach ($requiredPath in @($bundleSurfaceCheckPath, $bundleCheckerPath, $fixtureSurfaceCheckPath, $fixtureProbePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required proof helper was not found: $requiredPath"
    }
}

& $bundleSurfaceCheckPath -RepoRoot $resolvedRepoRoot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$bundleCheckerArgs = @{
    RepoRoot = $resolvedRepoRoot
    Json = $true
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $bundleCheckerArgs.InputPath = $InputPath
}

$bundle = Invoke-JsonScript -ScriptPath $bundleCheckerPath -Arguments $bundleCheckerArgs
Assert-BundleTargetsResolved -Bundle $bundle -AllowPartialBundle:$AllowPartialBundle

$resolvedInputPath = @(
    $bundle.targets |
        Where-Object { $_.status -eq "found" -and $_.path } |
        ForEach-Object { $_.path }
)

$fixtureSurfaceArgs = @{
    RepoRoot = $resolvedRepoRoot
    InputPath = $resolvedInputPath
}
& $fixtureSurfaceCheckPath @fixtureSurfaceArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Google issue #3 attached HTML target bundle fixed-list proof"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Locked input count: {0}" -f $resolvedInputPath.Count)
if ($AllowPartialBundle) {
    Write-Host "Bundle completeness policy: partial bundle allowed"
}
if ($AllowMissingLocalAssets) {
    Write-Host "Attached asset policy: degraded mode allowed"
}
Write-Host ""
Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle:$true
Write-Host ""

$probeArgs = @{
    RepoRoot = $resolvedRepoRoot
    FixturePaths = $resolvedInputPath
    Host = $Host
    Port = $Port
}
if ($BrowserExe) {
    $probeArgs.BrowserExe = $BrowserExe
}
if ($AllowMissingLocalAssets) {
    $probeArgs.AllowMissingLocalAssets = $true
}

& $fixtureProbePath @probeArgs
exit $LASTEXITCODE
