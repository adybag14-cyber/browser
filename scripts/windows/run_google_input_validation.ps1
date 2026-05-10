[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [ValidateSet("localhost", "home", "watch", "all")]
    [string]$Phase = "all",
    [switch]$IncludeWatch,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$probeRoot = Join-Path $RepoRoot "tmp-browser-smoke"
$googleLocalhostRoot = Join-Path $probeRoot "google-investigation-next"
$googleHomeProbe = Join-Path $probeRoot "google-home\chrome-google-home-enter-probe.ps1"
$watchProbe = Join-Path $scriptRoot "watch_headed_probe.ps1"

$localhostProbes = @(
    "google-style-localhost-probe.ps1",
    "google-style-correction-localhost-probe.ps1",
    "google-enter-order-localhost-probe.ps1",
    "google-style-delayed-ready-localhost-probe.ps1"
)

function Invoke-ProbeScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "Probe script not found: $ScriptPath"
    }

    Write-Host ("")
    Write-Host ("=== {0} ===" -f $Label)
    Write-Host ("Script: {0}" -f $ScriptPath)

    if ($Arguments) {
        & $ScriptPath @Arguments
    } else {
        & $ScriptPath
    }
}

function Invoke-LocalhostSequence {
    foreach ($probeName in $localhostProbes) {
        $scriptPath = Join-Path $googleLocalhostRoot $probeName
        Invoke-ProbeScript -Label $probeName -ScriptPath $scriptPath
    }
}

function Invoke-HomeSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
    }
    Invoke-ProbeScript -Label "google-home-enter" -ScriptPath $googleHomeProbe -Arguments $args
}

function Invoke-WatchSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        InputText = "QZ"
        ExpectedTypedTitleContains = "TYPED:QZ"
        SendEnter = $true
        ExpectedEnterTitleContains = "SUBMIT:QZ"
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home-watch" -ScriptPath $watchProbe -Arguments $args
}

Write-Host "Google headed-input validation runner"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Phase: {0}" -f $Phase)

switch ($Phase) {
    "localhost" {
        Invoke-LocalhostSequence
    }
    "home" {
        Invoke-HomeSequence
    }
    "watch" {
        Invoke-WatchSequence
    }
    "all" {
        Invoke-LocalhostSequence
        Invoke-HomeSequence
        if ($IncludeWatch) {
            Invoke-WatchSequence
        }
    }
}

Write-Host ("")
if ($Phase -eq "watch" -or $IncludeWatch) {
    Write-Host "Next: move on to the smallest live Google manual pass once the watcher confirms SUBMIT:QZ."
} else {
    Write-Host "Next: use -IncludeWatch or -Phase watch for the longer title-stream pass before the smallest live Google manual check."
}
