[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-SafeSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [int]$FallbackIndex = 1
    )

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormKD)
    $builder = [System.Text.StringBuilder]::new()
    $previousHyphen = $false
    foreach ($char in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -eq [Globalization.UnicodeCategory]::NonSpacingMark) {
            continue
        }

        if (($char -ge 'a' -and $char -le 'z') -or ($char -ge 'A' -and $char -le 'Z') -or ($char -ge '0' -and $char -le '9')) {
            [void]$builder.Append([char]::ToLowerInvariant($char))
            $previousHyphen = $false
            continue
        }

        if (-not $previousHyphen) {
            [void]$builder.Append('-')
            $previousHyphen = $true
        }
    }

    $slug = $builder.ToString().Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "saved-page-$FallbackIndex"
    }

    return $slug
}

function Get-UniqueChildPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Parent,
        [Parameter(Mandatory = $true)]
        [string]$LeafName
    )

    $candidate = Join-Path $Parent $LeafName
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $base = [System.IO.Path]::GetFileNameWithoutExtension($LeafName)
    $extension = [System.IO.Path]::GetExtension($LeafName)
    if ([string]::IsNullOrEmpty($base)) {
        $base = $LeafName
    }

    $index = 2
    while ($true) {
        $candidate = Join-Path $Parent ("{0}-{1}{2}" -f $base, $index, $extension)
        if (-not (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
        $index += 1
    }
}

function Get-ForwardRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ([System.IO.Path]::GetRelativePath(
            [System.IO.Path]::GetFullPath($Root),
            [System.IO.Path]::GetFullPath($Path)
        ) -replace "\\", "/")
}

function Test-HtmlFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetExtension($Path) -in @(".html", ".htm")
}

function New-StagedDirectoryName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Parent,
        [Parameter(Mandatory = $true)]
        [string]$SourceName,
        [int]$FallbackIndex
    )

    $slug = ConvertTo-SafeSlug -Value $SourceName -FallbackIndex $FallbackIndex
    return Split-Path -Leaf (Get-UniqueChildPath -Parent $Parent -LeafName $slug)
}

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}

