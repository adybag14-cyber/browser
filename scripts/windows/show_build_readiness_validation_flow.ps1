[CmdletBinding()]
param(
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "browser-shell", "google-attached-html", "google-form-controls-enter-order", "google-input", "google-shared-enter-order", "input", "manual-html", "navigation", "network", "popup", "rendering", "stop-loading")]
    [string]$NextChangeArea = "",
    [string]$RepoRoot = ""
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
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }
        $cursor = $parent
    }
}

function Get-MinimumZigVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRepoRoot
    )

    $zonPath = Join-Path $TargetRepoRoot "build.zig.zon"
    if (-not (Test-Path $zonPath)) {
        return $null
    }

    $match = Select-String -Path $zonPath -Pattern '\.minimum_zig_version\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($null -eq $match -or $match.Matches.Count -eq 0) {
        return $null
    }

    return $match.Matches[0].Groups[1].Value
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Write-Route {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Commands,
        [string[]]$Notes = @()
    )

    Write-Host ""
    Write-Host ("[{0}]" -f $Name)
    foreach ($command in $Commands) {
        Write-Host ("  {0}" -f $command)
    }

    foreach ($note in $Notes) {
        Write-Host ("  note: {0}" -f $note)
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

$minimumZigVersion = Get-MinimumZigVersion -TargetRepoRoot $RepoRoot
$routerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1"
if (-not [string]::IsNullOrWhiteSpace($NextChangeArea)) {
    $routerCommand += " -ChangeArea $NextChangeArea"
}

Write-Section "build-readiness"
Write-Host "Use this route before deeper headed validation when Zig, sibling dependencies, or build caches may have drifted."
if ($minimumZigVersion) {
    Write-Host ("build.zig.zon minimum_zig_version: {0}" -f $minimumZigVersion)
}
Write-Host ("Repo root: {0}" -f $RepoRoot)

Write-Route -Name "prereqs" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_lightpanda_windows_prereqs.ps1"
) -Notes @(
    "Run this first. It checks Zig presence, compares the current toolchain against build.zig.zon, verifies the expected ../zig-v8-fork and ../boringssl-zig sibling paths, and confirms Python and WSL availability.",
    "If ZigBranchCompatibility fails on the attached 0.17.0-dev.299 fallback, stop and switch to a 0.15.2-compatible toolchain or the repo's normal CI-aligned build path before blaming headed-mode source changes."
)

Write-Route -Name "fresh-cache-retry" -Commands @(
    "zig build --help",
    "zig build test --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover"
) -Notes @(
    "Use this after the prerequisite check passes when the first failure still looks like cache drift or a cold dependency/bootstrap path.",
    "The explicit recover cache dirs keep the retry separated from the default caches so you can tell cache corruption apart from a real source regression."
)

Write-Route -Name "artifact-report-and-cleanup" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -CleanBuildCaches"
) -Notes @(
    "Use the report command first so you can see whether the repo is carrying stale recover caches, slice outputs, or large dependency state before deleting anything.",
    "Use -CleanBuildCaches after a successful recover-cache build, or before one more clean retry, when you want the default .zig-cache path reset without deleting the expensive dependency caches."
)

Write-Route -Name "headed-validation-hand-off" -Commands @(
    $routerCommand
) -Notes @(
    "Move to the headed validation router only after the prerequisite check is green and the recover-cache retry no longer fails in untouched branch files.",
    "Pass -NextChangeArea when you already know the follow-up lane, for example rendering, input, network, browser-shell, popup, or attached-html."
)
