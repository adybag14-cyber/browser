[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$RepoRoot,
    [switch]$GoogleStyle,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-DeepLocalReferenceCandidates([string]$Content) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $patterns = @(
        '\b(?:src|href|poster)\s*=\s*["'']([^"'']+)["'']',
        '\bsrcset\s*=\s*["'']([^"'']+)["'']',
        '@import\s+(?:url\()?\s*["'']?([^"'')\s;]+)',
        'url\(\s*["'']?([^"'')]+)["'']?\s*\)'
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

function Get-DeepMissingLocalFixtureAssets([string]$FixturePath) {
    $pending = [System.Collections.Generic.Queue[string]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenCss = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $missing = [System.Collections.Generic.List[string]]::new()
    $inspected = [System.Collections.Generic.List[string]]::new()

    $pending.Enqueue($FixturePath)
    $null = $visited.Add([System.IO.Path]::GetFullPath($FixturePath))

    while ($pending.Count -gt 0) {
        $currentPath = $pending.Dequeue()
        Add-UniqueString -List $inspected -Value $currentPath

        $content = ""
        try {
            $content = Get-Content -LiteralPath $currentPath -Raw -ErrorAction Stop
        } catch {
            Add-UniqueString -List $missing -Value ("unreadable:" + $currentPath)
            continue
        }

        foreach ($reference in (Get-DeepLocalReferenceCandidates -Content $content)) {
            $resolved = Resolve-LocalFixtureReferencePath -FixturePath $currentPath -Reference $reference
            if (-not $resolved) {
                continue
            }

            if (-not (Test-Path -LiteralPath $resolved.full_path)) {
                Add-UniqueString -List $missing -Value $resolved.display_path
                continue
            }

            $extension = [System.IO.Path]::GetExtension($resolved.full_path)
            if ([string]::Equals($extension, ".css", [System.StringComparison]::OrdinalIgnoreCase)) {
                $fullResolvedPath = [System.IO.Path]::GetFullPath($resolved.full_path)
                if ($seenCss.Add($fullResolvedPath) -and -not $visited.Contains($fullResolvedPath)) {
                    $null = $visited.Add($fullResolvedPath)
                    $pending.Enqueue($fullResolvedPath)
                }
            }
        }
    }

    return [pscustomobject]@{
        missing_assets = @($missing)
        missing_asset_count = $missing.Count
        inspected_files = @($inspected)
        inspected_file_count = $inspected.Count
        inspected_css_files = @($seenCss)
        inspected_css_file_count = $seenCss.Count
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
}

$audit = @(
    $resolvedInputPath | ForEach-Object {
        $result = Get-DeepMissingLocalFixtureAssets -FixturePath $_
        [pscustomobject]@{
            path = $_
            display_path = Convert-ToDisplayPath -Path $_ -RepoRoot $RepoRoot
            missing_assets = $result.missing_assets
            missing_asset_count = $result.missing_asset_count
            inspected_files = $result.inspected_files | ForEach-Object { Convert-ToDisplayPath -Path $_ -RepoRoot $RepoRoot }
            inspected_file_count = $result.inspected_file_count
            inspected_css_file_count = $result.inspected_css_file_count
        }
    }
)

$summary = [ordered]@{
    repo_root = $RepoRoot
    google_style = [bool]$GoogleStyle
    fixture_count = $audit.Count
    fixtures = $audit
    fixtures_with_missing_assets = @($audit | Where-Object { $_.missing_asset_count -gt 0 }).Count
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 7
} else {
    Write-Host "Attached HTML local asset closure audit"
    Write-Host ""
    foreach ($fixture in $audit) {
        Write-Host ("Fixture: {0}" -f $fixture.display_path)
        Write-Host ("Inspected files: {0}" -f $fixture.inspected_file_count)
        Write-Host ("Inspected CSS files: {0}" -f $fixture.inspected_css_file_count)
        if ($fixture.missing_asset_count -eq 0) {
            Write-Host "Missing assets: none"
        } else {
            Write-Host ("Missing assets: {0}" -f $fixture.missing_asset_count)
            foreach ($asset in ($fixture.missing_assets | Select-Object -First 10)) {
                Write-Host ("- {0}" -f $asset)
            }
            if ($fixture.missing_asset_count -gt 10) {
                Write-Host ("- ... {0} more" -f ($fixture.missing_asset_count - 10))
            }
        }
        Write-Host ""
    }
}

if ($summary.fixtures_with_missing_assets -gt 0) {
    exit 1
}
