[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AttachedHtmlFlowMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [string]$PreferredInitialPage,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [bool]$UsingExplicitInputPath,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [Parameter(Mandatory = $true)]
        [bool]$LeaveOpen,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $preferredInitialPageMode = if ($PreferredInitialPage) {
        "explicit"
    } elseif ($ResolvedPreferredInitialPage) {
        if ($GoogleStyle) { "google-style-auto" } else { "auto-selected" }
    } else {
        "saved-page-summary-auto"
    }

    return [ordered]@{
        input_mode = if ($UsingExplicitInputPath) { "explicit" } else { "auto-discovered attached HTML" }
        input_count = @($ResolvedInputPath).Count
        resolved_input_path = @($ResolvedInputPath)
        preferred_initial_page = $ResolvedPreferredInitialPage
        preferred_initial_page_mode = $preferredInitialPageMode
        validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }
        leave_open = $LeaveOpen
        port = $Port
        search_roots = if ($UsingExplicitInputPath) { @() } else { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) }
    }
}

function Get-AttachedHtmlValidationHint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle
    )

    $leaf = [System.IO.Path]::GetFileName($Path)
    $pathLower = $Path.ToLowerInvariant()
    $rawLower = ""

    try {
        $rawLower = (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop).ToLowerInvariant()
    } catch {
        $rawLower = ""
    }

    $hasSearchField = $rawLower -match "<(input|textarea)[^>]+name\s*=\s*['`\""]q['`\""]" -or
        $rawLower -match "(id|class|name)\s*=\s*['`\""](apjfqb|gsfi|tsf|btnk)['`\""]"
    $hasGoogleSafetySignals = $rawLower -match "google safety|safety centre|online safety|privacy"
    $hasGoogleSearchSignals = $pathLower -match "google" -and $hasSearchField -and -not $hasGoogleSafetySignals
    $hasApplicationSignals = $pathLower -match "job|application|apply|greenhouse" -or
        $rawLower -match "job application|greenhouse|type\s*=\s*['`\""]submit['`\""]|aria-label\s*=\s*['`\""]apply['`\""]"
    $hasDenseAssetSignals = $pathLower -match "_files" -or
        $rawLower -match "jquery\.datatables|bootstrap|min\.css|_files/" -or
        ([regex]::Matches($rawLower, "<link\b").Count -ge 6) -or
        ([regex]::Matches($rawLower, "<script\b").Count -ge 6)

    if (($GoogleStyle -and $hasGoogleSearchSignals) -or $hasGoogleSearchSignals) {
        return [ordered]@{
            fixture = $leaf
            change_area = "google-attached-html"
            summary = "Google-style search or query page. Keep the issue #3 localhost-first validation flow ahead of manual follow-up."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($hasApplicationSignals) {
        return [ordered]@{
            fixture = $leaf
            change_area = "input"
            summary = "Form-heavy or application-style page. Start with shared form-controls and inline input gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($hasDenseAssetSignals) {
        return [ordered]@{
            fixture = $leaf
            change_area = "rendering"
            summary = "Asset-heavy saved page. Start with layout/rendering plus stylesheet or image gates before the manual localhost replay."
            bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        fixture = $leaf
        change_area = "attached-html"
        summary = "General attached page. Start with the closest bounded suite for the subsystem you changed, then use the attached-page localhost flow."
        bounded_first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
    }
}

function Get-AttachedHtmlValidationHints {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle
    )

    return @(
        $ResolvedInputPath | ForEach-Object {
            [pscustomobject](Get-AttachedHtmlValidationHint -Path $_ -GoogleStyle $GoogleStyle)
        }
    )
}

function Get-AttachedHtmlOverallRecommendation {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Hints,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle
    )

    if ($GoogleStyle -or ($Hints | Where-Object { $_.change_area -eq "google-attached-html" })) {
        return [ordered]@{
            change_area = "google-attached-html"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1 -ManualGoogleStyle"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "input" }) {
        return [ordered]@{
            change_area = "input"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
        }
    }

    if ($Hints | Where-Object { $_.change_area -eq "rendering" }) {
        return [ordered]@{
            change_area = "rendering"
            first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering"
            follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea network"
        }
    }

    return [ordered]@{
        change_area = "attached-html"
        first_step = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        follow_up = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait"
    }
}

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
$usingExplicitInputPath = $InputPath -and $InputPath.Count -gt 0
$resolvedInputPath = if ($usingExplicitInputPath) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $repoRoot -GoogleStyle:$GoogleStyle
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
} elseif ($GoogleStyle) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}

