[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

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

function Get-FixtureRouteSummary {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$Fixture,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $raw = ""
    try {
        $raw = Get-Content -LiteralPath $Fixture.FullName -Raw -ErrorAction Stop
    } catch {
        $raw = ""
    }

    $title = Get-HtmlTitle -Content $raw
    $pathLower = $Fixture.FullName.ToLowerInvariant()
    $titleLower = $title.ToLowerInvariant()
    $googleBranded = $pathLower -match "google" -or $titleLower -match "google"
    $googleStyle = Test-GoogleStyleFixture $Fixture

    if ($googleStyle) {
        return [ordered]@{
            fixture = Convert-ToDisplayPath -Path $Fixture.FullName -RepoRoot $RepoRoot
            title = $title
            route = "google-style"
            note = "Use the issue #3 localhost-first Google validation flow."
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
        }
    }

    if ($googleBranded) {
        return [ordered]@{
            fixture = Convert-ToDisplayPath -Path $Fixture.FullName -RepoRoot $RepoRoot
            title = $title
            route = "google-branded-non-search"
            note = "Keep this on the general attached-html route unless a real search-form fixture is also present."
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
        }
    }

    return [ordered]@{
        fixture = Convert-ToDisplayPath -Path $Fixture.FullName -RepoRoot $RepoRoot
        title = $title
        route = "general"
        note = "Use the general attached-html flow and let the bounded suite hints pick the first localhost gate."
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$fixtures = @(Get-AttachedHtmlCandidates -RepoRoot $RepoRoot)
if ($fixtures.Count -eq 0) {
    throw "no attached HTML files were found under the current workspace search roots"
}

$routes = @(
    $fixtures |
        Sort-Object FullName |
        ForEach-Object {
            [pscustomobject](Get-FixtureRouteSummary -Fixture $_ -RepoRoot $RepoRoot)
        }
)

$googleStyleRoutes = @($routes | Where-Object { $_.route -eq "google-style" })
$googleBrandedNonSearchRoutes = @($routes | Where-Object { $_.route -eq "google-branded-non-search" })

$result = [ordered]@{
    repo_root = $RepoRoot
    fixture_count = $routes.Count
    google_style_fixture_count = $googleStyleRoutes.Count
    google_branded_non_search_fixture_count = $googleBrandedNonSearchRoutes.Count
    overall_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    google_style_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
    routes = $routes
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Current attached HTML fixture routes"
Write-Host ""
Write-Host ("Fixtures discovered: {0}" -f $result.fixture_count)
Write-Host ("General first step: {0}" -f $result.overall_first_step)
if ($result.google_style_fixture_count -gt 0) {
    Write-Host ("Google-style first step: {0}" -f $result.google_style_first_step)
}
if ($result.google_branded_non_search_fixture_count -gt 0) {
    Write-Host "Warning: Google-branded pages were found that do not qualify as Google search fixtures."
    Write-Host "Keep those pages on the general attached-html flow unless the helper also surfaces a real search-style fixture."
}
Write-Host ""

foreach ($route in $routes) {
    $title = if ([string]::IsNullOrWhiteSpace($route.title)) { "(untitled)" } else { $route.title }
    Write-Host ("- {0}" -f $route.fixture)
    Write-Host ("  title: {0}" -f $title)
    Write-Host ("  route: {0}" -f $route.route)
    Write-Host ("  note: {0}" -f $route.note)
    Write-Host ("  first step: {0}" -f $route.first_step)
}
