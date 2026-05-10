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

function Normalize-RelativeHtmlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = ($Path -replace "\\", "/").Trim()
    while ($normalized.StartsWith("./")) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized.TrimStart('/')
}

function Get-RelativeHtmlUrlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = Normalize-RelativeHtmlPath -Path $Path
    $encodedSegments = foreach ($segment in ($normalized -split "/")) {
        if ($segment -ne "") {
            [System.Uri]::EscapeDataString($segment)
        }
    }
    return ($encodedSegments -join "/")
}

function Get-HtmlEncodedText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Write-StagedIndexPage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StageRoot,
        [Parameter(Mandatory = $true)]
        [object[]]$Entries,
        [Parameter(Mandatory = $true)]
        [string]$ManifestRelativePath
    )

    $listItems = foreach ($entry in ($Entries | Sort-Object staged_relative_path)) {
        $relativePath = [string]$entry.staged_relative_path
        $href = Get-RelativeHtmlUrlPath -Path $relativePath
        $displayPath = Get-HtmlEncodedText -Text $relativePath
        $sourceLabel = switch ([string]$entry.source_kind) {
            "directory_html" { "staged from a directory input" }
            "standalone_html" { "staged from a standalone file" }
            default { [string]$entry.source_kind }
        }
        $encodedSourceLabel = Get-HtmlEncodedText -Text $sourceLabel
        $encodedSourcePath = Get-HtmlEncodedText -Text ([string]$entry.source_path)
@"
      <li>
        <a href="$href">$displayPath</a>
        <p>$encodedSourceLabel</p>
        <code>$encodedSourcePath</code>
      </li>
"@
    }

    $manifestHref = Get-RelativeHtmlUrlPath -Path $ManifestRelativePath
    $entryCount = $Entries.Count
    $manifestLabel = Get-HtmlEncodedText -Text $ManifestRelativePath
    $listMarkup = $listItems -join "`r`n"
    $indexContent = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Staged localhost HTML validation</title>
  <style>
    :root {
      color-scheme: light dark;
      font-family: "Segoe UI", sans-serif;
    }
    body {
      margin: 0;
      background: #f3f4f6;
      color: #111827;
    }
    main {
      max-width: 960px;
      margin: 0 auto;
      padding: 32px 20px 48px;
    }
    h1 {
      margin: 0 0 12px;
      font-size: 2rem;
    }
    p {
      line-height: 1.55;
    }
    ul {
      list-style: none;
      padding: 0;
      margin: 24px 0;
      display: grid;
      gap: 14px;
    }
    li {
      background: #ffffff;
      border: 1px solid #d1d5db;
      border-radius: 8px;
      padding: 16px 18px;
    }
    a {
      color: #0f4c81;
      font-weight: 600;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    code {
      display: block;
      margin-top: 10px;
      white-space: pre-wrap;
      word-break: break-word;
      font-size: 0.92rem;
      color: #374151;
    }
    .manifest {
      margin-top: 20px;
      font-size: 0.95rem;
    }
  </style>
</head>
<body>
  <main>
    <h1>Staged localhost HTML validation</h1>
    <p>This landing page was generated for the headed saved-page follow-up. It keeps the staged HTML inputs together so you can move through the attached pages in one headed session.</p>
    <p>Staged pages: $entryCount</p>
    <ul>
$listMarkup
    </ul>
    <p class="manifest">Manifest: <a href="$manifestHref">$manifestLabel</a></p>
  </main>
</body>
</html>
"@

    $indexPath = Join-Path $StageRoot "index.html"
    Set-Content -Path $indexPath -Value $indexContent -Encoding Ascii
    return "index.html"
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

$manifestRelativePath = "staged-input-manifest.json"
$generatedIndexPage = Write-StagedIndexPage -StageRoot $stageRoot -Entries $stagedEntries -ManifestRelativePath $manifestRelativePath
if (-not $stagedInitialPage) {
    $stagedInitialPage = $generatedIndexPage
}

$manifestPath = Join-Path $stageRoot $manifestRelativePath
$manifest = [pscustomobject]@{
    staged_root = $stageRoot
    created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    entry_count = $stagedEntries.Count
    generated_index_page = $generatedIndexPage
    entries = $stagedEntries
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding Ascii

Write-Host ("Staged HTML validation root: {0}" -f $stageRoot)
Write-Host ("Generated staged index: {0}" -f (Join-Path $stageRoot $generatedIndexPage))
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
