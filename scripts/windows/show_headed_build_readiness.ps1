Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [string]$RepoRoot
)

function Write-Section {
    param([string]$Name)
    Write-Host ""
    Write-Host ("== {0} ==" -f $Name)
}

function Write-Check {
    param(
        [string]$Name,
        [bool]$Ok,
        [string]$Details
    )
    $mark = if ($Ok) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1} - {2}" -f $mark, $Name, $Details)
}

function Resolve-RepoRoot {
    param([string]$StartPath)

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return [System.IO.Path]::GetFullPath($RepoRoot)
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            return $null
        }
        $cursor = $parent
    }
}

function Get-CommandVersion {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    try {
        $output = & $Command @Arguments 2>&1
        if ($LASTEXITCODE -ne 0 -or $null -eq $output) {
            return $null
        }
        return ($output | Select-Object -First 1).ToString().Trim()
    } catch {
        return $null
    }
}

function Get-MinimumZigVersion {
    param([string]$ResolvedRepoRoot)

    if ([string]::IsNullOrWhiteSpace($ResolvedRepoRoot)) {
        return $null
    }

    $zonPath = Join-Path $ResolvedRepoRoot "build.zig.zon"
    if (-not (Test-Path $zonPath)) {
        return $null
    }

    $match = Select-String -Path $zonPath -Pattern '\.minimum_zig_version\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($null -eq $match -or $match.Matches.Count -eq 0) {
        return $null
    }

    return $match.Matches[0].Groups[1].Value
}

function Get-SemVerCore {
    param([string]$VersionText)

    if ([string]::IsNullOrWhiteSpace($VersionText)) {
        return $null
    }

    $match = [regex]::Match($VersionText, '(\d+\.\d+\.\d+)')
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value
}

function Test-VersionAtLeast {
    param(
        [string]$VersionText,
        [string]$MinimumText
    )

    $versionCore = Get-SemVerCore -VersionText $VersionText
    $minimumCore = Get-SemVerCore -VersionText $MinimumText
    if ([string]::IsNullOrWhiteSpace($versionCore) -or [string]::IsNullOrWhiteSpace($minimumCore)) {
        return $false
    }

    try {
        return ([version]$versionCore -ge [version]$minimumCore)
    } catch {
        return $false
    }
}

function Test-PathMarkers {
    param(
        [string]$Path,
        [string[]]$Markers
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path -PathType Container)) {
        return $false
    }

    foreach ($marker in $Markers) {
        if (-not (Test-Path (Join-Path $Path $marker))) {
            return $false
        }
    }

    return $true
}

function Test-RemoteDependencyUrl {
    param(
        [string]$ZonPath,
        [string]$DependencyName
    )

    if (-not (Test-Path $ZonPath)) {
        return $false
    }

    $pattern = '{0}\s*=\s*\{{[\s\S]*?url\s*=' -f [regex]::Escape($DependencyName)
    $raw = Get-Content -Path $ZonPath -Raw
    return [regex]::IsMatch($raw, $pattern)
}

$resolvedRepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
$zonPath = if ($resolvedRepoRoot) { Join-Path $resolvedRepoRoot "build.zig.zon" } else { $null }
$minimumZigVersion = Get-MinimumZigVersion -ResolvedRepoRoot $resolvedRepoRoot
$zigVersion = Get-CommandVersion -Command "zig" -Arguments @("version")
$allOk = $true

Write-Section "Repo"
if ($resolvedRepoRoot) {
    Write-Check "RepoRoot" $true $resolvedRepoRoot
} else {
    Write-Check "RepoRoot" $false "could not resolve a checkout containing build.zig"
    $allOk = $false
}

Write-Section "Toolchain"
$minimumOk = -not [string]::IsNullOrWhiteSpace($minimumZigVersion)
Write-Check "MinimumZigVersion" $minimumOk ($(if ($minimumOk) { $minimumZigVersion } else { "build.zig.zon minimum_zig_version not found" }))
if (-not $minimumOk) { $allOk = $false }

$zigOk = -not [string]::IsNullOrWhiteSpace($zigVersion)
Write-Check "ZigInPath" $zigOk ($(if ($zigOk) { "zig {0}" -f $zigVersion } else { "zig not found in PATH" }))
if (-not $zigOk) { $allOk = $false }

$branchCompatOk = $zigOk -and $minimumOk
$branchCompatDetails = "insufficient data"
if ($branchCompatOk) {
    if ($zigVersion -like "0.17.0-dev.299*") {
        $branchCompatOk = $false
        $branchCompatDetails = "attached 0.17.0-dev.299 fallback is known to fail in untouched branch files before focused headed validation; prefer a 0.15.2-compatible toolchain or the repo's normal CI-aligned build path"
    } elseif (-not (Test-VersionAtLeast -VersionText $zigVersion -MinimumText $minimumZigVersion)) {
        $branchCompatOk = $false
        $branchCompatDetails = "zig {0} is older than build.zig.zon minimum {1}" -f $zigVersion, $minimumZigVersion
    } else {
        $branchCompatDetails = "zig {0} satisfies build.zig.zon minimum {1}" -f $zigVersion, $minimumZigVersion
    }
}
Write-Check "BranchZigCompatibility" $branchCompatOk $branchCompatDetails
if (-not $branchCompatOk) { $allOk = $false }

Write-Section "Sibling Dependencies"
$parentRoot = if ($resolvedRepoRoot) { Split-Path $resolvedRepoRoot -Parent } else { $null }
$zigV8Path = if ($parentRoot) { Join-Path $parentRoot "zig-v8-fork" } else { $null }
$boringSslPath = if ($parentRoot) { Join-Path $parentRoot "boringssl-zig" } else { $null }

$zigV8Ok = Test-PathMarkers -Path $zigV8Path -Markers @("build.zig", "build.zig.zon")
Write-Check "zig-v8-fork" $zigV8Ok ($(if ($zigV8Ok) { $zigV8Path } else { "missing or incomplete sibling checkout at ../zig-v8-fork" }))
if (-not $zigV8Ok) { $allOk = $false }

$boringSslOk = Test-PathMarkers -Path $boringSslPath -Markers @("build.zig", "README.md")
Write-Check "boringssl-zig" $boringSslOk ($(if ($boringSslOk) { $boringSslPath } else { "missing or incomplete sibling checkout at ../boringssl-zig" }))
if (-not $boringSslOk) { $allOk = $false }

Write-Section "Offline Linux Or WSL Dependencies"
$remoteDeps = @()
foreach ($dep in @("brotli", "zlib", "nghttp2", "curl")) {
    if ($zonPath -and (Test-RemoteDependencyUrl -ZonPath $zonPath -DependencyName $dep)) {
        $remoteDeps += $dep
    }
}

if ($remoteDeps.Count -gt 0) {
    Write-Check "RemotePackageUrls" $false ("build.zig.zon still resolves these through remote URLs: {0}" -f ($remoteDeps -join ", "))
    Write-Host "Plan: stage an offline cache or a throwaway local path rewrite before treating Linux or WSL build failures as browser regressions."
} else {
    Write-Check "RemotePackageUrls" $true "no tracked remote package URLs found for brotli, zlib, nghttp2, or curl"
}

Write-Section "Next"
if ($allOk) {
    Write-Host "Ready: proceed to the normal headed build for this checkout."
    Write-Host "Command: zig build -Dtarget=x86_64-windows-msvc --summary all"
    exit 0
}

Write-Host "Not ready: fix the failed checks before reopening headed validation."
Write-Host "First commands:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_lightpanda_windows_prereqs.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_build_readiness.ps1"
Write-Host "  zig build --help"
exit 1
