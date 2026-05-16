[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AttachedBundleTargetSpec {
    return @(
        [pscustomobject]@{
            Name = "google-safety-centre"
            DisplayName = "Control your online safety and privacy – Google Safety Centre"
            MatchPatterns = @(
                "google safety centre",
                "online security and privacy.+google safety centre",
                "control your online safety and privacy.+google safety centre",
                "safety\.google"
            )
            Purpose = "Google-branded policy and content-heavy compatibility target."
        }
        [pscustomobject]@{
            Name = "anthropic-job-application"
            DisplayName = "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic"
            MatchPatterns = @(
                "job application.+interpretability at anthropic",
                "jobs\.ashbyhq\.com/.+anthropic",
                "ashbyhq\.com/.+anthropic"
            )
            Purpose = "Form-heavy application page compatibility target."
        }
        [pscustomobject]@{
            Name = "uap-encounters"
            DisplayName = "Presidential Unsealing and Reporting System for UAP Encounters"
            MatchPatterns = @(
                "presidential unsealing and reporting system for uap encounters",
                "department of war",
                "pursue"
            )
            Purpose = "Dense document and script-heavy compatibility target."
        }
    )
}

function Get-FirstRegexGroupValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Raw,
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $match = [regex]::Match(
        $Raw,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
    )
    if (-not $match.Success) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
}

function Get-FirstRegexCaptureValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Raw,
        [Parameter(Mandatory = $true)]
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        $match = [regex]::Match(
            $Raw,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
        if (-not $match.Success) {
            continue
        }

        foreach ($group in ($match.Groups | Select-Object -Skip 1)) {
            if (-not [string]::IsNullOrWhiteSpace($group.Value)) {
                return [System.Net.WebUtility]::HtmlDecode($group.Value).Trim()
            }
        }
    }

    return ""
}

function Get-MetaTagContentValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Raw,
        [Parameter(Mandatory = $true)]
        [string]$MetaName
    )

    $metaTags = [regex]::Matches(
        $Raw,
        '<meta\b[^>]*>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    foreach ($match in $metaTags) {
        $tag = $match.Value
        $propertyValue = Get-FirstRegexCaptureValue -Raw $tag -Patterns @(
            '\bproperty\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
        )
        $nameValue = Get-FirstRegexCaptureValue -Raw $tag -Patterns @(
            '\bname\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
        )

        if (
            -not [string]::Equals($propertyValue, "og:$MetaName", [System.StringComparison]::OrdinalIgnoreCase) -and
            -not [string]::Equals($nameValue, "og:$MetaName", [System.StringComparison]::OrdinalIgnoreCase)
        ) {
            continue
        }

        $contentValue = Get-FirstRegexCaptureValue -Raw $tag -Patterns @(
            '\bcontent\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
        )
        if (-not [string]::IsNullOrWhiteSpace($contentValue)) {
            return $contentValue
        }
    }

    return ""
}

function Get-CanonicalHref {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Raw
    )

    $linkTags = [regex]::Matches(
        $Raw,
        '<link\b[^>]*>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    foreach ($match in $linkTags) {
        $tag = $match.Value
        $relValue = Get-FirstRegexCaptureValue -Raw $tag -Patterns @(
            '\brel\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
        )
        if (-not [string]::Equals($relValue, 'canonical', [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $hrefValue = Get-FirstRegexCaptureValue -Raw $tag -Patterns @(
            '\bhref\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
        )
        if (-not [string]::IsNullOrWhiteSpace($hrefValue)) {
            return $hrefValue
        }
    }

    return ""
}

function Get-DocumentUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Raw
    )

    $frontMatterUrl = Get-FirstRegexGroupValue -Raw $Raw -Pattern '(?m)^\s*url:\s*(https?://\S+)'
    if (-not [string]::IsNullOrWhiteSpace($frontMatterUrl)) {
        return $frontMatterUrl
    }

    $canonicalHref = Get-CanonicalHref -Raw $Raw
    if (-not [string]::IsNullOrWhiteSpace($canonicalHref)) {
        return $canonicalHref
    }

    return Get-MetaTagContentValue -Raw $Raw -MetaName 'url'
}

