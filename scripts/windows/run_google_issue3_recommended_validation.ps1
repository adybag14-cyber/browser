[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$TraceInputText = "lightpanda",
    [int]$TitlePort = 9582,
    [int]$HomePort = 8168,
    [int]$HomepageFixturePort = 8155,
    [int]$WatchPort = 9582,
    [int]$SharedLabelPort = 8153,
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$InlineFlowPort = 8148,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$SubmitTimingPort = 8181,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
    [switch]$ManualGoogleStyle,
    [switch]$LeaveOpen,
    [switch]$SkipAutoAttachedHtml
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

function Test-GoogleStyleAttachedHtmlAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
    if ($searchRoots.Count -eq 0) {
        return $false
    }

    $googleFixture = Get-AttachedHtmlCandidates -RepoRoot $RepoRoot |
        Where-Object { Test-GoogleStyleFixture $_ } |
        Select-Object -First 1

    return [bool]$googleFixture
}

function Resolve-GoogleStyleAttachedHtmlSelection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $resolvedInputPath = @(Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle)
    if ($resolvedInputPath.Count -eq 0) {
        return $null
    }

    $resolvedInitialPage = Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
    return [ordered]@{
        InputPath = $resolvedInputPath
        InitialPage = $resolvedInitialPage
    }
}

$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$homepageFixtureRunner = Join-Path $PSScriptRoot "run_google_homepage_fixture_validation.ps1"
if (-not (Test-Path -LiteralPath $homepageFixtureRunner -PathType Leaf)) {
    throw "Google homepage fixture validation runner not found: $homepageFixtureRunner"
}

$autoAttachedHtml = $false
$autoAttachedSelection = $null
if (-not $SkipAutoAttachedHtml -and -not $ManualGoogleStyle -and -not ($ManualInputPath -and $ManualInputPath.Count -gt 0)) {
    $autoAttachedHtml = Test-GoogleStyleAttachedHtmlAvailable -RepoRoot $RepoRoot
    if ($autoAttachedHtml) {
        $autoAttachedSelection = Resolve-GoogleStyleAttachedHtmlSelection -RepoRoot $RepoRoot
    }
}

$basePhaseArguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    LocalhostPort = $LocalhostPort
    InputText = $InputText
    SharedInputText = $SharedInputText
    TraceInputText = $TraceInputText
    TitlePort = $TitlePort
    HomePort = $HomePort
    WatchPort = $WatchPort
    SharedLabelPort = $SharedLabelPort
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    InlineFlowPort = $InlineFlowPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    SharedEnterOrderPort = $SharedEnterOrderPort
    SubmitTimingPort = $SubmitTimingPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
    TraceWindowReadyAttempts = $TraceWindowReadyAttempts
    TracePollMilliseconds = $TracePollMilliseconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
    ManualPort = $ManualPort
}
if ($LeaveOpen) {
    $basePhaseArguments.LeaveOpen = $true
}

$manualPhaseEnabled = ($ManualInputPath -and $ManualInputPath.Count -gt 0) -or $ManualGoogleStyle -or [bool]$autoAttachedSelection
$resolvedManualInputPath = $ManualInputPath
$resolvedManualInitialPage = $ManualInitialPage
$resolvedManualGoogleStyle = [bool]$ManualGoogleStyle
if ($autoAttachedSelection) {
    $resolvedManualInputPath = $autoAttachedSelection.InputPath
    if (-not $resolvedManualInitialPage -and $autoAttachedSelection.InitialPage) {
        $resolvedManualInitialPage = $autoAttachedSelection.InitialPage
    }
    $resolvedManualGoogleStyle = $true
}

$manualPhaseUsesFixtureSelection = $resolvedManualInputPath -and $resolvedManualInputPath.Count -gt 0
$manualPhaseAssetAudit = if ($manualPhaseUsesFixtureSelection) {
    @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedManualInputPath)
} else {
    @()
}

function Invoke-RecommendedPhase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $phaseArguments = $basePhaseArguments.Clone()
    $phaseArguments.Phase = $Phase
    if ($Phase -eq "manual") {
        if ($resolvedManualInputPath -and $resolvedManualInputPath.Count -gt 0) {
            $phaseArguments.ManualInputPath = $resolvedManualInputPath
        }
        if ($resolvedManualInitialPage) {
            $phaseArguments.ManualInitialPage = $resolvedManualInitialPage
        }
        if ($resolvedManualGoogleStyle) {
            $phaseArguments.ManualGoogleStyle = $true
        }
    }

    & $runner @phaseArguments
}

function Invoke-HomepageFixturePhase {
    $fixtureArguments = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        FixturePort = $HomepageFixturePort
        InputText = $SharedInputText
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        HomeWindowReadyAttempts = $HomeWindowReadyAttempts
        HomeTitleWaitAttempts = $HomeTitleWaitAttempts
        HomePollMilliseconds = $HomePollMilliseconds
    }
    if ($LeaveOpen) {
        $fixtureArguments.LeaveOpen = $true
    }

    & $homepageFixtureRunner @fixtureArguments
}

if ($manualPhaseUsesFixtureSelection) {
    if ($autoAttachedSelection) {
        Write-Host ("Issue #3 recommended runner: Google-style attached HTML files were detected in the current search roots, so the Google-style manual localhost follow-up will run automatically with {0} locked fixture(s)." -f $resolvedManualInputPath.Count)
    } elseif ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
        Write-Host ("Issue #3 recommended runner: Using {0} explicit saved or attached HTML fixture(s) for the manual follow-up." -f $resolvedManualInputPath.Count)
    }

    Show-FixtureSelectionSummary -FixturePaths $resolvedManualInputPath -RepoRoot $RepoRoot
    if ($resolvedManualInitialPage) {
        Write-Host ("Issue #3 recommended runner: Manual follow-up initial page: {0}" -f $resolvedManualInitialPage)
    }
    Show-MissingLocalFixtureAssetWarnings -AssetAudit $manualPhaseAssetAudit -RepoRoot $RepoRoot
}

Invoke-RecommendedPhase -Phase "localhost"
Invoke-RecommendedPhase -Phase "title"
Invoke-RecommendedPhase -Phase "home"
Invoke-HomepageFixturePhase
Invoke-RecommendedPhase -Phase "submit-timing"
Invoke-RecommendedPhase -Phase "shared-enter-order"
Invoke-RecommendedPhase -Phase "watch"
if ($manualPhaseEnabled) {
    Invoke-RecommendedPhase -Phase "manual"
}
