param(
    [string]$RepoRoot = $env:LIGHTPANDA_REPO_ROOT
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [string]$Candidate
    )

    $resolved = $Candidate
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    }

    $resolvedItem = Get-Item -LiteralPath $resolved -ErrorAction Stop
    if (-not $resolvedItem.PSIsContainer) {
        throw "RepoRoot must point to the Lightpanda repository directory."
    }

    return $resolvedItem.FullName
}

function Get-ZigVersion {
    $command = Get-Command zig -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }

    $output = & $command.Source version 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return ($output | Select-Object -First 1).Trim()
}

function Get-MinimumZigVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildZonPath
    )

    $match = Select-String -LiteralPath $BuildZonPath -Pattern '\.minimum_zig_version\s*=\s*"([^"]+)"'
    if ($null -eq $match) {
        throw "Could not find .minimum_zig_version in $BuildZonPath"
    }

    return $match.Matches[0].Groups[1].Value
}

function Compare-ZigVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Current,
        [Parameter(Mandatory = $true)]
        [string]$Required
    )

    if ($Current -eq $Required) {
        return 0
    }

    $currentRelease = ($Current -split '-dev', 2)[0]
    try {
        $currentVersion = [version]$currentRelease
        $requiredVersion = [version]$Required
    } catch {
        return $null
    }

    return $currentVersion.CompareTo($requiredVersion)
}

function Get-SiblingStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $path = Join-Path (Split-Path -Path $RepoRoot -Parent) $Name
    [pscustomobject]@{
        Name = $Name
        Path = $path
        Exists = Test-Path -LiteralPath $path
    }
}

$RepoRoot = Resolve-RepoRoot -Candidate $RepoRoot
$buildZonPath = Join-Path $RepoRoot "build.zig.zon"
if (-not (Test-Path -LiteralPath $buildZonPath)) {
    throw "Could not find build.zig.zon under $RepoRoot"
}

$requiredZigVersion = Get-MinimumZigVersion -BuildZonPath $buildZonPath
$currentZigVersion = Get-ZigVersion
$siblingDeps = @(
    Get-SiblingStatus -RepoRoot $RepoRoot -Name "zig-v8-fork"
    Get-SiblingStatus -RepoRoot $RepoRoot -Name "boringssl-zig"
)

Write-Host "Lightpanda Zig toolchain preflight"
Write-Host ""
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("build.zig.zon minimum Zig: {0}" -f $requiredZigVersion)
Write-Host ("Installed zig: {0}" -f ($(if ($currentZigVersion) { $currentZigVersion } else { "missing from PATH" })))
Write-Host ""

if ($currentZigVersion) {
    $comparison = Compare-ZigVersion -Current $currentZigVersion -Required $requiredZigVersion
    switch ($comparison) {
        0 {
            Write-Host "Status: OK - installed zig exactly matches the branch minimum."
        }
        { $_ -gt 0 } {
            Write-Warning ("Installed zig ({0}) is newer than the branch minimum ({1}). This fork has known validation failures under the saved 0.17-dev fallback, so prefer an exact 0.15.2 toolchain before blaming headed-mode source changes." -f $currentZigVersion, $requiredZigVersion)
        }
        { $_ -lt 0 } {
            Write-Warning ("Installed zig ({0}) is older than the branch minimum ({1}). Upgrade zig before retrying builds or tests." -f $currentZigVersion, $requiredZigVersion)
        }
        default {
            Write-Warning "Could not compare zig versions automatically. Check the version strings manually before retrying builds."
        }
    }
} else {
    Write-Warning "zig was not found on PATH."
}

Write-Host ""
Write-Host "Sibling dependency check:"
foreach ($dep in $siblingDeps) {
    $status = if ($dep.Exists) { "OK" } else { "MISSING" }
    Write-Host ("- {0}: {1} ({2})" -f $dep.Name, $status, $dep.Path)
}

Write-Host ""
Write-Host "Recommended next steps:"
Write-Host "1. Prefer Zig 0.15.2 for this fork before retrying branch validation."
Write-Host "2. Make sure the repo sits beside ../zig-v8-fork and ../boringssl-zig."
Write-Host "3. If Windows build startup still looks unhealthy, capture fresh logs with:"
Write-Host "   zig build -Dtarget=x86_64-windows-msvc --summary all 1> tmp-current-build.stdout.txt 2> tmp-current-build.stderr.txt"
Write-Host "4. If the first retry still looks cache-related, use fresh cache dirs:"
Write-Host "   zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover"
Write-Host "5. After a successful fresh-cache retry, clean only the transient build caches with:"
Write-Host "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\manage_build_artifacts.ps1 -CleanBuildCaches -CleanSliceOutputs"