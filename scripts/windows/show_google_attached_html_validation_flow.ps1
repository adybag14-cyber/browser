[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$Json,
    [switch]$LeaveOpen,
    [switch]$AllowMissingLocalAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AssetClosureCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName,
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [bool]$AllowMissingLocalAssets
    )

    $base = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle"
    if ($AllowMissingLocalAssets) {
        $base += " -AllowMissingAssets"
    }
    switch ($ParameterSetName) {
        "InputPath" {
            if (-not $ResolvedInputPath -or $ResolvedInputPath.Count -eq 0) {
                return $base
            }

            $quotedPathArgs = @(
                $ResolvedInputPath | ForEach-Object {
                    "'" + ($_.Replace("'", "''")) + "'"
                }
            )
            return ($base + " -InputPath " + ($quotedPathArgs -join " "))
        }
        "Auto" {
            return $base
        }
        default {
            return $null
        }
    }
}

function Get-GoogleAttachedHtmlHandoffCommands {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName,
        [string]$ResolvedPageRoot,
        [string[]]$ResolvedInputPath,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [bool]$LeaveOpen,
        [Parameter(Mandatory = $true)]
        [bool]$AllowMissingLocalAssets
    )

    $helperCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle -Port $Port"
    $runnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Port $Port -Wait"

    if ($ResolvedPreferredInitialPage) {
        $quotedPreferredInitialPage = ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedPreferredInitialPage
        $helperCommand += " -PreferredInitialPage $quotedPreferredInitialPage"
        $runnerCommand += " -PreferredInitialPage $quotedPreferredInitialPage"
    }
    if ($LeaveOpen) {
        $helperCommand += " -LeaveOpen"
        $runnerCommand += " -LeaveServerRunning"
    }
    if ($AllowMissingLocalAssets) {
        $runnerCommand += " -AllowMissingLocalAssets"
    }

    switch ($ParameterSetName) {
        "PageRoot" {
            if ($ResolvedPageRoot) {
                $quotedPageRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedPageRoot
                $helperCommand += " -PageRoot $quotedPageRoot"
                $runnerCommand += " -PageRoot $quotedPageRoot"
            }
        }
        default {
            if ($ResolvedInputPath -and $ResolvedInputPath.Count -gt 0) {
                $quotedPathArgs = @(
                    $ResolvedInputPath | ForEach-Object {
                        ConvertTo-PowerShellSingleQuotedLiteral -Value $_
                    }
                )
                $joinedPathArgs = $quotedPathArgs -join ", "
                $helperCommand += " -InputPath $joinedPathArgs"
                $runnerCommand += " -InputPath $joinedPathArgs"
            }
        }
    }

    return [ordered]@{
        helper_command = $helperCommand
        runner_command = $runnerCommand
    }
}

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
        [object[]]$MissingAssetAudit,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckCommand,
        [string]$AssetClosureCommand,
        [Parameter(Mandatory = $true)]
        [string]$HelperCommand,
        [Parameter(Mandatory = $true)]
        [string]$RunnerCommand,
        [Parameter(Mandatory = $true)]
        [bool]$AllowMissingLocalAssets
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
        allow_missing_local_assets = $AllowMissingLocalAssets
        leave_open = $LeaveOpen
        port = $Port
        surface_check_command = $SurfaceCheckCommand
        asset_closure_command = $AssetClosureCommand
        helper_command = $HelperCommand
        runner_command = $RunnerCommand
        missing_asset_audit = $normalizedAssetAudit
        search_roots = if ($ParameterSetName -eq "Auto") { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) } else { @() }
    }
}

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
$helper = Join-Path $PSScriptRoot "show_saved_page_google_validation_flow.ps1"
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1"
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
$assetClosureCommand = Get-AssetClosureCommand -ParameterSetName $PSCmdlet.ParameterSetName -ResolvedInputPath $resolvedInputPath -AllowMissingLocalAssets ([bool]$AllowMissingLocalAssets)
$handoffCommands = Get-GoogleAttachedHtmlHandoffCommands `
    -ParameterSetName $PSCmdlet.ParameterSetName `
    -ResolvedPageRoot $resolvedPageRoot `
    -ResolvedInputPath $resolvedInputPath `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -Port $Port `
    -LeaveOpen ([bool]$LeaveOpen) `
    -AllowMissingLocalAssets ([bool]$AllowMissingLocalAssets)

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
    throw "No Google-style attached HTML files were found under: $($searchRoots -join '; '). Use .\\scripts\\windows\\show_attached_html_validation_flow.ps1 for the general attached-page flow, or pass -InputPath / -PageRoot to override auto-discovery."
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
    -MissingAssetAudit $attachedAssetAudit `
    -SurfaceCheckCommand $surfaceCheckCommand `
    -AssetClosureCommand $assetClosureCommand `
    -HelperCommand $handoffCommands.helper_command `
    -RunnerCommand $handoffCommands.runner_command `
    -AllowMissingLocalAssets ([bool]$AllowMissingLocalAssets)

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
    Write-Host ""
    if ($assetClosureCommand) {
        Write-Host "Start with the dedicated surface check and deep asset-closure audit before the printed flow or runner:"
        Write-Host ("- {0}" -f $surfaceCheckCommand)
        Write-Host ("- {0}" -f $assetClosureCommand)
    } else {
        Write-Host "Start with the dedicated surface check before the printed flow or runner:"
        Write-Host ("- {0}" -f $surfaceCheckCommand)
        Write-Host "- Deep asset-closure audit is skipped in explicit page-root mode."
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
    if ($AllowMissingLocalAssets) {
        Write-Host "Attached asset policy: degraded mode allowed"
    }
    Write-Host "Override: use -PreferredInitialPage to keep one Google-like page first, or pass -PageRoot / -InputPath to skip auto-discovery."
    Write-Host ("Helper: {0}" -f $handoffCommands.helper_command)
    Write-Host ("Runner: {0}" -f $handoffCommands.runner_command)
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
