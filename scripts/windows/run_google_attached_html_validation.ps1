[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
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

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

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

function Test-IgnoredLocalAssetReference([string]$Reference) {
    if ([string]::IsNullOrWhiteSpace($Reference)) {
        return $true
    }

    $trimmed = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $true
    }

    if ($trimmed.StartsWith("#") -or $trimmed.StartsWith("/")) {
        return $true
    }

    if ($trimmed -match '^(?i)([a-z][a-z0-9+.-]*:|//)') {
        return $true
    }

    return $false
}

function Get-LocalReferenceCandidates([string]$Content) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $patterns = @(
        '\b(?:src|href|poster)\s*=\s*["'']([^"'']+)["'']',
        '\bsrcset\s*=\s*["'']([^"'']+)["'']'
    )

    foreach ($pattern in $patterns) {
        foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $value = $match.Groups[1].Value
            if ($pattern -like '*srcset*') {
                foreach ($entry in ($value -split ',')) {
                    $srcsetCandidate = ($entry.Trim() -split '\s+')[0]
                    if (-not [string]::IsNullOrWhiteSpace($srcsetCandidate)) {
                        Add-UniqueString -List $candidates -Value $srcsetCandidate
                    }
                }
            } else {
                Add-UniqueString -List $candidates -Value $value
            }
        }
    }

    return @($candidates)
}

function Resolve-LocalFixtureReferencePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FixturePath,
        [Parameter(Mandatory = $true)]
        [string]$Reference
    )

    if (Test-IgnoredLocalAssetReference $Reference) {
        return $null
    }

    $decoded = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
    $relativeReference = (($decoded -split '#', 2)[0] -split '\?', 2)[0]
    if ([string]::IsNullOrWhiteSpace($relativeReference)) {
        return $null
    }

    $fixtureDir = Split-Path -Parent $FixturePath
    $fullFixtureDir = [System.IO.Path]::GetFullPath($fixtureDir).TrimEnd('\', '/')
    $combined = Join-Path $fixtureDir ($relativeReference -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $resolved = [System.IO.Path]::GetFullPath($combined)
    $directoryPrefix = $fullFixtureDir + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($directoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $displayPath = ($relativeReference -replace '\\', '/').TrimStart('./')
    return [pscustomobject]@{
        full_path = $resolved
        display_path = $displayPath
    }
}

function Get-MissingLocalFixtureAssets([string]$FixturePath) {
    $content = Get-Content -LiteralPath $FixturePath -Raw
    $missing = [System.Collections.Generic.List[string]]::new()

    foreach ($reference in (Get-LocalReferenceCandidates -Content $content)) {
        $resolved = Resolve-LocalFixtureReferencePath -FixturePath $FixturePath -Reference $reference
        if (-not $resolved) {
            continue
        }

        if (-not (Test-Path -LiteralPath $resolved.full_path)) {
            Add-UniqueString -List $missing -Value $resolved.display_path
        }
    }

    return @($missing)
}

$runner = Join-Path $PSScriptRoot "run_localhost_html_validation_recommended.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google-style attached HTML validation runner not found: $runner"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}
$resolvedPageRoot = if ($PageRoot) {
    (Resolve-Path -LiteralPath $PageRoot).Path
} else {
    $null
}
$resolvedInputPath = switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" { @() }
    "InputPath" { @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }) }
    default { Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle }
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

$autoGoogleStyleFixture = if ($PSCmdlet.ParameterSetName -eq "Auto") {
    $resolvedInputPath |
        ForEach-Object { Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue } |
        Where-Object { $_ -and (Test-GoogleStyleFixture $_) } |
        Select-Object -First 1
} else {
    $null
}

if ($PSCmdlet.ParameterSetName -eq "Auto" -and -not $autoGoogleStyleFixture) {
    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $resolvedRepoRoot)
    throw "No Google-style attached HTML files were found under: $($searchRoots -join '; '). Use .\scripts\windows\show_attached_html_validation_flow.ps1 or .\scripts\windows\run_localhost_html_validation_recommended.ps1 for non-Google attached pages."
}

