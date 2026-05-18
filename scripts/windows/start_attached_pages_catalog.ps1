[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [string]$Bind = "127.0.0.1",
    [int]$Port = 8235,
    [switch]$GoogleStyle,
    [switch]$PrintManifest,
    [switch]$AuditAssets,
    [switch]$AuditAssetsJson,
    [switch]$AllowMissingAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AttachedPagesManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonExePath,
        [Parameter(Mandatory = $true)]
        [string]$ServerPath,
        [Parameter(Mandatory = $true)]
        [string[]]$SelectedInputs
    )

    $manifestArgs = @($ServerPath)
    foreach ($path in $SelectedInputs) {
        $manifestArgs += @("--input", $path)
    }
    $manifestArgs += "--print-manifest"

    $manifestJson = & $PythonExePath @manifestArgs
    if ($LASTEXITCODE -ne 0) {
        throw "attached pages catalog manifest generation failed with exit code $LASTEXITCODE"
    }

    return $manifestJson | ConvertFrom-Json
}

function Get-AttachedPagesAssetAudit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonExePath,
        [Parameter(Mandatory = $true)]
        [string]$ServerPath,
        [Parameter(Mandatory = $true)]
        [string[]]$SelectedInputs
    )

    $auditArgs = @($ServerPath)
    foreach ($path in $SelectedInputs) {
        $auditArgs += @("--input", $path)
    }
    $auditArgs += @("--audit-assets", "--audit-assets-json", "--allow-missing-assets")

    $auditJson = & $PythonExePath @auditArgs
    if ($LASTEXITCODE -ne 0) {
        throw "attached pages catalog asset audit failed with exit code $LASTEXITCODE"
    }

    return $auditJson | ConvertFrom-Json -Depth 12
}

function Show-AttachedPagesAssetWarnings {
    param(
        [Parameter(Mandatory = $true)]
        $AssetAudit,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    if (-not $AssetAudit -or [int]$AssetAudit.fixtures_with_missing_assets -le 0) {
        return
    }

    Write-Warning "Some attached HTML files still have missing local sidecars in the catalog audit. Headed localhost replay may render or behave differently until those files are restored."
    foreach ($fixture in @($AssetAudit.fixtures | Where-Object { [int]$_.missing_asset_count -gt 0 })) {
        Write-Host ("Missing assets: {0}" -f (Convert-ToDisplayPath -Path $fixture.path -RepoRoot $RepoRoot))
        Write-Host ("  Count: {0}" -f $fixture.missing_asset_count)
        foreach ($asset in @($fixture.missing_assets | Select-Object -First 5)) {
            Write-Host ("  - {0}" -f $asset)
        }
        if ([int]$fixture.missing_asset_count -gt 5) {
            Write-Host ("  - ... {0} more" -f ([int]$fixture.missing_asset_count - 5))
        }
    }
    Write-Host ""
}

function Find-ManifestEntryForPath {
    param(
        [Parameter(Mandatory = $true)]
        $Manifest,
        [Parameter(Mandatory = $true)]
        [string]$PreferredPath
    )

    $preferredLeaf = Split-Path -Leaf $PreferredPath
    foreach ($entry in $Manifest) {
        if ($entry.file -eq $preferredLeaf -or $entry.file -like "*/$preferredLeaf") {
            return $entry
        }
    }

    return $null
}

if ($PrintManifest -and $AuditAssets) {
    throw "Choose either -PrintManifest or -AuditAssets. The attached-pages helper cannot print the manifest and run the asset audit in the same invocation."
}
if ($AuditAssetsJson -and -not $AuditAssets) {
    throw "-AuditAssetsJson requires -AuditAssets."
}
if ($AllowMissingAssets -and -not $AuditAssets) {
    throw "-AllowMissingAssets is only supported with -AuditAssets."
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$serverPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/attached_pages_server.py"
if (-not (Test-Path -LiteralPath $serverPath -PathType Leaf)) {
    throw "attached pages catalog server not found: $serverPath"
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source
$resolvedInputPath = if ($PSCmdlet.ParameterSetName -eq "InputPath") {
    @(Get-ResolvedExplicitBundleInputPaths -InputPath $InputPath)
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle:$GoogleStyle
}
if (-not $resolvedInputPath -or $resolvedInputPath.Count -eq 0) {
    throw "No attached HTML inputs were resolved for the catalog server."
}

$resolvedPreferredInitialPage = if ($GoogleStyle) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}
$preferredManifestEntry = $null
if ($resolvedPreferredInitialPage -and -not $PrintManifest -and -not $AuditAssets) {
    $manifest = Get-AttachedPagesManifest -PythonExePath $resolvedPython -ServerPath $serverPath -SelectedInputs $resolvedInputPath
    $preferredManifestEntry = Find-ManifestEntryForPath -Manifest $manifest -PreferredPath $resolvedPreferredInitialPage
}

$serverArgs = @($serverPath)
foreach ($path in $resolvedInputPath) {
    $serverArgs += @("--input", $path)
}

if ($PrintManifest) {
    $serverArgs += "--print-manifest"
} elseif ($AuditAssets) {
    $serverArgs += "--audit-assets"
    if ($AuditAssetsJson) {
        $serverArgs += "--audit-assets-json"
    }
    if ($AllowMissingAssets) {
        $serverArgs += "--allow-missing-assets"
    }
} else {
    $serverArgs += @("--bind", $Bind, "--port", "$Port")
}

if (-not $PrintManifest -and -not $AuditAssets) {
    $attachedAssetAudit = Get-AttachedPagesAssetAudit -PythonExePath $resolvedPython -ServerPath $serverPath -SelectedInputs $resolvedInputPath

    Write-Host "Attached pages catalog"
    Write-Host ""
    Write-Host ("Mode: {0}" -f $(if ($GoogleStyle) { "google-style auto-discovery" } elseif ($PSCmdlet.ParameterSetName -eq "InputPath") { "explicit pinned inputs" } else { "auto-discovery" }))
    Write-Host ("Inputs pinned: {0}" -f $resolvedInputPath.Count)
    Write-Host ("Bind: http://{0}:{1}/" -f $Bind, $Port)
    Write-Host "Routes: /, /manifest.json, /audit.json, /audit.txt, /pages/<n>, /named/<slug>, /raw/..."
    if ($resolvedPreferredInitialPage) {
        Write-Host ("Preferred Google-style page: {0}" -f $resolvedPreferredInitialPage)
    }
    if ($preferredManifestEntry) {
        Write-Host ("Preferred route: http://{0}:{1}{2}/" -f $Bind, $Port, $preferredManifestEntry.route)
        Write-Host ("Preferred alias route: http://{0}:{1}{2}/" -f $Bind, $Port, $preferredManifestEntry.alias_route)
        Write-Host ("Preferred named route: http://{0}:{1}{2}/" -f $Bind, $Port, $preferredManifestEntry.slug_route)
    }
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle:$GoogleStyle
    Write-Host ""
    Show-AttachedPagesAssetWarnings -AssetAudit $attachedAssetAudit -RepoRoot $resolvedRepoRoot
}

& $resolvedPython @serverArgs
exit $LASTEXITCODE
