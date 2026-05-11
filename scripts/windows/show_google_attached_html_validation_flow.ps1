[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$Json,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-GoogleAttachedHtmlFlowMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName,
        [string]$PageRoot,
        [string[]]$ResolvedInputPath,
        [string]$PreferredInitialPage,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [bool]$LeaveOpen,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [object[]]$MissingAssetAudit
    )

    $parameterMode = switch ($ParameterSetName) {
        "PageRoot" { "explicit page root" }
        "InputPath" { "explicit input path" }
        default { "auto-discovered attached HTML" }
    }

    $preferredInitialPageMode = if ($PreferredInitialPage) {
        "explicit"
    } elseif ($ResolvedPreferredInitialPage) {
        if ($ParameterSetName -eq "PageRoot") { "page-root-auto" } else { "google-style-auto" }
    } else {
        if ($ParameterSetName -eq "PageRoot") { "page-root-default" } else { "saved-page-summary-auto" }
    }

    $normalizedAssetAudit = @(
        $MissingAssetAudit | ForEach-Object {
            [ordered]@{
                path = $_.path
                missing_assets = @($_.missing_assets)
                missing_asset_count = $_.missing_asset_count
            }
        }
    )

    return [ordered]@{
        parameter_mode = $parameterMode
        page_root = $PageRoot
        input_count = @($ResolvedInputPath).Count
        resolved_input_path = @($ResolvedInputPath)
        preferred_initial_page = $ResolvedPreferredInitialPage
        preferred_initial_page_mode = $preferredInitialPageMode
        validation_mode = "google-style"
        leave_open = $LeaveOpen
        port = $Port
        missing_asset_audit = $normalizedAssetAudit
        search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }
    }
}

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
$helper = Join-Path $PSScriptRoot "show_saved_page_google_validation_flow.ps1"
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    throw "Google-style attached HTML flow helper not found: $helper"
}

$resolvedPageRoot = if ($PageRoot) {
    (Resolve-Path -LiteralPath $PageRoot).Path
} else {
    $null
}
$resolvedInputPath = switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" { @() }
    "InputPath" { @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }) }
    default { Get-DefaultAttachedHtmlInputPath -RepoRoot $repoRoot -GoogleStyle }
}
$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    if ($PSCmdlet.ParameterSetName -eq "PageRoot") {
        $PreferredInitialPage
    } else {
        Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
    }
} elseif ($PSCmdlet.ParameterSetName -eq "PageRoot") {
    $null
} else {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
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
    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $repoRoot)
    throw "No Google-style attached HTML files were found under: $($searchRoots -join '; '). Use .\scripts\windows\show_attached_html_validation_flow.ps1 for the general attached-page flow, or pass -InputPath / -PageRoot to override auto-discovery."
}

$attachedAssetAudit = if ($PSCmdlet.ParameterSetName -eq "PageRoot") {
    @()
} else {
    @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath)
}

$arguments = @{
    Port = $Port
    ManualGoogleStyle = $true
}
if ($resolvedPreferredInitialPage) {
    $arguments.PreferredInitialPage = $resolvedPreferredInitialPage
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

$googleAttachedHtmlMetadata = Get-GoogleAttachedHtmlFlowMetadata `
    -RepoRoot $repoRoot `
    -ParameterSetName $PSCmdlet.ParameterSetName `
    -PageRoot $resolvedPageRoot `
    -ResolvedInputPath $resolvedInputPath `
    -PreferredInitialPage $PreferredInitialPage `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -LeaveOpen ([bool]$LeaveOpen) `
    -Port $Port `
    -MissingAssetAudit $attachedAssetAudit

if (-not $Json) {
    Write-Host "Google-style attached HTML validation flow"
    Write-Host ""
    Write-Host "Mode: attached HTML auto-discovery with the Google-style localhost follow-up"
    switch ($PSCmdlet.ParameterSetName) {
        "PageRoot" {
            Write-Host ("Mode detail: explicit page root ({0})" -f $resolvedPageRoot)
        }
        "InputPath" {
            Write-Host ("Mode detail: explicit saved HTML inputs ({0})" -f $resolvedInputPath.Count)
        }
        default {
            Write-Host ("Mode detail: auto-discovered attached HTML inputs ({0}) locked before the Google-style follow-up." -f $resolvedInputPath.Count)
        }
    }
    if ($PSCmdlet.ParameterSetName -eq "Auto" -and $googleAttachedHtmlMetadata.search_roots.Count -gt 0) {
        Write-Host "Search roots:"
        foreach ($root in $googleAttachedHtmlMetadata.search_roots) {
            Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $repoRoot))
        }
    }
    if ($resolvedInputPath.Count -gt 0) {
        Write-Host ""
        Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $repoRoot
        Show-MissingLocalFixtureAssetWarnings -AssetAudit $attachedAssetAudit -RepoRoot $repoRoot
    }
    if ($resolvedPreferredInitialPage) {
        Write-Host ""
        if ($PreferredInitialPage) {
            Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
        } else {
            Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
        }
    }
    Write-Host "Override: use -PreferredInitialPage to keep one Google-like page first, or pass -PageRoot / -InputPath to skip auto-discovery."
    Write-Host "Helper: .\scripts\windows\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle"
    Write-Host ""
}

if ($Json) {
    $arguments.Json = $true
    switch ($PSCmdlet.ParameterSetName) {
        "PageRoot" {
            $helperJson = (& $helper @arguments -PageRoot $resolvedPageRoot) -join [Environment]::NewLine
        }
        default {
            $helperJson = (& $helper @arguments -InputPath $resolvedInputPath) -join [Environment]::NewLine
        }
    }

    $result = [ordered]@{
        google_attached_html = $googleAttachedHtmlMetadata
        missing_asset_audit = $attachedAssetAudit
        flow = $helperJson | ConvertFrom-Json -Depth 10
    }
    $result | ConvertTo-Json -Depth 10
    exit $LASTEXITCODE
}

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        & $helper @arguments -PageRoot $resolvedPageRoot
        exit $LASTEXITCODE
    }
    default {
        & $helper @arguments -InputPath $resolvedInputPath
        exit $LASTEXITCODE
    }
}
