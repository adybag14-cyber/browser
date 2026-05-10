[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputPath,

    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InitialPage,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$LaunchBrowser,
    [switch]$Wait,
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-HtmlFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetExtension($Path) -in @(".html", ".htm")
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

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}

$helperPath = Join-Path $scriptRoot "start_localhost_html_validation.ps1"
if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "localhost helper not found: $helperPath"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\manual-user\localhost-html-validation"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$stageRoot = Join-Path $artifactRoot ("staged-inputs-" + (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

$resolvedInitialSource = $null
if ($InitialPage -and (Test-Path -LiteralPath $InitialPage -PathType Leaf)) {
    $resolvedInitialSource = (Resolve-Path -LiteralPath $InitialPage).Path
}

$stagedInitialPage = $null
$stagedEntries = @()

foreach ($input in $InputPath) {
    $resolvedInput = (Resolve-Path -LiteralPath $input).Path
    $item = Get-Item -LiteralPath $resolvedInput

    if ($item.PSIsContainer) {
        $targetDir = Get-UniqueChildPath -Parent $stageRoot -LeafName $item.Name
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

        Get-ChildItem -LiteralPath $resolvedInput -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $targetDir -Recurse -Force
        }

        $htmlFiles = Get-ChildItem -LiteralPath $resolvedInput -Recurse -File |
            Where-Object { Test-HtmlFilePath -Path $_.FullName } |
            Sort-Object FullName

        foreach ($htmlFile in $htmlFiles) {
            $relativeWithinInput = Get-ForwardRelativePath -Root $resolvedInput -Path $htmlFile.FullName
            $stagedRelativePath = ((Join-Path (Split-Path -Leaf $targetDir) $relativeWithinInput) -replace "\\", "/")
            $stagedEntries += [pscustomobject]@{
                source_path = $htmlFile.FullName
                staged_relative_path = $stagedRelativePath
                source_kind = "directory_html"
            }

            if ($resolvedInitialSource -and [string]::Equals($htmlFile.FullName, $resolvedInitialSource, [System.StringComparison]::OrdinalIgnoreCase)) {
                $stagedInitialPage = $stagedRelativePath
            }
        }

        continue
    }

    if (-not (Test-HtmlFilePath -Path $item.FullName)) {
        throw "standalone inputs must be .html or .htm files: $resolvedInput"
    }

    $targetFile = Get-UniqueChildPath -Parent $stageRoot -LeafName $item.Name
    Copy-Item -LiteralPath $item.FullName -Destination $targetFile -Force

    $stagedRelativePath = Split-Path -Leaf $targetFile
    $stagedEntries += [pscustomobject]@{
        source_path = $item.FullName
        staged_relative_path = $stagedRelativePath
        source_kind = "standalone_html"
    }

    if ($resolvedInitialSource -and [string]::Equals($item.FullName, $resolvedInitialSource, [System.StringComparison]::OrdinalIgnoreCase)) {
        $stagedInitialPage = $stagedRelativePath
    }
}

if ($stagedEntries.Count -eq 0) {
    throw "no HTML files were staged from the provided input paths"
}

if (-not $stagedInitialPage -and $InitialPage) {
    $stagedInitialPage = $InitialPage
}

$manifestPath = Join-Path $stageRoot "staged-input-manifest.json"
$manifest = [pscustomobject]@{
    staged_root = $stageRoot
    created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    entry_count = $stagedEntries.Count
    entries = $stagedEntries
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding Ascii

Write-Host ("Staged HTML validation root: {0}" -f $stageRoot)
Write-Host ("Staged input manifest: {0}" -f $manifestPath)

$helperArgs = @{
    PageRoot = $stageRoot
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
}

if ($BrowserExe) {
    $helperArgs["BrowserExe"] = $BrowserExe
}
if ($stagedInitialPage) {
    $helperArgs["InitialPage"] = $stagedInitialPage
}
if ($LaunchBrowser) {
    $helperArgs["LaunchBrowser"] = $true
}
if ($Wait) {
    $helperArgs["Wait"] = $true
}
if ($LeaveServerRunning) {
    $helperArgs["LeaveServerRunning"] = $true
}

& $helperPath @helperArgs
