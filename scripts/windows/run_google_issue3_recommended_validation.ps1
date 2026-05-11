[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [string]$TraceInputText = "lightpanda",
    [int]$TitlePort = 9582,
    [int]$TitleProbePort = 8159,
    [int]$HomePort = 8168,
    [int]$HomepageFixturePort = 8155,
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
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
    [string]$SummaryPath,
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

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot "google-issue3-recommended-validation-summary.json"
}
if (Test-Path -LiteralPath $SummaryPath) {
    Remove-Item -LiteralPath $SummaryPath -Force
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

$surfaceCheck = Join-Path $PSScriptRoot "check_google_issue3_recommended_validation_surface.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google issue #3 recommended validation surface checker not found: $surfaceCheck"
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
    EnterMutationSuffix = $EnterMutationSuffix
    TraceInputText = $TraceInputText
    TitlePort = $TitlePort
    TitleProbePort = $TitleProbePort
    HomePort = $HomePort
    InputPhasePort = $InputPhasePort
    WatchPort = $WatchPort
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

function Invoke-RecommendedStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString("o")
    try {
        & $Action
        return [pscustomobject]@{
            name = $Name
            status = "passed"
            started_at_utc = $startedAt
            completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            error = $null
        }
    } catch {
        return [pscustomobject]@{
            name = $Name
            status = "failed"
            started_at_utc = $startedAt
            completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            error = $_.Exception.Message
        }
    }
}

function Show-RecommendedSummary {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PhaseResults
    )

    Write-Host ""
    Write-Host "Issue #3 recommended validation summary"
    foreach ($result in $PhaseResults) {
        $status = if ($result.status -eq "passed") { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.name)
        if ($result.error) {
            Write-Host ("  {0}" -f $result.error)
        }
    }
    Write-Host ("Summary JSON: {0}" -f $SummaryPath)
}

function Write-RecommendedSummaryArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PhaseResults,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckStatus,
        [string]$SurfaceCheckError
    )

    $failedPhase = @($PhaseResults | Where-Object { $_.status -ne "passed" } | Select-Object -First 1)
    $passedPhaseCount = @($PhaseResults | Where-Object { $_.status -eq "passed" }).Count
    $summary = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        host = $Host
        summary_path = $SummaryPath
        leave_open = [bool]$LeaveOpen
        skip_auto_attached_html = [bool]$SkipAutoAttachedHtml
        auto_attached_html_detected = [bool]$autoAttachedHtml
        surface_check_script = $surfaceCheck
        surface_check_status = $SurfaceCheckStatus
        surface_check_error = $SurfaceCheckError
        manual_phase_enabled = [bool]$manualPhaseEnabled
        manual_phase_google_style = [bool]$resolvedManualGoogleStyle
        manual_phase_uses_fixture_selection = [bool]$manualPhaseUsesFixtureSelection
        manual_initial_page = $resolvedManualInitialPage
        manual_input_path = @($resolvedManualInputPath)
        missing_fixture_asset_audit = @($manualPhaseAssetAudit)
        phase_plan = @($phasePlan | ForEach-Object { $_.Name })
        phase_count = @($PhaseResults).Count
        passed_phase_count = $passedPhaseCount
        phase_results = @($PhaseResults)
        first_failed_phase = if ($failedPhase.Count -gt 0) { $failedPhase[0].name } else { $null }
        first_failed_phase_error = if ($failedPhase.Count -gt 0) { $failedPhase[0].error } else { $null }
        completed = ($failedPhase.Count -eq 0 -and $SurfaceCheckStatus -eq "passed")
    }

    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path $SummaryPath -Encoding Ascii
}

$phasePlan = [System.Collections.Generic.List[object]]::new()
$phasePlan.Add([pscustomobject]@{ Name = "localhost"; Action = { Invoke-RecommendedPhase -Phase "localhost" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "quick"; Action = { Invoke-RecommendedPhase -Phase "quick" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "home"; Action = { Invoke-RecommendedPhase -Phase "home" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "homepage-fixture"; Action = { Invoke-HomepageFixturePhase } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "input-phase-localhost"; Action = { Invoke-RecommendedPhase -Phase "input-phase-localhost" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "submit-timing"; Action = { Invoke-RecommendedPhase -Phase "submit-timing" } }) | Out-Null
$phasePlan.Add([pscustomobject]@{ Name = "shared-enter-order"; Action = { Invoke-RecommendedPhase -Phase "shared-enter-order" } }) | Out-Null
if ($manualPhaseEnabled) {
    $phasePlan.Add([pscustomobject]@{ Name = "manual"; Action = { Invoke-RecommendedPhase -Phase "manual" } }) | Out-Null
}

Write-Host "Google issue #3 recommended validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Summary JSON: {0}" -f $SummaryPath)
Write-Host ""
Write-Host "=== google-issue3-recommended-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)

$surfaceCheckStatus = "passed"
$surfaceCheckError = $null
$phaseResults = [System.Collections.Generic.List[object]]::new()
try {
    & $surfaceCheck -RepoRoot $RepoRoot
} catch {
    $surfaceCheckStatus = "failed"
    $surfaceCheckError = $_.Exception.Message
    Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError
    throw ("Google issue #3 recommended validation surface check failed: {0}. Summary JSON: {1}" -f $surfaceCheckError, $SummaryPath)
}
Write-Host ""

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

foreach ($step in $phasePlan) {
    $stepResult = Invoke-RecommendedStep -Name $step.Name -Action $step.Action
    $phaseResults.Add($stepResult) | Out-Null
    if ($stepResult.status -ne "passed") {
        break
    }
}

Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError
Show-RecommendedSummary -PhaseResults @($phaseResults)

$failedPhase = @($phaseResults | Where-Object { $_.status -ne "passed" } | Select-Object -First 1)
if ($failedPhase.Count -gt 0) {
    throw ("Google issue #3 recommended validation stopped at phase '{0}': {1}. Summary JSON: {2}" -f $failedPhase[0].name, $failedPhase[0].error, $SummaryPath)
}
