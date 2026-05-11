[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [int]$TitlePort = 9582,
    [int]$HomePort = 8168,
    [int]$InputPhasePort = 8178,
    [int]$WatchPort = 9582,
    [int]$SharedLabelPort = 8153,
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$InlineFlowPort = 8148,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$ReducedHomeKeypressPort = 8167,
    [int]$SubmitTimingPort = 8181,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
    [switch]$ManualGoogleStyle,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_validation_surface.ps1"
$quickRunner = Join-Path $PSScriptRoot "run_google_quick_validation.ps1"
$sharedRunner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"

foreach ($path in @($surfaceCheck, $quickRunner, $sharedRunner)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required ordered validation helper not found: $path"
    }
}

function Invoke-OrderedStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments
    )

    Write-Host ""
    Write-Host ("=== {0} ===" -f $Label)
    Write-Host ("Script: {0}" -f $ScriptPath)

    if ($Arguments) {
        & $ScriptPath @Arguments
    } else {
        & $ScriptPath
    }
}

function Copy-Hashtable {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Source
    )

    $copy = @{}
    foreach ($key in $Source.Keys) {
        $copy[$key] = $Source[$key]
    }
    return $copy
}

Write-Host "Google ordered validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Browser exe: {0}" -f $BrowserExe)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Input text: {0}" -f $InputText)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Write-Host ("Manual HTML follow-up: {0}" -f (($ManualInputPath | ForEach-Object { $_ }) -join ", "))
}
if ($ManualGoogleStyle) {
    Write-Host "Manual HTML mode: google-style attached follow-up"
}

$sharedBaseArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    InputText = $InputText
    SharedInputText = $SharedInputText
    EnterMutationSuffix = $EnterMutationSuffix
    LocalhostPort = $LocalhostPort
    HomePort = $HomePort
    InputPhasePort = $InputPhasePort
    SharedLabelPort = $SharedLabelPort
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    InlineFlowPort = $InlineFlowPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    SharedEnterOrderPort = $SharedEnterOrderPort
    ReducedHomeKeypressPort = $ReducedHomeKeypressPort
    SubmitTimingPort = $SubmitTimingPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
if ($LeaveOpen) {
    $sharedBaseArgs.LeaveOpen = $true
}

Invoke-OrderedStep -Label "google-validation-surface" -ScriptPath $surfaceCheck -Arguments @{
    Profile = "issue3"
    RepoRoot = $RepoRoot
}

$localhostArgs = Copy-Hashtable $sharedBaseArgs
$localhostArgs.Phase = "localhost"
Invoke-OrderedStep -Label "google-localhost" -ScriptPath $sharedRunner -Arguments $localhostArgs

$quickArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    InputText = $InputText
    TitlePort = $TitlePort
    WatchPort = $WatchPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
}
if ($LeaveOpen) {
    $quickArgs.LeaveOpen = $true
}
Invoke-OrderedStep -Label "google-quick" -ScriptPath $quickRunner -Arguments $quickArgs

$homeArgs = Copy-Hashtable $sharedBaseArgs
$homeArgs.Phase = "home"
Invoke-OrderedStep -Label "google-home" -ScriptPath $sharedRunner -Arguments $homeArgs

$inputPhaseArgs = Copy-Hashtable $sharedBaseArgs
$inputPhaseArgs.Phase = "input-phase-localhost"
Invoke-OrderedStep -Label "google-input-phase-localhost" -ScriptPath $sharedRunner -Arguments $inputPhaseArgs

$submitTimingArgs = Copy-Hashtable $sharedBaseArgs
$submitTimingArgs.Phase = "submit-timing"
Invoke-OrderedStep -Label "google-submit-timing" -ScriptPath $sharedRunner -Arguments $submitTimingArgs

$sharedEnterOrderArgs = Copy-Hashtable $sharedBaseArgs
$sharedEnterOrderArgs.Phase = "shared-enter-order"
$sharedEnterOrderArgs.TitleProbePort = $TitlePort
Invoke-OrderedStep -Label "google-shared-enter-order" -ScriptPath $sharedRunner -Arguments $sharedEnterOrderArgs

if (($ManualInputPath -and $ManualInputPath.Count -gt 0) -or $ManualGoogleStyle) {
    $manualArgs = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Phase = "manual"
        Host = $Host
        ManualPort = $ManualPort
    }
    if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
        $manualArgs.ManualInputPath = $ManualInputPath
    }
    if ($ManualInitialPage) {
        $manualArgs.ManualInitialPage = $ManualInitialPage
    }
    if ($ManualGoogleStyle) {
        $manualArgs.ManualGoogleStyle = $true
    }
    if ($LeaveOpen) {
        $manualArgs.LeaveOpen = $true
    }
    Invoke-OrderedStep -Label "google-manual" -ScriptPath $sharedRunner -Arguments $manualArgs
}

Write-Host ""
if (($ManualInputPath -and $ManualInputPath.Count -gt 0) -or $ManualGoogleStyle) {
    Write-Host "Next: compare the saved-page follow-up with the reduced homepage and submit-timing results, then use run_google_input_validation.ps1 -Phase trace only if live Google still diverges."
} else {
    Write-Host "Next: move on to the smallest manual or live Google replay, then use run_google_input_validation.ps1 -Phase trace only if the reduced and shared gates stay green while the real homepage still diverges."
}