function Get-FixtureMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    } catch {
        return [pscustomobject]@{
            Raw = ""
            Title = ""
            OpenGraphTitle = ""
            OpenGraphUrl = ""
            DocumentUrl = ""
        }
    }

    return [pscustomobject]@{
        Raw = $raw
        Title = Get-FirstRegexGroupValue -Raw $raw -Pattern "<title[^>]*>(.*?)</title>"
        OpenGraphTitle = Get-MetaTagContentValue -Raw $raw -MetaName 'title'
        OpenGraphUrl = Get-MetaTagContentValue -Raw $raw -MetaName 'url'
        DocumentUrl = Get-DocumentUrl -Raw $raw
    }
}

function Convert-ToSingleQuotedPowerShellArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + $Value.Replace("'", "''") + "'"
}

function Convert-ToPowerShellArgumentList {
    param(
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return ""
    }

    return ($Values | ForEach-Object { Convert-ToSingleQuotedPowerShellArgument -Value $_ }) -join " "
}

function Get-ResolvedExplicitBundleInputPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$InputPath
    )

    $resolvedPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($rawPath in $InputPath) {
        $resolvedItems = @(Resolve-Path -LiteralPath $rawPath -ErrorAction Stop)
        foreach ($resolvedItem in $resolvedItems) {
            $item = Get-Item -LiteralPath $resolvedItem.Path -ErrorAction Stop
            if ($item.PSIsContainer) {
                $fixturePaths = @(
                    Get-ChildItem -LiteralPath $item.FullName -Recurse -File |
                        Where-Object { $_.Extension -in @(".html", ".htm") } |
                        Sort-Object FullName |
                        ForEach-Object { $_.FullName }
                )
                foreach ($fixturePath in $fixturePaths) {
                    Add-UniqueString -List $resolvedPaths -Value $fixturePath
                }
                continue
            }

            Add-UniqueString -List $resolvedPaths -Value $item.FullName
        }
    }

    return @($resolvedPaths)
}

function Get-ResolvedBundleCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string[]]$InputPath
    )

    $paths = if ($InputPath -and $InputPath.Count -gt 0) {
        @(Get-ResolvedExplicitBundleInputPaths -InputPath $InputPath)
    } else {
        @(Get-AttachedHtmlCandidates -RepoRoot $RepoRoot | ForEach-Object { $_.FullName })
    }

    return @(
        $paths | ForEach-Object {
            $metadata = Get-FixtureMetadata -Path $_
            $fixtureItem = Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue
            $googleSummary = if ($fixtureItem) { Get-GoogleStyleFixtureSummary $fixtureItem } else { $null }
            $searchTextParts = @($_, $metadata.Title, $metadata.OpenGraphTitle, $metadata.OpenGraphUrl, $metadata.DocumentUrl) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            [pscustomobject]@{
                Path = $_
                Title = $metadata.Title
                OpenGraphTitle = $metadata.OpenGraphTitle
                OpenGraphUrl = $metadata.OpenGraphUrl
                DocumentUrl = $metadata.DocumentUrl
                SearchText = ($searchTextParts -join "`n").ToLowerInvariant()
                IsGoogleStyle = if ($fixtureItem) { Test-GoogleStyleFixture $fixtureItem } else { $false }
                GoogleScore = if ($googleSummary) { $googleSummary.score } else { [int]::MinValue }
            }
        }
    )
}

