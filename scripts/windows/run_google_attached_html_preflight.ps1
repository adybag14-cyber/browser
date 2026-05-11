[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-GoogleAttachedHtmlPreflightMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName,
        [string[]]$ResolvedInputPath,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckCommand,
        [Parameter(Mandatory = $true)]
        [string]$AssetClosureCommand,
        [Parameter(Mandatory = $true)]
        [string]$FlowCommand,
        [Parameter(Mandatory = $true)]
        [string]$RunnerCommand
    )

    $parameterMode = switch ($ParameterSetName) {
        "InputPath" { "explicit input path" }
        default { "auto-discovered attached HTML" }
    }

    return [ordered]@{
        parameter_mode = $parameterMode
        input_count = @($ResolvedInputPath).Count
        resolved_input_path = @($ResolvedInputPath)
        preferred_initial_page = $ResolvedPreferredInitialPage
        surface_check_command = $SurfaceCheckCommand
        asset_closure_command = $AssetClosureCommand
        flow_command = $FlowCommand
        runner_command = $RunnerCommand
        search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }
    }
}

$surfaceChecker = Join-Path $PSScriptRoot "check_google_attached_html_validation_surface.ps1"
$assetClosureChecker = Join-Path $PSScriptRoot "check_attached_html_local_asset_closure.ps1"
if (-not (Test-Path -LiteralPath $surfaceChecker -PathType Leaf)) {
    throw "Google-style attached HTML surface checker not found: $surfaceChecker"
}
if (-not (Test-Path -LiteralPath $assetClosureChecker -PathType Leaf)) {
    throw "Attached HTML asset-closure checker not found: $assetClosureChecker"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$resolvedInputPath = switch ($PSCmdlet.ParameterSetName) {
    "InputPath" { @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }) }
    default { Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle }
}

$autoGoogleStyleFixture = if ($PSCmdlet.ParameterSetName -eq "Auto") {
    $resolvedInputPath |
        ForEach-Object { Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue } |
        Where-Object { $_ -and (Test-GoogleStyleFixture $_) } |
        Select-Object -First 1
} else {
    $null
}

if ($PSCmdlet.ParameterSetName -eq "Auto" -and -not $autoGoogleStyleFixture) {
    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $resolvedRepoRoot)
    throw "No Google-style attached HTML files were found under: $($searchRoots -join '; '). Use .\\scripts\\windows\\show_attached_html_validation_flow.ps1 for the general attached-page flow, or pass -InputPath to override auto-discovery."
}

$resolvedPreferredInitialPage = if ($resolvedInputPath.Count -gt 0) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}

$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1"
$quotedInputPaths = @(
    $resolvedInputPath | ForEach-Object {
        "'" + ($_.Replace("'", "''")) + "'"
    }
)
$assetClosureCommand = if ($quotedInputPaths.Count -gt 0) {
    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle -InputPath " + ($quotedInputPaths -join " ")
} else {
    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
}
$flowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
$runnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait"

$surfaceCheckArgs = @{ RepoRoot = $resolvedRepoRoot }
if ($Json) {
    $surfaceCheckArgs.Json = $true
    $surfaceCheckJson = (& $surfaceChecker @surfaceCheckArgs) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $surfaceCheckSummary = $surfaceCheckJson | ConvertFrom-Json -Depth 10
} else {
    & $surfaceChecker @surfaceCheckArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host ""
}

$assetClosureArgs = @{
    RepoRoot = $resolvedRepoRoot
    GoogleStyle = $true
    InputPath = $resolvedInputPath
}
if ($Json) {
    $assetClosureArgs.Json = $true
    $assetClosureJson = (& $assetClosureChecker @assetClosureArgs) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $assetClosureSummary = $assetClosureJson | ConvertFrom-Json -Depth 10
} else {
    & $assetClosureChecker @assetClosureArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host ""
}

$preflightMetadata = Get-GoogleAttachedHtmlPreflightMetadata `
    -RepoRoot $resolvedRepoRoot `
    -ParameterSetName $PSCmdlet.ParameterSetName `
    -ResolvedInputPath $resolvedInputPath `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -SurfaceCheckCommand $surfaceCheckCommand `
    -AssetClosureCommand $assetClosureCommand `
    -FlowCommand $flowCommand `
    -RunnerCommand $runnerCommand

if ($Json) {
    [ordered]@{
        google_attached_html_preflight = $preflightMetadata
        surface_check = $surfaceCheckSummary
        asset_closure = $assetClosureSummary
    } | ConvertTo-Json -Depth 10
    exit 0
}

Write-Host "Google attached HTML preflight"
Write-Host ""
Write-Host "Mode: Google-style attached HTML follow-up preflight"
Write-Host ("Mode detail: {0}" -f $preflightMetadata.parameter_mode)
if ($preflightMetadata.search_roots.Count -gt 0) {
    Write-Host "Search roots:"
    foreach ($root in $preflightMetadata.search_roots) {
        Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $resolvedRepoRoot))
    }
}
if ($resolvedInputPath.Count -gt 0) {
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot
}
if ($resolvedPreferredInitialPage) {
    Write-Host ""
    Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
}
Write-Host ""
Write-Host "Preflight checks passed. Next commands:"
Write-Host ("- {0}" -f $flowCommand)
Write-Host ("- {0}" -f $runnerCommand)
