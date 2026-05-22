[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$OfflineBundleRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $cursor "build.zig") -PathType Leaf) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the repo root from $StartPath. Pass -RepoRoot to override."
        }

        $cursor = $parent
    }
}

function Get-MinimumZigVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRootPath
    )

    $zonPath = Join-Path $RepoRootPath "build.zig.zon"
    if (-not (Test-Path -LiteralPath $zonPath -PathType Leaf)) {
        throw "build.zig.zon not found at $zonPath"
    }

    $content = Get-Content -LiteralPath $zonPath -Raw
    $match = [regex]::Match($content, '\.minimum_zig_version\s*=\s*"([^"]+)"')
    if (-not $match.Success) {
        throw "Could not read .minimum_zig_version from $zonPath"
    }

    return $match.Groups[1].Value
}

function Write-Check {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [bool]$Passed,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}: {2}" -f $status, $Label, $Detail)
}

function Write-Warn {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    Write-Host ("[WARN] {0}: {1}" -f $Label, $Detail)
}

function Test-DependencyDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Check -Label $Label -Passed $false -Detail ("missing directory {0}" -f $Path)
        return $false
    }

    $buildPath = Join-Path $Path "build.zig"
    if (-not (Test-Path -LiteralPath $buildPath -PathType Leaf)) {
        Write-Check -Label $Label -Passed $false -Detail ("directory exists but build.zig is missing at {0}" -f $buildPath)
        return $false
    }

    Write-Check -Label $Label -Passed $true -Detail $Path
    return $true
}

function Test-OfflineBundleRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Check -Label "offline bundle root" -Passed $false -Detail ("missing directory {0}" -f $Path)
        return $false
    }

    $patterns = @(
        "brotli*.tar.gz",
        "zlib*.tar.gz",
        "nghttp2*.tar.gz",
        "curl*.tar.gz"
    )

    $allPresent = $true
    foreach ($pattern in $patterns) {
        $matches = Get-ChildItem -LiteralPath $Path -Filter $pattern -File -ErrorAction SilentlyContinue
        if (-not $matches) {
            Write-Check -Label ("offline bundle " + $pattern) -Passed $false -Detail "no matching archive found"
            $allPresent = $false
            continue
        }

        $sample = $matches[0].FullName
        Write-Check -Label ("offline bundle " + $pattern) -Passed $true -Detail $sample
    }

    return $allPresent
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$minimumZigVersion = Get-MinimumZigVersion -RepoRootPath $RepoRoot
$dependencyParent = Split-Path $RepoRoot -Parent

Write-Host "Headed build dependency layout check"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Expected minimum Zig version: {0}" -f $minimumZigVersion)
Write-Host ""

$failureCount = 0

Write-Check -Label "repo root" -Passed (Test-Path -LiteralPath (Join-Path $RepoRoot "build.zig") -PathType Leaf) -Detail $RepoRoot
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot "build.zig") -PathType Leaf)) {
    $failureCount += 1
}

$zigPath = Get-Command zig -ErrorAction SilentlyContinue
if ($zigPath) {
    $zigVersion = (& zig version).Trim()
    $zigMatches = $zigVersion -eq $minimumZigVersion
    Write-Check -Label "zig version" -Passed $zigMatches -Detail ("found {0} at {1}" -f $zigVersion, $zigPath.Source)
    if (-not $zigMatches) {
        $failureCount += 1
        Write-Warn -Label "zig version" -Detail ("This branch currently declares {0} in build.zig.zon. A newer toolchain may still fail in untouched files before headed-mode regressions can be isolated." -f $minimumZigVersion)
    }
} else {
    Write-Check -Label "zig command" -Passed $false -Detail "zig is not on PATH"
    $failureCount += 1
}

$cargoPath = Get-Command cargo -ErrorAction SilentlyContinue
if ($cargoPath) {
    $cargoVersion = (& cargo --version).Trim()
    Write-Check -Label "cargo" -Passed $true -Detail ("{0} at {1}" -f $cargoVersion, $cargoPath.Source)
} else {
    Write-Check -Label "cargo" -Passed $false -Detail "cargo is not on PATH"
    $failureCount += 1
}

$v8Path = Join-Path $dependencyParent "zig-v8-fork"
if (-not (Test-DependencyDir -Label "v8 sibling" -Path $v8Path)) {
    $failureCount += 1
}

$boringSslPath = Join-Path $dependencyParent "boringssl-zig"
if (-not (Test-DependencyDir -Label "boringssl sibling" -Path $boringSslPath)) {
    $failureCount += 1
}

if ($OfflineBundleRoot) {
    if (-not (Test-OfflineBundleRoot -Path ([System.IO.Path]::GetFullPath($OfflineBundleRoot)))) {
        $failureCount += 1
    }
} else {
    Write-Warn -Label "offline bundle root" -Detail "Pass -OfflineBundleRoot when you want this check to confirm locally staged brotli, zlib, nghttp2, and curl archives before an offline build."
}

Write-Host ""
if ($failureCount -eq 0) {
    Write-Host "Result: build dependency layout looks ready for the next headed-mode build attempt."
    exit 0
}

Write-Host ("Result: found {0} blocking build-readiness issue(s)." -f $failureCount)
Write-Host "Next steps:"
Write-Host "- Keep the browser repo beside ../zig-v8-fork and ../boringssl-zig."
Write-Host ("- Use Zig {0} for this branch unless the branch metadata changes." -f $minimumZigVersion)
Write-Host "- If you are building offline, rerun this script with -OfflineBundleRoot pointing at the staged brotli, zlib, nghttp2, and curl archives."
exit 1