function Get-TargetValidationRouting {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetName,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [bool]$IsGoogleStyle = $false
    )

    if ($Status -ne "found") {
        return [ordered]@{
            change_area = $null
            summary = "Routing is available after this target resolves to one attached HTML file."
            first_step = $null
            follow_up = $null
        }
    }

    switch ($TargetName) {
        "google-safety-centre" {
            return [ordered]@{
                change_area = if ($IsGoogleStyle) { "google-attached-html" } else { "attached-html" }
                summary = if ($IsGoogleStyle) {
                    "Start with the Google-style attached HTML flow so the saved page stays on the issue #3 localhost-first ladder before manual replay."
                } else {
                    "Start with the general attached HTML flow so the content-heavy Google-branded page stays on the broader localhost replay path before manual follow-up."
                }
                first_step = if ($IsGoogleStyle) {
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
                } else {
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
                }
                follow_up = if ($IsGoogleStyle) {
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait"
                } else {
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait"
                }
            }
        }
        "anthropic-job-application" {
            return [ordered]@{
                change_area = "input"
                summary = "Start with the shared input suites, then use the attached HTML localhost follow-up for the form-heavy page."
                first_step = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea input"
                follow_up = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait"
            }
        }
        "uap-encounters" {
            return [ordered]@{
                change_area = "rendering"
                summary = "Start with the rendering suites, then use the attached HTML localhost follow-up for the dense document page."
                first_step = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea rendering"
                follow_up = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
            }
        }
        default {
            return [ordered]@{
                change_area = "attached-html"
                summary = "Start with the general attached HTML flow."
                first_step = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
                follow_up = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait"
            }
        }
    }
}

function Get-BundlePinnedValidationCommands {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ResultRows
    )

    $resolvedRows = @($ResultRows | Where-Object { $_.status -eq "found" -and $_.path })
    if ($resolvedRows.Count -eq 0) {
        return [ordered]@{
            validation_profile = $null
            locked_input_count = 0
            preferred_initial_page = $null
            preferred_initial_page_display_path = $null
            summary = "Resolve the expected bundle first so the checker can print the exact attached-page follow-up commands."
            surface_check = $null
            asset_closure = $null
            flow = $null
            runner = $null
        }
    }

    $resolvedInputPath = @($resolvedRows | ForEach-Object { $_.path })
    $inputPathArguments = Convert-ToPowerShellArgumentList -Values $resolvedInputPath
    $googleStyleTarget = @(
        $resolvedRows |
            Where-Object { $_.is_google_style } |
            Sort-Object @{ Expression = { $_.google_style_score }; Descending = $true }, @{ Expression = { $_.path } }
    ) | Select-Object -First 1
    $preferredTarget = if ($googleStyleTarget) { $googleStyleTarget } else { $resolvedRows | Select-Object -First 1 }
    $preferredInitialPageArgument = Convert-ToSingleQuotedPowerShellArgument -Value $preferredTarget.path

    if ($googleStyleTarget) {
        return [ordered]@{
            validation_profile = "google-attached-html"
            locked_input_count = $resolvedInputPath.Count
            preferred_initial_page = $preferredTarget.path
            preferred_initial_page_display_path = $preferredTarget.display_path
            summary = "Keep the current compatibility bundle locked into the Google-style attached HTML route, with the strongest Google-style page pinned first for the issue #3 localhost-first follow-up."
            surface_check = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1"
            asset_closure = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle -InputPath $inputPathArguments"
            flow = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1 -InputPath $inputPathArguments -PreferredInitialPage $preferredInitialPageArgument"
            runner = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -InputPath $inputPathArguments -PreferredInitialPage $preferredInitialPageArgument -Wait"
        }
    }

    return [ordered]@{
        validation_profile = "attached-html"
        locked_input_count = $resolvedInputPath.Count
        preferred_initial_page = $preferredTarget.path
        preferred_initial_page_display_path = $preferredTarget.display_path
        summary = "Keep the current compatibility bundle locked into the general attached HTML route, with the first resolved target pinned as the initial page."
        surface_check = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_validation_surface.ps1"
        asset_closure = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -InputPath $inputPathArguments"
        flow = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1 -InputPath $inputPathArguments -PreferredInitialPage $preferredInitialPageArgument"
        runner = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_localhost_validation.ps1 -InputPath $inputPathArguments -PreferredInitialPage $preferredInitialPageArgument -Wait"
    }
}

