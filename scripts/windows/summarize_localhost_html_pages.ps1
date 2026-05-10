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

function Add-UniqueString {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$List,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if (-not $List.Contains($Value)) {
        $List.Add($Value) | Out-Null
    }
}

function Test-GoogleStyleHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $lowerPath = $RelativePath.ToLowerInvariant()
    $lowerTitle = $Title.ToLowerInvariant()
    $lowerContent = $Content.ToLowerInvariant()

    if ($lowerPath -match "google|search|query") {
        return $true
    }
    if ($lowerTitle -match "google|search") {
        return $true
    }
    if ($lowerContent -match 'name\s*=\s*["'']q["'']') {
        return $true
    }
    if ($lowerContent -match 'id\s*=\s*["'']search') {
        return $true
    }

    return $false
}

function Get-RecommendedProbeSuites {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Counts,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle
    )

    $result = [System.Collections.Generic.List[string]]::new()

    $hasTextInput = ($Counts.inputs + $Counts.textareas + $Counts.contenteditable) -gt 0
    $hasForms = $Counts.forms -gt 0
    $hasAnchors = $Counts.anchors -gt 0
    $hasImages = $Counts.images -gt 0
    $hasCanvas = $Counts.canvas -gt 0
    $hasScripts = $Counts.scripts -gt 0
    $hasFrames = $Counts.iframes -gt 0
    $hasInteractiveControls = $hasForms -or $hasTextInput -or ($Counts.buttons -gt 0)

    if ($hasInteractiveControls) {
        Add-UniqueString -List $result -Value "form-controls"
        Add-UniqueString -List $result -Value "inline-flow"
    }

    if ($hasAnchors) {
        Add-UniqueString -List $result -Value "wrapped-link"
        Add-UniqueString -List $result -Value "rendered-link-dom"
    }

    if ($hasImages) {
        Add-UniqueString -List $result -Value "image-smoke"
        Add-UniqueString -List $result -Value "flow-layout"
    }

    if ($hasCanvas) {
        Add-UniqueString -List $result -Value "canvas-smoke"
    }

    if ($hasScripts -or $hasFrames) {
        Add-UniqueString -List $result -Value "layout-smoke"
    }

    if ($GoogleStyle) {
        Add-UniqueString -List $result -Value "google-investigation-next"
        if ($hasInteractiveControls) {
            Add-UniqueString -List $result -Value "google-home"
        }
    }

    if ($result.Count -eq 0) {
        Add-UniqueString -List $result -Value "layout-smoke"
    }

    return @($result)
}

function Get-PageNextStep {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [Parameter(Mandatory = $true)]
        [string[]]$RecommendedSuites
    )

    if ($GoogleStyle) {
        return "Use scripts/windows/show_saved_page_google_validation_flow.ps1 so the reduced Google-style localhost and shared Enter-order phases run before the saved-page manual pass."
    }
    if ($RecommendedSuites.Count -gt 0) {
        return "Run the closest recommended bounded suite before the saved-page localhost follow-up."
    }

    return "Use scripts/windows/show_localhost_html_validation_flow.ps1 for the general saved-page follow-up."
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
    $title = Get-HtmlTitle -Content $content
    $googleStyle = Test-GoogleStyleHtml -RelativePath $relativePath -Title $title -Content $content
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
        contenteditable = Get-RegexMatchCount -Content $content -Pattern "contenteditable(\s*=\s*[\"']?(true|plaintext-only)[\"']?)?"
    }
    $interactiveScore =
        ($counts.forms * 3) +
        ($counts.inputs * 3) +
        ($counts.textareas * 3) +
        ($counts.buttons * 2) +
        ($counts.contenteditable * 4) +
        $counts.anchors
    $recommendedSuites = Get-RecommendedProbeSuites -Counts $counts -GoogleStyle $googleStyle
    $nextStep = Get-PageNextStep -GoogleStyle $googleStyle -RecommendedSuites $recommendedSuites

    [pscustomobject]@{
        relative_path = $relativePath
        url_path = $urlPath
        url = "http://{0}:{1}/{2}" -f $Host, $Port, $urlPath
        title = $title
        file_size_bytes = $_.Length
        interactive_score = $interactiveScore
        google_style = $googleStyle
        counts = [pscustomobject]$counts
        recommended_bounded_suites = $recommendedSuites
        manual_follow_up_suite = "manual-user"
        next_step = $nextStep
    }
})

$recommendedInitialPage = $pageSummaries |
    Sort-Object @{ Expression = "interactive_score"; Descending = $true }, @{ Expression = "relative_path"; Descending = $false } |
    Select-Object -First 1

$overallRecommendedSuites = [System.Collections.Generic.List[string]]::new()
foreach ($page in $pageSummaries) {
    foreach ($suite in $page.recommended_bounded_suites) {
        Add-UniqueString -List $overallRecommendedSuites -Value $suite
    }
}

$hasGoogleStylePages = @($pageSummaries | Where-Object { $_.google_style }).Count -gt 0
$overallNextStep = if ($hasGoogleStylePages) {
    "Use scripts/windows/show_saved_page_google_validation_flow.ps1 so Google-style saved pages run through the dedicated localhost and shared Enter-order issue #3 flow before the manual headed pass."
} else {
    "Run one or two of the recommended bounded suites first, then use scripts/windows/show_localhost_html_validation_flow.ps1 for the saved-page localhost follow-up."
}
$flowHelper = if ($hasGoogleStylePages) {
    "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    "scripts/windows/show_localhost_html_validation_flow.ps1"
}

$summary = [pscustomobject]@{
    page_root = $resolvedPageRoot
    repo_root = $RepoRoot
    host = $Host
    port = $Port
    page_count = $pageSummaries.Count
    recommended_initial_page = $recommendedInitialPage.relative_path
    recommended_initial_url = $recommendedInitialPage.url
    overall_recommended_suites = @($overallRecommendedSuites)
    manual_follow_up_suite = "manual-user"
    recommended_flow_helper = $flowHelper
    overall_google_style = $hasGoogleStylePages
    next_step = $overallNextStep
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    pages = $pageSummaries
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding Ascii

Write-Host ("Saved HTML summary: {0}" -f $OutputPath)
Write-Host ("Recommended initial page: {0}" -f $recommendedInitialPage.relative_path)
Write-Host ("Suggested bounded suites: {0}" -f ($summary.overall_recommended_suites -join ", "))
Write-Host ("Manual follow-up suite: {0}" -f $summary.manual_follow_up_suite)
Write-Host ("Flow helper: {0}" -f $summary.recommended_flow_helper)
Write-Host ("Next step: {0}" -f $summary.next_step)
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
    Write-Host ("  google-style: {0}" -f $page.google_style.ToString().ToLowerInvariant())
    Write-Host ("  bounded suites: {0}" -f ($page.recommended_bounded_suites -join ", "))
    Write-Host ("  url: {0}" -f $page.url)
    Write-Host ("  next: {0}" -f $page.next_step)
}

$summary | ConvertTo-Json -Depth 6
