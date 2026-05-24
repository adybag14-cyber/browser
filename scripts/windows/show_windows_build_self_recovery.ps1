param(
    [string]$RepoRoot = $env:LIGHTPANDA_REPO_ROOT,
    [switch]$PrintCommandsOnly
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

function Quote-ForDisplay {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    return '"' + $Text.Replace('"', '""') + '"'
}

function Write-StepHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    if ($PrintCommandsOnly) {
        return
    }

    Write-Host ""
    Write-Host $Title
}

function Write-CommandLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Write-Host $Command
}

$RepoRoot = Resolve-RepoRoot -Candidate $RepoRoot
$quotedRepoRoot = Quote-ForDisplay -Text $RepoRoot

if (-not $PrintCommandsOnly) {
    Write-Host "Lightpanda Windows build self-recovery helper"
    Write-Host ("RepoRoot: {0}" -f $RepoRoot)
    Write-Host ""
    Write-Host "Use this after a headed Windows build stalls or fails before direct compiler diagnostics."
}

Write-StepHeader -Title "1. Inspect known build processes before assuming the cache is bad"
Write-CommandLine ("powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -RepoRoot {0} -ListKnownBuildProcesses" -f $quotedRepoRoot)

Write-StepHeader -Title "2. Stop only confirmed orphaned build processes if the report shows stale runners"
Write-CommandLine ("powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -RepoRoot {0} -StopKnownBuildProcesses" -f $quotedRepoRoot)

Write-StepHeader -Title "3. Capture fresh default-cache build logs"
Write-CommandLine ("Set-Location -LiteralPath {0}" -f $quotedRepoRoot)
Write-CommandLine 'zig build -Dtarget=x86_64-windows-msvc --summary all 1> tmp-current-build.stdout.txt 2> tmp-current-build.stderr.txt'

Write-StepHeader -Title "4. If the default cache path still looks unhealthy, validate the toolchain directly"
Write-CommandLine ("Set-Location -LiteralPath {0}" -f $quotedRepoRoot)
Write-CommandLine 'zig build --help'
Write-CommandLine '$probeSource = @'''
Write-CommandLine 'const std = @import("std");'
Write-CommandLine 'pub fn main() void {'
Write-CommandLine '    std.debug.print("build-self-recovery probe ok\\n", .{});'
Write-CommandLine '}'
Write-CommandLine '''@'
Write-CommandLine '$probeSource | Set-Content -LiteralPath .\tmp-build-self-recovery-probe.zig -Encoding UTF8'
Write-CommandLine 'zig build-exe .\tmp-build-self-recovery-probe.zig -femit-bin=.\tmp-build-self-recovery-probe.exe'

Write-StepHeader -Title "5. Retry with fresh cache directories before editing source"
Write-CommandLine ("Set-Location -LiteralPath {0}" -f $quotedRepoRoot)
Write-CommandLine 'zig build -Dtarget=x86_64-windows-msvc --summary all --cache-dir .zig-cache-recover --global-cache-dir .zig-global-cache-recover 1> tmp-current-build.stdout.txt 2> tmp-current-build.stderr.txt'

Write-StepHeader -Title "6. If the fresh-cache retry works, clean the temporary recovery caches and logs"
Write-CommandLine ("powershell -ExecutionPolicy Bypass -File .\scripts\windows\manage_build_artifacts.ps1 -RepoRoot {0} -CleanBuildCaches -CleanSliceOutputs" -f $quotedRepoRoot)

Write-StepHeader -Title "7. Remove the temporary toolchain probe once you are done"
Write-CommandLine ("Set-Location -LiteralPath {0}" -f $quotedRepoRoot)
Write-CommandLine 'Remove-Item -LiteralPath .\tmp-build-self-recovery-probe.zig, .\tmp-build-self-recovery-probe.exe -Force -ErrorAction SilentlyContinue'

if (-not $PrintCommandsOnly) {
    Write-Host ""
    Write-Host "If fresh-cache builds still fail without direct parser, type, or linker diagnostics, prefer fixing the toolchain or environment before changing headed-mode source files."
}