$missingAssetAudit = @()
if ($PSCmdlet.ParameterSetName -ne "PageRoot") {
    $missingAssetAudit = @(
        $resolvedInputPath | ForEach-Object {
            $missing = @(Get-MissingLocalFixtureAssets -FixturePath $_)
            [pscustomobject]@{
                path = $_
                missing_assets = $missing
                missing_asset_count = $missing.Count
            }
        }
    )
}

$arguments = @{
    Host = $Host
    Port = $Port
    GoogleStyle = $true
    RepoRoot = $resolvedRepoRoot
}
if ($BrowserExe) {
    $arguments.BrowserExe = $BrowserExe
}
if ($resolvedPreferredInitialPage) {
    $arguments.PreferredInitialPage = $resolvedPreferredInitialPage
}
if ($SummaryOnly) {
    $arguments.SummaryOnly = $true
}
if ($Wait) {
    $arguments.Wait = $true
}
if ($LeaveServerRunning) {
    $arguments.LeaveServerRunning = $true
}

Write-Host "Google-style attached HTML validation"
Write-Host ""
Write-Host "Mode: attached HTML auto-discovery with the Google-style localhost follow-up"
switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        Write-Host ("Mode detail: explicit page root ({0})" -f $resolvedPageRoot)
    }
    "InputPath" {
        Write-Host ("Mode detail: explicit saved HTML inputs ({0}) locked before launch." -f $resolvedInputPath.Count)
    }
    default {
        Write-Host ("Mode detail: auto-discovered attached HTML inputs ({0}) locked before launch." -f $resolvedInputPath.Count)
    }
}
if ($PSCmdlet.ParameterSetName -eq "Auto") {
    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $resolvedRepoRoot)
    if ($searchRoots.Count -gt 0) {
        Write-Host "Search roots:"
        foreach ($root in $searchRoots) {
            Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $resolvedRepoRoot))
        }
    }
}
if ($resolvedInputPath.Count -gt 0) {
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot
}
if ($resolvedPreferredInitialPage) {
    Write-Host ""
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
    }
}
if ($missingAssetAudit.Count -gt 0) {
    $fixturesWithMissingAssets = @($missingAssetAudit | Where-Object { $_.missing_asset_count -gt 0 })
    if ($fixturesWithMissingAssets.Count -gt 0) {
        Write-Warning "Some attached HTML files reference sibling local assets that are missing from the current workspace. The localhost-headed follow-up may render or behave differently until those files are restored."
        foreach ($fixture in $fixturesWithMissingAssets) {
            Write-Host ("Missing assets: {0}" -f (Convert-ToDisplayPath -Path $fixture.path -RepoRoot $resolvedRepoRoot))
            Write-Host ("  Count: {0}" -f $fixture.missing_asset_count)
            foreach ($asset in ($fixture.missing_assets | Select-Object -First 5)) {
                Write-Host ("  - {0}" -f $asset)
            }
            if ($fixture.missing_asset_count -gt 5) {
                Write-Host ("  - ... {0} more" -f ($fixture.missing_asset_count - 5))
            }
        }
        Write-Host ""
    }
}
Write-Host "Override: use -PreferredInitialPage to pin the first Google-like page, or pass -PageRoot / -InputPath to skip auto-discovery."
if ($SummaryOnly) {
    Write-Host "Launch mode: summary only"
} elseif ($Wait) {
    Write-Host "Launch mode: launch and wait"
}
Write-Host "Runner: .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle"
Write-Host ""

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        & $runner @arguments -PageRoot $resolvedPageRoot
        exit $LASTEXITCODE
    }
    default {
        & $runner @arguments -InputPath $resolvedInputPath
        exit $LASTEXITCODE
    }
}