$runnerPath = Join-Path $scriptRoot "run_saved_page_localhost_validation.ps1"
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "saved-page localhost validation runner not found: $runnerPath"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\manual-user\localhost-html-validation"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
$stageRoot = Join-Path $artifactRoot ("sanitized-inputs-" + (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

$resolvedPreferredSource = $null
if ($PreferredInitialPage -and (Test-Path -LiteralPath $PreferredInitialPage -PathType Leaf)) {
    $resolvedPreferredSource = (Resolve-Path -LiteralPath $PreferredInitialPage).Path
}

$manifestEntries = @()
$resolvedPreferredStagedPage = $null
$inputIndex = 0

foreach ($input in $InputPath) {
    $inputIndex += 1
    $resolvedInput = (Resolve-Path -LiteralPath $input).Path
    $item = Get-Item -LiteralPath $resolvedInput

    if ($item.PSIsContainer) {
        $stagedDirName = New-StagedDirectoryName -Parent $stageRoot -SourceName $item.Name -FallbackIndex $inputIndex
        $targetDir = Join-Path $stageRoot $stagedDirName
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

        Get-ChildItem -LiteralPath $resolvedInput -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $targetDir -Recurse -Force
        }

        if ($resolvedPreferredSource) {
            $matchedHtml = Get-ChildItem -LiteralPath $resolvedInput -Recurse -File |
                Where-Object { Test-HtmlFilePath -Path $_.FullName } |
                Where-Object { [string]::Equals($_.FullName, $resolvedPreferredSource, [System.StringComparison]::OrdinalIgnoreCase) } |
                Select-Object -First 1
            if ($matchedHtml) {
                $relativeWithinInput = Get-ForwardRelativePath -Root $resolvedInput -Path $matchedHtml.FullName
                $resolvedPreferredStagedPage = ((Join-Path $stagedDirName $relativeWithinInput) -replace "\\", "/")
            }
        }

        $manifestEntries += [pscustomobject]@{
            source_path = $resolvedInput
            staged_path = $targetDir
            source_kind = "directory"
        }
        continue
    }

    if (-not (Test-HtmlFilePath -Path $item.FullName)) {
        throw "standalone inputs must be .html or .htm files: $resolvedInput"
    }

    $sourceStem = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
    $safeStem = ConvertTo-SafeSlug -Value $sourceStem -FallbackIndex $inputIndex
    $targetFile = Get-UniqueChildPath -Parent $stageRoot -LeafName ($safeStem + $item.Extension.ToLowerInvariant())
    $targetStem = [System.IO.Path]::GetFileNameWithoutExtension($targetFile)
    $htmlContent = Get-Content -LiteralPath $item.FullName -Raw

    $siblingAssetDirs = @(Get-ChildItem -LiteralPath $item.DirectoryName -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -like "$sourceStem*_files*"
    })

    $assetMappings = @()
    $assetIndex = 0
    foreach ($assetDir in $siblingAssetDirs) {
        $assetIndex += 1
        $targetAssetLeaf = if ($assetIndex -eq 1) {
            "$targetStem`_files"
        } else {
            "$targetStem-$assetIndex`_files"
        }
        $targetAssetDir = Join-Path $stageRoot $targetAssetLeaf
        Copy-Item -LiteralPath $assetDir.FullName -Destination $targetAssetDir -Recurse -Force
        $assetMappings += [pscustomobject]@{
            source_name = $assetDir.Name
            target_name = $targetAssetLeaf
        }
    }

    foreach ($mapping in $assetMappings) {
        $htmlContent = $htmlContent.Replace([string]$mapping.source_name, [string]$mapping.target_name)
    }

    Set-Content -LiteralPath $targetFile -Value $htmlContent -Encoding utf8

    if ($resolvedPreferredSource -and [string]::Equals($item.FullName, $resolvedPreferredSource, [System.StringComparison]::OrdinalIgnoreCase)) {
        $resolvedPreferredStagedPage = Split-Path -Leaf $targetFile
    }

    $manifestEntries += [pscustomobject]@{
        source_path = $resolvedInput
        staged_path = $targetFile
        source_kind = "standalone_html"
        asset_mappings = $assetMappings
    }
}

if (-not $resolvedPreferredStagedPage -and $PreferredInitialPage -and -not (Test-Path -LiteralPath $PreferredInitialPage -PathType Leaf)) {
    $preferredLeaf = Split-Path -Leaf $PreferredInitialPage
    $matchedEntry = $manifestEntries | Where-Object {
        (Split-Path -Leaf ([string]$_.source_path)) -eq $preferredLeaf
    } | Select-Object -First 1
    if ($matchedEntry) {
        $resolvedPreferredStagedPage = Split-Path -Leaf ([string]$matchedEntry.staged_path)
    }
}

$manifestPath = Join-Path $stageRoot "sanitized-input-manifest.json"
[pscustomobject]@{
    created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    input_count = $manifestEntries.Count
    stage_root = $stageRoot
    preferred_initial_page = $resolvedPreferredStagedPage
    entries = $manifestEntries
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Write-Host ("Sanitized saved-page stage root: {0}" -f $stageRoot)
Write-Host ("Sanitized input manifest: {0}" -f $manifestPath)
if ($resolvedPreferredStagedPage) {
    Write-Host ("Preferred staged page: {0}" -f $resolvedPreferredStagedPage)
}
Write-Host ""

$runnerArgs = @{
    PageRoot = $stageRoot
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
}
if ($BrowserExe) {
    $runnerArgs["BrowserExe"] = $BrowserExe
}
if ($resolvedPreferredStagedPage) {
    $runnerArgs["PreferredInitialPage"] = $resolvedPreferredStagedPage
}
if ($SummaryOnly) {
    $runnerArgs["SummaryOnly"] = $true
}
if ($Wait) {
    $runnerArgs["Wait"] = $true
}
if ($LeaveServerRunning) {
    $runnerArgs["LeaveServerRunning"] = $true
}

& $runnerPath @runnerArgs