function Get-OverallBundleRecommendation {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ResultRows
    )

    $bundlePinnedCommands = Get-BundlePinnedValidationCommands -ResultRows $ResultRows
    $googleStyleTarget = @(
        $ResultRows |
            Where-Object { $_.status -eq "found" -and $_.is_google_style } |
            Sort-Object @{ Expression = { $_.google_style_score }; Descending = $true }, @{ Expression = { $_.path } }
    ) | Select-Object -First 1
    if ($googleStyleTarget) {
        return [ordered]@{
            preferred_initial_page = $googleStyleTarget.path
            preferred_initial_page_display_path = $googleStyleTarget.display_path
            first_change_area = $googleStyleTarget.route_change_area
            first_step = $googleStyleTarget.bounded_first_step
            follow_up = $googleStyleTarget.follow_up
            summary = "Keep the strongest Google-style target first so the bundle stays aligned with the issue #3 localhost-first follow-up before the broader attached-page replay."
            bundle_validation_profile = $bundlePinnedCommands.validation_profile
            bundle_locked_input_count = $bundlePinnedCommands.locked_input_count
            bundle_surface_check = $bundlePinnedCommands.surface_check
            bundle_asset_closure = $bundlePinnedCommands.asset_closure
            bundle_flow = $bundlePinnedCommands.flow
            bundle_runner = $bundlePinnedCommands.runner
            bundle_summary = $bundlePinnedCommands.summary
        }
    }

    $firstFound = $ResultRows | Where-Object { $_.status -eq "found" } | Select-Object -First 1
    if ($firstFound) {
        return [ordered]@{
            preferred_initial_page = $firstFound.path
            preferred_initial_page_display_path = $firstFound.display_path
            first_change_area = $firstFound.route_change_area
            first_step = $firstFound.bounded_first_step
            follow_up = $firstFound.follow_up
            summary = "Start with the first resolved compatibility target, then widen into the broader attached-page localhost replay."
            bundle_validation_profile = $bundlePinnedCommands.validation_profile
            bundle_locked_input_count = $bundlePinnedCommands.locked_input_count
            bundle_surface_check = $bundlePinnedCommands.surface_check
            bundle_asset_closure = $bundlePinnedCommands.asset_closure
            bundle_flow = $bundlePinnedCommands.flow
            bundle_runner = $bundlePinnedCommands.runner
            bundle_summary = $bundlePinnedCommands.summary
        }
    }

    return [ordered]@{
        preferred_initial_page = $null
        preferred_initial_page_display_path = $null
        first_change_area = $null
        first_step = $null
        follow_up = $null
        summary = "Resolve the expected attached-page bundle before routing validation."
        bundle_validation_profile = $bundlePinnedCommands.validation_profile
        bundle_locked_input_count = $bundlePinnedCommands.locked_input_count
        bundle_surface_check = $bundlePinnedCommands.surface_check
        bundle_asset_closure = $bundlePinnedCommands.asset_closure
        bundle_flow = $bundlePinnedCommands.flow
        bundle_runner = $bundlePinnedCommands.runner
        bundle_summary = $bundlePinnedCommands.summary
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
$targets = @(Get-AttachedBundleTargetSpec)
$candidates = @(Get-ResolvedBundleCandidates -RepoRoot $RepoRoot -InputPath $InputPath)

$matchedPaths = @()
$targetResults = foreach ($target in $targets) {
    $matches = @(
        $candidates | ForEach-Object {
            $candidate = $_
            $patternHits = @($target.MatchPatterns | Where-Object { $_ -and $candidate.SearchText -match $_ }).Count
            if ($patternHits -gt 0) {
                [pscustomobject]@{
                    Candidate = $candidate
                    PatternHits = $patternHits
                }
            }
        }
    )

    $selectedPath = $null
    $selectedTitle = ""
    $selectedOpenGraphTitle = ""
    $selectedDocumentUrl = ""
    $selectedGoogleStyle = $false
    $selectedGoogleScore = $null
    $selectedPatternHits = 0
    $status = "missing"
    if ($matches.Count -gt 0) {
        $sortedMatches = @(
            $matches | Sort-Object @{ Expression = { $_.PatternHits }; Descending = $true }, @{ Expression = { $_.Candidate.GoogleScore }; Descending = $true }, @{ Expression = { $_.Candidate.Path } }
        )
        $topPatternHits = $sortedMatches[0].PatternHits
        $topMatches = @($sortedMatches | Where-Object { $_.PatternHits -eq $topPatternHits })

        if ($topMatches.Count -eq 1) {
            $selectedCandidate = $topMatches[0].Candidate
            $selectedPath = $selectedCandidate.Path
            $selectedTitle = $selectedCandidate.Title
            $selectedOpenGraphTitle = $selectedCandidate.OpenGraphTitle
            $selectedDocumentUrl = $selectedCandidate.DocumentUrl
            $selectedGoogleStyle = [bool]$selectedCandidate.IsGoogleStyle
            $selectedGoogleScore = $selectedCandidate.GoogleScore
            $selectedPatternHits = $topMatches[0].PatternHits
            $matchedPaths += $selectedPath
            $status = "found"
        } else {
            $status = "ambiguous"
            $selectedPatternHits = $topPatternHits
        }
    }

    $routing = Get-TargetValidationRouting -TargetName $target.Name -Status $status -IsGoogleStyle:$selectedGoogleStyle

    [pscustomobject]@{
        name = $target.Name
        display_name = $target.DisplayName
        purpose = $target.Purpose
        status = $status
        match_count = $matches.Count
        pattern_hit_count = $selectedPatternHits
        path = $selectedPath
        title = $selectedTitle
        open_graph_title = $selectedOpenGraphTitle
        document_url = $selectedDocumentUrl
        is_google_style = $selectedGoogleStyle
        google_style_score = $selectedGoogleScore
        change_area = $routing.change_area
        route_summary = $routing.summary
        bounded_first_step = $routing.first_step
        follow_up = $routing.follow_up
        candidate_paths = @($matches | ForEach-Object { $_.Candidate.Path })
    }
}

$assetAudit = @()
if ($matchedPaths.Count -gt 0) {
    $assetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $matchedPaths)
}