$attachedHtmlHints = Get-AttachedHtmlValidationHints -ResolvedInputPath $resolvedInputPath -GoogleStyle ([bool]$GoogleStyle)
$overallRecommendation = Get-AttachedHtmlOverallRecommendation -Hints $attachedHtmlHints -GoogleStyle ([bool]$GoogleStyle)
$attachedAssetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath)
$assetClosureChecker = Join-Path $repoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"
if (-not (Test-Path -LiteralPath $assetClosureChecker -PathType Leaf)) {
    throw "attached HTML asset-closure checker not found: $assetClosureChecker"
}

$assetClosureArgs = @{
    RepoRoot = $repoRoot
    InputPath = $resolvedInputPath
}
if ($GoogleStyle) {
    $assetClosureArgs["GoogleStyle"] = $true
}
$assetClosureArgs["Json"] = $true
$assetClosureJson = (& $assetClosureChecker @assetClosureArgs) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$assetClosureAudit = $assetClosureJson | ConvertFrom-Json -Depth 10

$helperPath = if ($GoogleStyle) {
    Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
}

if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw "validation flow helper not found: $helperPath"
}

$helperArgs = @{
    Port = $Port
}
if (-not ($GoogleStyle -and -not $usingExplicitInputPath)) {
    $helperArgs["InputPath"] = $resolvedInputPath
}
if ($resolvedPreferredInitialPage) {
    $helperArgs["PreferredInitialPage"] = $resolvedPreferredInitialPage
}
if ($GoogleStyle) {
    $helperArgs["ManualGoogleStyle"] = $true
}
if ($GoogleStyle -and $LeaveOpen) {
    $helperArgs["LeaveOpen"] = $true
}

$attachedHtmlMetadata = Get-AttachedHtmlFlowMetadata `
    -RepoRoot $repoRoot `
    -ResolvedInputPath $resolvedInputPath `
    -PreferredInitialPage $PreferredInitialPage `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -UsingExplicitInputPath ([bool]$usingExplicitInputPath) `
    -GoogleStyle ([bool]$GoogleStyle) `
    -LeaveOpen ([bool]$LeaveOpen) `
    -Port $Port

if ($Json) {
    $helperArgs["Json"] = $true
    $helperJson = (& $helperPath @helperArgs) -join [Environment]::NewLine
    $result = [ordered]@{
        attached_html = $attachedHtmlMetadata
        missing_asset_audit = $attachedAssetAudit
        asset_closure_audit = $assetClosureAudit
        fixture_hints = $attachedHtmlHints
        overall_recommendation = $overallRecommendation
        flow = $helperJson | ConvertFrom-Json -Depth 10
    }
    $result | ConvertTo-Json -Depth 10
    exit $LASTEXITCODE
}

Write-Host "Attached HTML validation flow"
Write-Host ""
Write-Host ("Inputs discovered: {0}" -f $attachedHtmlMetadata.input_count)
Write-Host ("Input mode: {0}" -f $attachedHtmlMetadata.input_mode)
if ($resolvedPreferredInitialPage) {
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
    }
} else {
    Write-Host "Preferred initial page: auto (from saved-page summary)"
}
Write-Host ("Validation mode: {0}" -f $attachedHtmlMetadata.validation_mode)
Write-Host ""
Show-MissingLocalFixtureAssetWarnings -AssetAudit $attachedAssetAudit -RepoRoot $repoRoot
Write-Host "Deep attached-asset closure audit:"
foreach ($fixture in @($assetClosureAudit.fixtures)) {
    Write-Host ("- {0}" -f $fixture.display_path)
    Write-Host ("  Inspected files: {0}" -f $fixture.inspected_file_count)
    Write-Host ("  Inspected CSS files: {0}" -f $fixture.inspected_css_file_count)
    Write-Host ("  Inspected module script files: {0}" -f $fixture.inspected_module_script_file_count)
    if ($fixture.missing_asset_count -eq 0) {
        Write-Host "  Missing deep-linked assets: none"
    } else {
        Write-Host ("  Missing deep-linked assets: {0}" -f $fixture.missing_asset_count)
        foreach ($asset in ($fixture.missing_assets | Select-Object -First 5)) {
            Write-Host ("  - {0}" -f $asset)
        }
        if ($fixture.missing_asset_count -gt 5) {
            Write-Host ("  - ... {0} more" -f ($fixture.missing_asset_count - 5))
        }
    }
}
Write-Host ""
Write-Host "Per-page bounded validation hints:"
foreach ($hint in $attachedHtmlHints) {
    Write-Host ("- {0}" -f $hint.fixture)
    Write-Host ("  Route: {0}" -f $hint.change_area)
    Write-Host ("  Why: {0}" -f $hint.summary)
    Write-Host ("  First bounded step: {0}" -f $hint.bounded_first_step)
    Write-Host ("  Follow-up: {0}" -f $hint.follow_up)
}
Write-Host ""
Write-Host ("Overall first bounded step: {0}" -f $overallRecommendation.first_step)
Write-Host ("Overall follow-up: {0}" -f $overallRecommendation.follow_up)
Write-Host ""

& $helperPath @helperArgs