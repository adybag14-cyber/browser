[CmdletBinding()]
param(
    [ValidateSet("all", "basic", "correction", "enter-order", "delayed-ready")]
    [string]$Probe = "all",
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8176,
    [string]$InputText = "QZ",
    [string]$CorrectionWrongSuffix = "W",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 25,
    [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$probeRoot = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next"
$probeTable = [ordered]@{
    basic = [ordered]@{
        Label = "google-style-localhost"
        ScriptPath = Join-Path $probeRoot "google-style-localhost-probe.ps1"
        UsesCorrectionWrongSuffix = $false
    }
    correction = [ordered]@{
        Label = "google-style-correction-localhost"
        ScriptPath = Join-Path $probeRoot "google-style-correction-localhost-probe.ps1"
        UsesCorrectionWrongSuffix = $true
    }
    "enter-order" = [ordered]@{
        Label = "google-enter-order-localhost"
        ScriptPath = Join-Path $probeRoot "google-enter-order-localhost-probe.ps1"
        UsesCorrectionWrongSuffix = $false
    }
    "delayed-ready" = [ordered]@{
        Label = "google-style-delayed-ready-localhost"
        ScriptPath = Join-Path $probeRoot "google-style-delayed-ready-localhost-probe.ps1"
        UsesCorrectionWrongSuffix = $false
    }
}

function Invoke-LocalhostProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $entry = $probeTable[$Name]
    if (-not $entry) {
        throw "Unknown localhost probe: $Name"
    }
    if (-not (Test-Path -LiteralPath $entry.ScriptPath -PathType Leaf)) {
        throw "Localhost probe script not found: $($entry.ScriptPath)"
    }

    $arguments = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $Port
        InputText = $InputText
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        WindowReadyAttempts = $WindowReadyAttempts
        TitleWaitAttempts = $TitleWaitAttempts
        PollMilliseconds = $PollMilliseconds
    }
    if ($entry.UsesCorrectionWrongSuffix) {
        $arguments.CorrectionWrongSuffix = $CorrectionWrongSuffix
    }

    Write-Host ""
    Write-Host ("=== {0} ===" -f $entry.Label)
    Write-Host ("Script: {0}" -f $entry.ScriptPath)
    & $entry.ScriptPath @arguments
}

switch ($Probe) {
    "all" {
        foreach ($name in $probeTable.Keys) {
            Invoke-LocalhostProbe -Name $name
        }
    }
    default {
        Invoke-LocalhostProbe -Name $Probe
    }
}

Write-Host ""
switch ($Probe) {
    "basic" {
        Write-Host "Next: use -Probe correction, -Probe enter-order, or -Probe delayed-ready to isolate the first localhost follow-up that still diverges before moving on to the title or reduced-homepage passes."
    }
    "correction" {
        Write-Host "Next: use -Probe enter-order or -Probe delayed-ready to check the next localhost gate before the title or reduced-homepage passes."
    }
    "enter-order" {
        Write-Host "Next: use -Probe delayed-ready, the title pass, or the reduced-homepage pass once the localhost keypress-before-submit gate stays green."
    }
    "delayed-ready" {
        Write-Host "Next: move on to the title pass or reduced-homepage pass once the localhost delayed-readiness gate stays green."
    }
    default {
        Write-Host "Next: rerun with -Probe basic, -Probe correction, -Probe enter-order, or -Probe delayed-ready when you want to isolate the first failing localhost gate before the title, reduced-homepage, submit-timing, or shared Enter-order passes."
    }
}