$assetAuditByPath = @{}
foreach ($fixture in $assetAudit) {
    $assetAuditByPath[$fixture.path] = $fixture
}

$resultRows = @(
    $targetResults | ForEach-Object {
        $audit = if ($_.path -and $assetAuditByPath.ContainsKey($_.path)) { $assetAuditByPath[$_.path] } else { $null }
        $effectiveTitle = if (-not [string]::IsNullOrWhiteSpace($_.title)) { $_.title } else { $_.open_graph_title }
        [ordered]@{
            name = $_.name
            display_name = $_.display_name
            purpose = $_.purpose
            status = $_.status
            match_count = $_.match_count
            pattern_hit_count = $_.pattern_hit_count
            path = $_.path
            display_path = if ($_.path) { Convert-ToDisplayPath -Path $_.path -RepoRoot $RepoRoot } else { $null }
            title = $_.title
            open_graph_title = $_.open_graph_title
            effective_title = $effectiveTitle
            document_url = $_.document_url
            is_google_style = $_.is_google_style
            google_style_score = $_.google_style_score
            missing_asset_count = if ($audit) { $audit.missing_asset_count } else { $null }
            route_change_area = $_.change_area
            route_summary = $_.route_summary
            bounded_first_step = $_.bounded_first_step
            follow_up = $_.follow_up
            candidate_paths = @($_.candidate_paths | ForEach-Object { Convert-ToDisplayPath -Path $_ -RepoRoot $RepoRoot })
        }
    }
)

$missingTargets = @($resultRows | Where-Object { $_.status -eq "missing" })
$ambiguousTargets = @($resultRows | Where-Object { $_.status -eq "ambiguous" })
$bundlePassed = $missingTargets.Count -eq 0 -and $ambiguousTargets.Count -eq 0
$overallRecommendation = Get-OverallBundleRecommendation -ResultRows $resultRows

if ($Json) {
    [ordered]@{
        repo_root = $RepoRoot
        search_roots = $searchRoots
        input_mode = if ($InputPath -and $InputPath.Count -gt 0) { "explicit" } else { "auto-discovered" }
        discovered_candidate_count = $candidates.Count
        expected_target_count = $targets.Count
        matched_target_count = @($resultRows | Where-Object { $_.status -eq "found" }).Count
        passed = $bundlePassed
        overall_recommendation = $overallRecommendation
        targets = $resultRows
    } | ConvertTo-Json -Depth 8

    if (-not $bundlePassed) {
        exit 1
    }

    exit 0
}

