[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [string]$RepoRoot,
    [string]$OutputPath
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

function Test-LocalAssetReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Reference
    )

    if ([string]::IsNullOrWhiteSpace($Reference)) {
        return $false
    }

    if ($Reference.StartsWith("#")) {
        return $false
    }

    if ($Reference -match "^(?i:https?:|data:|mailto:|tel:|javascript:|//)") {
        return $false
    }

    return $true
}

function Normalize-LocalAssetReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Reference
    )

    $trimmed = $Reference.Trim()
    $withoutQuery = ($trimmed -split "[?#]", 2)[0]
    if ([string]::IsNullOrWhiteSpace($withoutQuery)) {
        return ""
    }

    $normalized = $withoutQuery -replace "/", [System.IO.Path]::DirectorySeparatorChar
    return [System.Uri]::UnescapeDataString($normalized)
}

function Get-LocalAssetReferences {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $matches = [System.Text.RegularExpressions.Regex]::Matches(
        $Content,
        "(?:src|href)\s*=\s*(['\""])(?<ref>[^'\""]+)\1",
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    $references = [System.Collections.Generic.List[string]]::new()
    foreach ($match in $matches) {
        $reference = $match.Groups["ref"].Value
        if (-not (Test-LocalAssetReference -Reference $reference)) {
            continue
        }

        if (-not $references.Contains($reference)) {
            $references.Add($reference) | Out-Null
        }
    }

    return @($references)
}

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

if (-not $PageRoot -and (-not $InputPath -or $InputPath.Count -eq 0)) {
    throw "either PageRoot or InputPath is required"
}

$resolvedRoots = [System.Collections.Generic.List[string]]::new()
if ($InputPath -and $InputPath.Count -gt 0) {
    foreach ($input in $InputPath) {
        $resolvedInput = (Resolve-Path -LiteralPath $input).Path
        $item = Get-Item -LiteralPath $resolvedInput
        if ($item.PSIsContainer) {
            if (-not $resolvedRoots.Contains($resolvedInput)) {
                $resolvedRoots.Add($resolvedInput) | Out-Null
            }
            continue
        }

        if (-not (Test-HtmlFilePath -Path $resolvedInput)) {
            continue
        }

        $parent = Split-Path -Parent $resolvedInput
        if (-not $resolvedRoots.Contains($parent)) {
            $resolvedRoots.Add($parent) | Out-Null
        }
    }
} else {
    $resolvedPageRoot = (Resolve-Path -LiteralPath $PageRoot).Path
    $resolvedRoots.Add($resolvedPageRoot) | Out-Null
}

$htmlFiles = foreach ($root in $resolvedRoots) {
    Get-ChildItem -LiteralPath $root -Recurse -File |
        Where-Object { Test-HtmlFilePath -Path $_.FullName }
} | Sort-Object FullName -Unique

if (-not $OutputPath) {
    $artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\manual-user\localhost-html-validation"
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
    $OutputPath = Join-Path $artifactRoot ("saved-page-local-asset-check-" + $timestamp + ".json")
}

$pageResults = @()
foreach ($htmlFile in $htmlFiles) {
    $content = Get-Content -LiteralPath $htmlFile.FullName -Raw
    $references = Get-LocalAssetReferences -Content $content
    $missingReferences = [System.Collections.Generic.List[string]]::new()

    foreach ($reference in $references) {
        $normalizedReference = Normalize-LocalAssetReference -Reference $reference
        if ([string]::IsNullOrWhiteSpace($normalizedReference)) {
            continue
        }

        $candidatePath = Join-Path (Split-Path -Parent $htmlFile.FullName) $normalizedReference
        if (-not (Test-Path -LiteralPath $candidatePath)) {
            $missingReferences.Add($reference) | Out-Null
        }
    }

    $rootForFile = $resolvedRoots |
        Where-Object { $htmlFile.FullName.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) } |
        Sort-Object Length -Descending |
        Select-Object -First 1
    if (-not $rootForFile) {
        $rootForFile = Split-Path -Parent $htmlFile.FullName
    }

    $pageResults += [pscustomobject]@{
        relative_path = Get-ForwardRelativePath -Root $rootForFile -Path $htmlFile.FullName
        title = Get-HtmlTitle -Content $content
        local_reference_count = $references.Count
        missing_local_reference_count = $missingReferences.Count
        has_missing_local_references = $missingReferences.Count -gt 0
        missing_local_references = @($missingReferences)
    }
}

$summary = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    roots_checked = @($resolvedRoots)
    page_count = $pageResults.Count
    pages_with_missing_local_references = @($pageResults | Where-Object { $_.has_missing_local_references } | Select-Object -ExpandProperty relative_path)
    pages = $pageResults
    next_step = "If pages are missing sibling assets, treat the localhost pass as partial snapshot validation until the missing files or folders are restored."
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding Ascii

Write-Host ("Saved local-asset summary: {0}" -f $OutputPath)
Write-Host ("Pages checked: {0}" -f $summary.page_count)
if ($summary.pages_with_missing_local_references.Count -gt 0) {
    Write-Host ("Pages with missing local references: {0}" -f ($summary.pages_with_missing_local_references -join ", "))
} else {
    Write-Host "All checked pages have their local asset references present."
}
Write-Host ("Next step: {0}" -f $summary.next_step)
