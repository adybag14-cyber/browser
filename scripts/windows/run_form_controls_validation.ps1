[CmdletBinding()]
param(
    [ValidateSet("all", "label", "default-enter", "deferred-enter", "google-title", "reduced-google-home", "google-enter-order")]
    [string]$Probe = "all",
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "Q",
    [int]$LabelPort = 8153,
    [int]$DefaultEnterPort = 8154,
    [int]$DeferredEnterPort = 8155,
    [int]$GoogleTitlePort = 9582,
    [int]$ReducedGoogleHomePort = 8156,
    [int]$GoogleEnterOrderPort = 8157,
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
        GoogleEnterOrder = $false
        UsesInputText = $false
    }
    "default-enter" = [ordered]@{
        Label = "enter-submit-default"
        ScriptPath = Join-Path $probeRoot "enter-submit-probe.ps1"
        Port = $DefaultEnterPort
        DeferredEnter = $false
        GoogleEnterOrder = $false
        UsesInputText = $true
    }
    "deferred-enter" = [ordered]@{
        Label = "enter-submit-deferred"
        ScriptPath = Join-Path $probeRoot "enter-submit-probe.ps1"
        Port = $DeferredEnterPort
        DeferredEnter = $true
        GoogleEnterOrder = $false
        UsesInputText = $true
    }
    "google-title" = [ordered]@{
        Label = "google-home-title"
        ScriptPath = Join-Path $scriptRoot "run_google_home_title_probe.ps1"
        Port = $GoogleTitlePort
        DeferredEnter = $false
        GoogleEnterOrder = $false
        UsesInputText = $true
    }
    "reduced-google-home" = [ordered]@{
        Label = "google-home-enter-submit"
        ScriptPath = Join-Path $probeRoot "chrome-google-home-enter-submit-probe.ps1"
        Port = $ReducedGoogleHomePort
        DeferredEnter = $false
        GoogleEnterOrder = $false
        UsesInputText = $true
    }
    "google-enter-order" = [ordered]@{
        Label = "google-enter-order"
        ScriptPath = Join-Path $probeRoot "enter-submit-probe.ps1"
        Port = $GoogleEnterOrderPort
        DeferredEnter = $false
        GoogleEnterOrder = $true
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
    if ($entry.GoogleEnterOrder) {
        $arguments.GoogleEnterOrder = $true
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
Write-Host ("Google title port: {0}" -f $GoogleTitlePort)
Write-Host ("Reduced Google-home port: {0}" -f $ReducedGoogleHomePort)
Write-Host ("Google enter-order port: {0}" -f $GoogleEnterOrderPort)
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
        Write-Host "Next: use -Probe default-enter and -Probe deferred-enter to confirm the shared Enter-submit gates before moving on to the Google-style form probes."
    }
    "default-enter" {
        Write-Host "Next: use -Probe deferred-enter to check the pending-submit gate, then move on to -Probe google-title before the reduced Google-home submit path."
    }
    "deferred-enter" {
        Write-Host "Next: if the deferred Enter gate stays green, move on to -Probe google-title, then widen to -Probe reduced-google-home and -Probe google-enter-order."
    }
    "google-title" {
        Write-Host "Next: if the reduced Google title gate stays green, use -Probe reduced-google-home for the fuller reduced-home submit pass before the stricter -Probe google-enter-order gate."
    }
    "reduced-google-home" {
        Write-Host "Next: if the reduced Google-home submit gate stays green, use -Probe google-enter-order for the stricter keypress-before-submit localhost check."
    }
    "google-enter-order" {
        Write-Host "Next: if the stricter enter-order localhost check stays green, move on to the broader shared Google wrapper or the smallest live Google manual pass."
    }
    default {
        Write-Host "Next: if the shared label, Enter, reduced Google title, reduced Google-home, and enter-order gates stay green, move on to inline-flow, google-shared-enter-order, or the broader reduced Google localhost probes."
    }
}