Write-Host "Attached HTML target bundle check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Input mode: {0}" -f $(if ($InputPath -and $InputPath.Count -gt 0) { "explicit" } else { "auto-discovered" }))
if ($searchRoots.Count -gt 0) {
    Write-Host ("Search roots: {0}" -f ($searchRoots -join "; "))
}
Write-Host ("Discovered candidates: {0}" -f $candidates.Count)
Write-Host ""

foreach ($row in $resultRows) {
    $statusText = $row.status.ToUpperInvariant()
    Write-Host ("[{0}] {1}" -f $statusText, $row.display_name)
    Write-Host ("  Purpose: {0}" -f $row.purpose)
    if ($row.display_path) {
        Write-Host ("  Path: {0}" -f $row.display_path)
    }
    if ($row.effective_title) {
        Write-Host ("  Title: {0}" -f $row.effective_title)
    }
    if ($row.document_url) {
        Write-Host ("  Document URL: {0}" -f $row.document_url)
    }
    if ($row.pattern_hit_count -gt 0) {
        Write-Host ("  Match signal count: {0}" -f $row.pattern_hit_count)
    }
    if ($row.is_google_style) {
        Write-Host ("  Google-style score: {0}" -f $row.google_style_score)
    }
    if ($null -ne $row.missing_asset_count) {
        Write-Host ("  Shallow missing-asset count: {0}" -f $row.missing_asset_count)
    }
    if ($row.route_change_area) {
        Write-Host ("  Route: {0}" -f $row.route_change_area)
        Write-Host ("  Why: {0}" -f $row.route_summary)
        Write-Host ("  First bounded step: {0}" -f $row.bounded_first_step)
        Write-Host ("  Follow-up: {0}" -f $row.follow_up)
    }
    if ($row.status -eq "ambiguous") {
        foreach ($candidatePath in $row.candidate_paths) {
            Write-Host ("  Candidate: {0}" -f $candidatePath)
        }
    }
}

Write-Host ""
Write-Host ("Overall recommendation: {0}" -f $overallRecommendation.summary)
if ($overallRecommendation.preferred_initial_page_display_path) {
    Write-Host ("Preferred initial page: {0}" -f $overallRecommendation.preferred_initial_page_display_path)
}
if ($overallRecommendation.first_step) {
    Write-Host ("Suggested first bounded step: {0}" -f $overallRecommendation.first_step)
}
if ($overallRecommendation.follow_up) {
    Write-Host ("Suggested follow-up: {0}" -f $overallRecommendation.follow_up)
}
if ($overallRecommendation.bundle_validation_profile) {
    Write-Host ""
    Write-Host ("Bundle-pinned validation profile: {0}" -f $overallRecommendation.bundle_validation_profile)
    Write-Host ("Bundle-pinned inputs: {0}" -f $overallRecommendation.bundle_locked_input_count)
    Write-Host ("Bundle route summary: {0}" -f $overallRecommendation.bundle_summary)
    if ($overallRecommendation.bundle_surface_check) {
        Write-Host ("Bundle surface check: {0}" -f $overallRecommendation.bundle_surface_check)
    }
    if ($overallRecommendation.bundle_asset_closure) {
        Write-Host ("Bundle asset-closure check: {0}" -f $overallRecommendation.bundle_asset_closure)
    }
    if ($overallRecommendation.bundle_flow) {
        Write-Host ("Bundle flow helper: {0}" -f $overallRecommendation.bundle_flow)
    }
    if ($overallRecommendation.bundle_runner) {
        Write-Host ("Bundle runner: {0}" -f $overallRecommendation.bundle_runner)
    }
}
Write-Host ""

if ($bundlePassed) {
    Write-Host "Known attached HTML compatibility bundle is present."
    Write-Host "Run check_attached_html_local_asset_closure.ps1 next if you also need deep sibling-asset proof before localhost replay."
    exit 0
}

Write-Host ("Known attached HTML compatibility bundle check failed: {0} missing, {1} ambiguous." -f $missingTargets.Count, $ambiguousTargets.Count)
Write-Host "Restore the expected saved pages or pass explicit InputPath values before relying on attached-page localhost compatibility coverage."
exit 1