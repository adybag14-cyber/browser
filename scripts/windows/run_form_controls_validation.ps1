[CmdletBinding()]
param(
    [ValidateSet("all", "label", "default-enter", "deferred-enter")]
    [string]$Probe = "all",
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "Q",
    [int]$LabelPort = 8153,
    [int]$DefaultEnterPort = 8154,
    [int]$DeferredEnterPort = 8155,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250
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

$probeRoot = Join-Path $RepoRoot "tmp-browser-smoke\form-controls"
$probeTable = [ordered]@{
    label = [ordered]@{
        Label = "label-click"
        ScriptPath = Join-Path $probeRoot "label-click-probe.ps1"
        Port = $LabelPort
        DeferredEnter = $false
        UsesInputText = $false
    }
    "default-enter" = [ordered]@{
        Label = "enter-submit-default"
        ScriptPath = Join-Path $probeRoot "enter-submit-probe.ps1"
        Port = $DefaultEnterPort
        DeferredEnter = $false
        UsesInputText = $true
    }
    "deferred-enter" = [ordered]@{
        Label = "enter-submit-deferred"
        ScriptPath = Join-Path $probeRoot "enter-submit-probe.ps1"
        Port = $DeferredEnterPort
        DeferredEnter = $true
        UsesInputText = $true
    }
}

function Invoke-FormControlsProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $entry = $probeTable[$Name]
    if (-not $entry) {
        throw "Unknown form-controls probe: $Name"
    }
    if (-not (Test-Path -LiteralPath $entry.ScriptPath -PathType Leaf)) {
        throw "Form-controls probe script not found: $($entry.ScriptPath)"
    }

    $arguments = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $entry.Port
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        WindowReadyAttempts = $WindowReadyAttempts
        TitleWaitAttempts = $TitleWaitAttempts
        PollMilliseconds = $PollMilliseconds
    }
    if ($entry.UsesInputText) {
        $arguments.InputText = $InputText
    }
    if ($entry.DeferredEnter) {
        $arguments.DeferredEnter = $true
    }

    Write-Host ""
    Write-Host ("=== {0} ===" -f $entry.Label)
    Write-Host ("Script: {0}" -f $entry.ScriptPath)
    & $entry.ScriptPath @arguments
}

Write-Host "Form-controls headed validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Label port: {0}" -f $LabelPort)
Write-Host ("Default Enter port: {0}" -f $DefaultEnterPort)
Write-Host ("Deferred Enter port: {0}" -f $DeferredEnterPort)
Write-Host ""

switch ($Probe) {
    "all" {
        foreach ($name in $probeTable.Keys) {
            Invoke-FormControlsProbe -Name $name
        }
    }
    default {
        Invoke-FormControlsProbe -Name $Probe
    }
}

Write-Host ""
switch ($Probe) {
    "label" {
        Write-Host "Next: use -Probe default-enter and -Probe deferred-enter to confirm the shared Enter-submit gates before moving on to inline-flow or Google-specific probes."
    }
    "default-enter" {
        Write-Host "Next: use -Probe deferred-enter to check the pending-submit gate, then move on to inline-flow or the smaller Google localhost passes."
    }
    "deferred-enter" {
        Write-Host "Next: if the deferred Enter gate stays green, move on to the shared Enter-order or reduced Google localhost probes."
    }
    default {
        Write-Host "Next: if the shared label and Enter gates stay green, move on to inline-flow, google-shared-enter-order, or the reduced Google localhost probes."
    }
}
