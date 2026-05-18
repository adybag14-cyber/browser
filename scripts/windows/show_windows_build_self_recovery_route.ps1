[CmdletBinding()]
param(
    [string]$RepoRoot = $env:LIGHTPANDA_REPO_ROOT,
    [ValidateSet("", "attached-html", "google-input", "input", "navigation", "network", "rendering", "stop-loading")]
    [string]$NextChangeArea = "",
    [switch]$Json
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

function New-RouteStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Commands,
        [string[]]$Notes = @()
    )

    return [pscustomobject]@{
        Name = $Name
        Commands = @($Commands)
        Notes = @($Notes)
    }
}

$resolvedRepoRoot = Resolve-RepoRoot -Candidate $RepoRoot
$routerCommand = if ([string]::IsNullOrWhiteSpace($NextChangeArea)) {
    'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1'
} else {
    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea $NextChangeArea"
}

$steps = @(
    (New-RouteStep -Name 'prereqs' -Commands @(
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_lightpanda_windows_prereqs.ps1'
    ) -Notes @(
        'Run this first so missing symlink capability, Zig, or WSL support is visible before the build logs send you in the wrong direction.'
    )),
    (New-RouteStep -Name 'self-recovery' -Commands @(
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\invoke_headed_build_self_recovery.ps1',
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\invoke_headed_build_self_recovery.ps1 -Json | Set-Content -Path .\\tmp-headed-build-self-recovery.json'
    ) -Notes @(
        'Use the default invocation for a normal recovery pass.',
        'Use the JSON form when you want a saved recovery summary alongside the captured stdout and stderr logs.'
    )),
    (New-RouteStep -Name 'read-logs' -Commands @(
        'Get-Content .\\tmp-current-build.stderr.txt',
        'Get-Content .\\tmp-current-build.stdout.txt'
    ) -Notes @(
        'Read stderr first when the helper reports direct diagnostics.',
        'Treat build.exe: FileNotFound as cache state, and GetLastError(5): Access is denied as an environment restriction until proven otherwise.'
    )),
    (New-RouteStep -Name 'cleanup-after-fresh-cache-success' -Commands @(
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\manage_build_artifacts.ps1 -CleanBuildCaches'
    ) -Notes @(
        'Only do this after the fresh-cache retry succeeded and you are restoring the normal build path.'
    )),
    (New-RouteStep -Name 'return-to-validation' -Commands @(
        $routerCommand
    ) -Notes @(
        'Once the default build path is healthy again, reopen the headed validation router and continue with the smallest matching probe family.'
    ))
)

if ($Json) {
    [ordered]@{
        repo_root = $resolvedRepoRoot
        next_change_area = $NextChangeArea
        route = @($steps)
        companion_docs = @(
            'docs/WINDOWS_BUILD_SELF_RECOVERY.md',
            'docs/WINDOWS_BUILD_SELF_RECOVERY_ROUTE.md',
            'docs/WINDOWS_FULL_USE.md'
        )
    } | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Windows build self-recovery route'
Write-Host ''
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)

foreach ($step in $steps) {
    Write-Host ''
    Write-Host ("[{0}]" -f $step.Name)
    foreach ($command in $step.Commands) {
        Write-Host ("  {0}" -f $command)
    }
    foreach ($note in $step.Notes) {
        Write-Host ("  note: {0}" -f $note)
    }
}
