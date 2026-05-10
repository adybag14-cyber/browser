[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PageRoot,

    [string]$RepoRoot,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Get-RegexMatchCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    return [System.Text.RegularExpressions.Regex]::Matches(
        $Content,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    ).Count
}

function Get-HtmlTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $titleMatch = [System.Text.RegularExpressions.Regex]::Match(
        $Content,
        "<title\b[^>]*>(.*?)</title>",
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $titleMatch.Success) {
        return ""
    }

    $decoded = [System.Net.WebUtility]::HtmlDecode($titleMatch.Groups[1].Value)
    return ($decoded -replace "\s+", " ").Trim()
}

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$resolvedPageRoot = (Resolve-Path -LiteralPath $PageRoot).Path
if (-not (Test-Path -LiteralPath $resolvedPageRoot -PathType Container)) {
    throw "page root must be a directory: $PageRoot"
}

if ($Port -lt 0 -or $Port -gt 65535) {
    throw "port must be between 0 and 65535"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\manual-user\localhost-html-validation"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

if (-not $OutputPath) {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
    $OutputPath = Join-Path $artifactRoot ("page-summary-" + $timestamp + ".json")
}

$htmlFiles = Get-ChildItem -LiteralPath $resolvedPageRoot -Recurse -File |
    Where-Object { $_.Extension -in @(".html", ".htm") } |
    Sort-Object FullName

if ($htmlFiles.Count -eq 0) {
    throw "no .html or .htm files were found under $resolvedPageRoot"
}

$pageSummaries = @($htmlFiles | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw
    $relativePath = Get-ForwardRelativePath -Root $resolvedPageRoot -Path $_.FullName
    $urlPath = Get-RelativeHtmlUrlPath -Path $relativePath
    $counts = [ordered]@{
        forms = Get-RegexMatchCount -Content $content -Pattern "<form\b"
        inputs = Get-RegexMatchCount -Content $content -Pattern "<input\b"
        buttons = Get-RegexMatchCount -Content $content -Pattern "<button\b"
        textareas = Get-RegexMatchCount -Content $content -Pattern "<textarea\b"
        anchors = Get-RegexMatchCount -Content $content -Pattern "<a\b"
        scripts = Get-RegexMatchCount -Content $content -Pattern "<script\b"
        iframes = Get-RegexMatchCount -Content $content -Pattern "<iframe\b"
        images = Get-RegexMatchCount -Content $content -Pattern "<img\b"
        canvas = Get-RegexMatchCount -Content $content -Pattern "<canvas\b"
        contenteditable = Get-RegexMatchCount -Content $content -Pattern "contenteditable\s*="
    }
    $interactiveScore =
        ($counts.forms * 3) +
        ($counts.inputs * 3) +
        ($counts.textareas * 3) +
        ($counts.buttons * 2) +
        ($counts.contenteditable * 4) +
        $counts.anchors

    [pscustomobject]@{
        relative_path = $relativePath
        url_path = $urlPath
        url = "http://{0}:{1}/{2}" -f $Host, $Port, $urlPath
        title = Get-HtmlTitle -Content $content
        file_size_bytes = $_.Length
        interactive_score = $interactiveScore
        counts = [pscustomobject]$counts
    }
})

$recommendedInitialPage = $pageSummaries |
    Sort-Object @{ Expression = "interactive_score"; Descending = $true }, @{ Expression = "relative_path"; Descending = $false } |
    Select-Object -First 1

$summary = [pscustomobject]@{
    page_root = $resolvedPageRoot
    repo_root = $RepoRoot
    host = $Host
    port = $Port
    page_count = $pageSummaries.Count
    recommended_initial_page = $recommendedInitialPage.relative_path
    recommended_initial_url = $recommendedInitialPage.url
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    pages = $pageSummaries
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding Ascii

Write-Host ("Saved HTML summary: {0}" -f $OutputPath)
Write-Host ("Recommended initial page: {0}" -f $recommendedInitialPage.relative_path)
Write-Host ""

foreach ($page in $pageSummaries) {
    $title = if ([string]::IsNullOrWhiteSpace($page.title)) {
        "(untitled)"
    } else {
        $page.title
    }
    Write-Host ("- {0}" -f $page.relative_path)
    Write-Host ("  title: {0}" -f $title)
    Write-Host ("  score: {0} | forms={1} inputs={2} buttons={3} textareas={4} links={5} scripts={6}" -f @(
            $page.interactive_score,
            $page.counts.forms,
            $page.counts.inputs,
            $page.counts.buttons,
            $page.counts.textareas,
            $page.counts.anchors,
            $page.counts.scripts
        ))
    Write-Host ("  url: {0}" -f $page.url)
}

$summary | ConvertTo-Json -Depth 6
