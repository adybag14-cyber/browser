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
$surfaceCheckArtifactPath = Join-Path $artifactRoot "google-issue3-recommended-validation-surface.json"
$guideArtifactPath = Join-Path $artifactRoot "google-issue3-recommended-validation-guide.json"
$manifestArtifactPath = Join-Path $artifactRoot "google-issue3-recommended-validation-manifest.json"
$phaseBoundaryArtifactPath = Join-Path $artifactRoot "google-issue3-phase-boundary.json"
$phaseArtifactRoot = Join-Path $artifactRoot "google-issue3-recommended-validation-phases"
if (Test-Path -LiteralPath $SummaryPath) {
    Remove-Item -LiteralPath $SummaryPath -Force
}
if (Test-Path -LiteralPath $surfaceCheckArtifactPath) {
    Remove-Item -LiteralPath $surfaceCheckArtifactPath -Force
}
if (Test-Path -LiteralPath $guideArtifactPath) {
    Remove-Item -LiteralPath $guideArtifactPath -Force
}
if (Test-Path -LiteralPath $manifestArtifactPath) {
    Remove-Item -LiteralPath $manifestArtifactPath -Force
}
if (Test-Path -LiteralPath $phaseBoundaryArtifactPath) {
    Remove-Item -LiteralPath $phaseBoundaryArtifactPath -Force
}
if (Test-Path -LiteralPath $phaseArtifactRoot) {
    Remove-Item -LiteralPath $phaseArtifactRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $phaseArtifactRoot | Out-Null
$artifactScanRoots = @(
    $artifactRoot,
    (Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next"),
    (Join-Path $RepoRoot "tmp-browser-smoke\google-home"),
    (Join-Path $RepoRoot "tmp-browser-smoke\form-controls"),
    (Join-Path $RepoRoot "tmp-browser-smoke\layout-smoke"),
    (Join-Path $RepoRoot "tmp-browser-smoke\inline-flow")
)

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

function Convert-ToPhaseArtifactSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "phase"
    }
    return $slug
}

function Convert-ToRepoRelativeArtifactPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\\', '/')
    $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    if ($normalizedPath.StartsWith($normalizedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $normalizedPath.Substring($normalizedRepoRoot.Length).TrimStart('\\', '/')
        if (-not [string]::IsNullOrWhiteSpace($relative)) {
            return $relative -replace '\\', '/'
        }
    }

    return $normalizedPath
}

function Get-PhaseArtifactSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Roots
    )

    $snapshot = @{}
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $snapshot[$_.FullName] = "{0}:{1}" -f $_.Length, $_.LastWriteTimeUtc.Ticks
        }
    }

    return $snapshot
}

function Get-PhaseArtifactChanges {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Before,
        [Parameter(Mandatory = $true)]
        [string[]]$Roots
    )

    $artifactPaths = New-Object System.Collections.Generic.List[string]
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $signature = "{0}:{1}" -f $_.Length, $_.LastWriteTimeUtc.Ticks
            if (-not $Before.ContainsKey($_.FullName) -or $Before[$_.FullName] -ne $signature) {
                $artifactPaths.Add((Convert-ToRepoRelativeArtifactPath -Path $_.FullName)) | Out-Null
            }
        }
    }

    return @($artifactPaths | Sort-Object -Unique)
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_issue3_recommended_validation_surface.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
$summaryGuide = Join-Path $PSScriptRoot "show_google_issue3_validation_summary_guide.ps1"
$phaseBoundaryHelper = Join-Path $PSScriptRoot "show_google_issue3_phase_boundary.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google issue #3 recommended validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $summaryGuide -PathType Leaf)) {
    throw "Google issue #3 validation summary guide not found: $summaryGuide"
}
if (-not (Test-Path -LiteralPath $phaseBoundaryHelper -PathType Leaf)) {
    throw "Google issue #3 phase boundary helper not found: $phaseBoundaryHelper"
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

    $phaseSlug = Convert-ToPhaseArtifactSlug -Name $Name
    $phaseLogPath = Join-Path $phaseArtifactRoot ($phaseSlug + ".log")
    if (Test-Path -LiteralPath $phaseLogPath) {
        Remove-Item -LiteralPath $phaseLogPath -Force
    }

    $startedAt = (Get-Date).ToUniversalTime().ToString("o")
    $artifactSnapshot = Get-PhaseArtifactSnapshot -Roots $artifactScanRoots
    try {
        & $Action *>&1 | Tee-Object -FilePath $phaseLogPath -Append
        $artifactPaths = @(Get-PhaseArtifactChanges -Before $artifactSnapshot -Roots $artifactScanRoots)
        $jsonArtifactPaths = @($artifactPaths | Where-Object { $_ -like '*.json' })
        $primaryJsonArtifactPath = $jsonArtifactPaths | Select-Object -First 1
        return [pscustomobject]@{
            name = $Name
            status = "passed"
            started_at_utc = $startedAt
            completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            error = $null
            log_path = $phaseLogPath
            artifact_count = $artifactPaths.Count
            artifact_paths = @($artifactPaths)
            json_artifact_paths = @($jsonArtifactPaths)
            primary_json_artifact_path = $primaryJsonArtifactPath
        }
    } catch {
        $errorMessage = $_.Exception.Message
        $errorRecordText = ($_ | Out-String).TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($errorRecordText)) {
            Add-Content -Path $phaseLogPath -Value ""
            Add-Content -Path $phaseLogPath -Value $errorRecordText
        }

        $artifactPaths = @(Get-PhaseArtifactChanges -Before $artifactSnapshot -Roots $artifactScanRoots)
        $jsonArtifactPaths = @($artifactPaths | Where-Object { $_ -like '*.json' })
        $primaryJsonArtifactPath = $jsonArtifactPaths | Select-Object -First 1
        return [pscustomobject]@{
            name = $Name
            status = "failed"
            started_at_utc = $startedAt
            completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            error = $errorMessage
            log_path = $phaseLogPath
            artifact_count = $artifactPaths.Count
            artifact_paths = @($artifactPaths)
            json_artifact_paths = @($jsonArtifactPaths)
            primary_json_artifact_path = $primaryJsonArtifactPath
        }
    }
}

function Show-RecommendedSummary {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PhaseResults,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckArtifactPath,
        [Parameter(Mandatory = $true)]
        [string]$GuideArtifactPath,
        [Parameter(Mandatory = $true)]
        [string]$BoundaryArtifactPath,
        [Parameter(Mandatory = $true)]
        [string]$ManifestArtifactPath,
        [string]$GuideArtifactError,
        [string]$BoundaryArtifactError,
        $GuideRecord
    )

    Write-Host ""
    Write-Host "Issue #3 recommended validation summary"
    Write-Host ("Artifact root: {0}" -f $phaseArtifactRoot)
    foreach ($result in $PhaseResults) {
        $status = if ($result.status -eq "passed") { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.name)
        if ($result.log_path) {
            Write-Host ("  Log: {0}" -f $result.log_path)
        }
        if ($result.primary_json_artifact_path) {
            Write-Host ("  JSON: {0}" -f $result.primary_json_artifact_path)
        } elseif ($result.artifact_count -gt 0) {
            Write-Host ("  Artifacts: {0}" -f $result.artifact_count)
        }
        if ($result.error) {
            Write-Host ("  {0}" -f $result.error)
        }
    }
    Write-Host ("Surface JSON: {0}" -f $SurfaceCheckArtifactPath)
    Write-Host ("Summary JSON: {0}" -f $SummaryPath)
    Write-Host ("Guide JSON: {0}" -f $GuideArtifactPath)
    Write-Host ("Boundary JSON: {0}" -f $BoundaryArtifactPath)
    if ($BoundaryArtifactError) {
        Write-Host ("Boundary error: {0}" -f $BoundaryArtifactError)
    }
    Write-Host ("Manifest JSON: {0}" -f $ManifestArtifactPath)
    if ($GuideArtifactError) {
        Write-Host ("Guide error: {0}" -f $GuideArtifactError)
    } elseif ($GuideRecord) {
        if ($GuideRecord.first_failed_phase) {
            Write-Host ("First fail: {0}" -f $GuideRecord.first_failed_phase)
        }
        if ($GuideRecord.next_focus) {
            Write-Host ("Next focus: {0}" -f $GuideRecord.next_focus)
        }
        if ($GuideRecord.recommended_command) {
            Write-Host ("Run next: {0}" -f $GuideRecord.recommended_command)
        }
        if ($GuideRecord.manual_fixture_replay_command) {
            Write-Host ("Manual replay: {0}" -f $GuideRecord.manual_fixture_replay_command)
        }
    }
}

function Write-RecommendedSummaryArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PhaseResults,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckStatus,
        [string]$SurfaceCheckError,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckArtifactPath,
        $SurfaceCheckRecord,
        [string]$GuideArtifactPath,
        [string]$BoundaryArtifactPath,
        [string]$GuideArtifactError,
        [string]$BoundaryArtifactError
    )

    $failedPhase = @($PhaseResults | Where-Object { $_.status -ne "passed" } | Select-Object -First 1)
    $passedPhaseCount = @($PhaseResults | Where-Object { $_.status -eq "passed" }).Count
    $summary = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        host = $Host
        artifact_root = $artifactRoot
        phase_artifact_root = $phaseArtifactRoot
        summary_path = $SummaryPath
        guide_artifact_path = $GuideArtifactPath
        boundary_artifact_path = $BoundaryArtifactPath
        manifest_artifact_path = $manifestArtifactPath
        guide_artifact_error = $GuideArtifactError
        boundary_artifact_error = $BoundaryArtifactError
        leave_open = [bool]$LeaveOpen
        skip_auto_attached_html = [bool]$SkipAutoAttachedHtml
        auto_attached_html_detected = [bool]$autoAttachedHtml
        surface_check_script = $surfaceCheck
        surface_check_status = $SurfaceCheckStatus
        surface_check_error = $SurfaceCheckError
        surface_check_artifact_path = $SurfaceCheckArtifactPath
        surface_check_profile = if ($SurfaceCheckRecord) { $SurfaceCheckRecord.profile } else { $null }
        surface_check_checked_count = if ($SurfaceCheckRecord) { $SurfaceCheckRecord.checked_count } else { $null }
        surface_check_missing_count = if ($SurfaceCheckRecord) { $SurfaceCheckRecord.missing_count } else { $null }
        surface_check_missing_paths = if ($SurfaceCheckRecord) {
            @($SurfaceCheckRecord.references | Where-Object { -not $_.Exists } | ForEach-Object { $_.Path })
        } else {
            @()
        }
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
        first_failed_phase_log_path = if ($failedPhase.Count -gt 0) { $failedPhase[0].log_path } else { $null }
        first_failed_phase_primary_json_artifact_path = if ($failedPhase.Count -gt 0) { $failedPhase[0].primary_json_artifact_path } else { $null }
        completed = ($failedPhase.Count -eq 0 -and $SurfaceCheckStatus -eq "passed")
    }

    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path $SummaryPath -Encoding Ascii
}

function Write-RecommendedManifestArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PhaseResults,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckStatus,
        [string]$SurfaceCheckError,
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckArtifactPath,
        $SurfaceCheckRecord,
        [string]$GuideArtifactPath,
        [string]$BoundaryArtifactPath,
        [string]$GuideArtifactError,
        [string]$BoundaryArtifactError,
        $GuideRecord
    )

    $failedPhase = @($PhaseResults | Where-Object { $_.status -ne "passed" } | Select-Object -First 1)
    $manifest = [pscustomobject]@{
        issue = "Google issue #3 recommended validation manifest"
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        host = $Host
        artifact_root = $artifactRoot
        manifest_artifact_path = $manifestArtifactPath
        summary_path = $SummaryPath
        surface_check_artifact_path = $SurfaceCheckArtifactPath
        guide_artifact_path = $GuideArtifactPath
        boundary_artifact_path = $BoundaryArtifactPath
        guide_artifact_error = $GuideArtifactError
        boundary_artifact_error = $BoundaryArtifactError
        phase_artifact_root = $phaseArtifactRoot
        surface_check_status = $SurfaceCheckStatus
        surface_check_error = $SurfaceCheckError
        surface_check_profile = if ($SurfaceCheckRecord) { $SurfaceCheckRecord.profile } else { $null }
        surface_check_missing_count = if ($SurfaceCheckRecord) { $SurfaceCheckRecord.missing_count } else { $null }
        surface_check_missing_paths = if ($SurfaceCheckRecord) {
            @($SurfaceCheckRecord.references | Where-Object { -not $_.Exists } | ForEach-Object { $_.Path })
        } else {
            @()
        }
        completed = ($failedPhase.Count -eq 0 -and $SurfaceCheckStatus -eq "passed")
        first_failed_phase = if ($failedPhase.Count -gt 0) { $failedPhase[0].name } else { $null }
        first_failed_phase_log_path = if ($failedPhase.Count -gt 0) { $failedPhase[0].log_path } else { $null }
        first_failed_phase_primary_json_artifact_path = if ($failedPhase.Count -gt 0) { $failedPhase[0].primary_json_artifact_path } else { $null }
        recommended_command = if ($GuideRecord) { $GuideRecord.recommended_command } else { $null }
        recommended_guide_command = if ($GuideRecord) { $GuideRecord.recommended_guide_command } else { $null }
        manual_fixture_replay_available = if ($GuideRecord) { [bool]$GuideRecord.manual_fixture_replay_available } else { $false }
        manual_fixture_replay_command = if ($GuideRecord) { $GuideRecord.manual_fixture_replay_command } else { $null }
        manual_fixture_replay_reason = if ($GuideRecord) { $GuideRecord.manual_fixture_replay_reason } else { $null }
        next_focus = if ($GuideRecord) { $GuideRecord.next_focus } else { $null }
        phase_results = @($PhaseResults | ForEach-Object {
            [pscustomobject]@{
                name = $_.name
                status = $_.status
                log_path = $_.log_path
                artifact_count = $_.artifact_count
                artifact_paths = @($_.artifact_paths)
                json_artifact_paths = @($_.json_artifact_paths)
                primary_json_artifact_path = $_.primary_json_artifact_path
                error = $_.error
            }
        })
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestArtifactPath -Encoding Ascii
}

function Save-SurfaceCheckArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SurfaceCheckScript,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    $surfaceCheckOutput = @(
        & powershell -NoProfile -ExecutionPolicy Bypass -File $SurfaceCheckScript -RepoRoot $RepoRoot -Json 2>&1
    )
    $surfaceCheckExitCode = $LASTEXITCODE
    $surfaceCheckText = ($surfaceCheckOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($surfaceCheckText)) {
        throw "Google issue #3 recommended validation surface checker produced no JSON output."
    }

    $surfaceCheckText | Set-Content -Path $ArtifactPath -Encoding Ascii

    try {
        $surfaceCheckRecord = $surfaceCheckText | ConvertFrom-Json
    } catch {
        throw ("Google issue #3 recommended validation surface checker returned non-JSON output. Artifact: {0}" -f $ArtifactPath)
    }

    return [pscustomobject]@{
        status = if ($surfaceCheckExitCode -eq 0) { "passed" } else { "failed" }
        exit_code = $surfaceCheckExitCode
        record = $surfaceCheckRecord
    }
}

function Save-RecommendedGuideArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GuideScript,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    $guideOutput = @(
        & powershell -NoProfile -ExecutionPolicy Bypass -File $GuideScript -SummaryPath $SummaryPath -Json 2>&1
    )
    $guideText = ($guideOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($guideText)) {
        throw "Google issue #3 validation summary guide produced no JSON output."
    }

    $guideText | Set-Content -Path $ArtifactPath -Encoding Ascii

    try {
        return ($guideText | ConvertFrom-Json)
    } catch {
        throw ("Google issue #3 validation summary guide returned non-JSON output. Artifact: {0}" -f $ArtifactPath)
    }
}

function Save-PhaseBoundaryArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BoundaryScript,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )

    $boundaryOutput = @(
        & powershell -NoProfile -ExecutionPolicy Bypass -File $BoundaryScript -SummaryPath $SummaryPath -ArtifactPath $ArtifactPath -Json 2>&1
    )
    $boundaryText = ($boundaryOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($boundaryText)) {
        throw "Google issue #3 phase boundary helper produced no JSON output."
    }

    try {
        return ($boundaryText | ConvertFrom-Json)
    } catch {
        throw ("Google issue #3 phase boundary helper returned non-JSON output. Artifact: {0}" -f $ArtifactPath)
    }
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
Write-Host ("Phase artifacts: {0}" -f $phaseArtifactRoot)
Write-Host ("Surface JSON: {0}" -f $surfaceCheckArtifactPath)
Write-Host ("Summary JSON: {0}" -f $SummaryPath)
Write-Host ("Guide JSON: {0}" -f $guideArtifactPath)
Write-Host ("Boundary JSON: {0}" -f $phaseBoundaryArtifactPath)
Write-Host ("Manifest JSON: {0}" -f $manifestArtifactPath)
Write-Host ""
Write-Host "=== google-issue3-recommended-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)

$surfaceCheckStatus = "passed"
$surfaceCheckError = $null
$surfaceCheckRecord = $null
$phaseResults = [System.Collections.Generic.List[object]]::new()
$guideRecord = $null
$guideArtifactError = $null
$boundaryArtifactError = $null
try {
    $surfaceCheckResult = Save-SurfaceCheckArtifact -SurfaceCheckScript $surfaceCheck -RepoRoot $RepoRoot -ArtifactPath $surfaceCheckArtifactPath
    $surfaceCheckStatus = $surfaceCheckResult.status
    $surfaceCheckRecord = $surfaceCheckResult.record
    if ($surfaceCheckStatus -ne "passed") {
        if ($surfaceCheckRecord -and $surfaceCheckRecord.missing_count -ne $null) {
            $surfaceCheckError = ("Missing {0} recommended-validation path(s)." -f $surfaceCheckRecord.missing_count)
        } else {
            $surfaceCheckError = ("Surface checker returned exit code {0}." -f $surfaceCheckResult.exit_code)
        }
    }
} catch {
    $surfaceCheckStatus = "failed"
    $surfaceCheckError = $_.Exception.Message
}
if ($surfaceCheckStatus -ne "passed") {
    Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError
    try {
        $guideRecord = Save-RecommendedGuideArtifact -GuideScript $summaryGuide -SummaryPath $SummaryPath -ArtifactPath $guideArtifactPath
    } catch {
        $guideArtifactError = $_.Exception.Message
    }
    try {
        $null = Save-PhaseBoundaryArtifact -BoundaryScript $phaseBoundaryHelper -SummaryPath $SummaryPath -ArtifactPath $phaseBoundaryArtifactPath
    } catch {
        $boundaryArtifactError = $_.Exception.Message
    }
    Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError
    Write-RecommendedManifestArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError -GuideRecord $guideRecord
    $guideMessage = if ($guideArtifactError) {
        " Guide artifact error: $guideArtifactError"
    } else {
        " Guide JSON: $guideArtifactPath"
    }
    $boundaryMessage = if ($boundaryArtifactError) {
        " Boundary artifact error: $boundaryArtifactError"
    } else {
        " Boundary JSON: $phaseBoundaryArtifactPath"
    }
    throw ("Google issue #3 recommended validation surface check failed: {0}. Surface JSON: {1}. Summary JSON: {2}. Manifest JSON: {3}.{4}{5}" -f $surfaceCheckError, $surfaceCheckArtifactPath, $SummaryPath, $manifestArtifactPath, $guideMessage, $boundaryMessage)
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

Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError
try {
    $guideRecord = Save-RecommendedGuideArtifact -GuideScript $summaryGuide -SummaryPath $SummaryPath -ArtifactPath $guideArtifactPath
} catch {
    $guideArtifactError = $_.Exception.Message
}
try {
    $null = Save-PhaseBoundaryArtifact -BoundaryScript $phaseBoundaryHelper -SummaryPath $SummaryPath -ArtifactPath $phaseBoundaryArtifactPath
} catch {
    $boundaryArtifactError = $_.Exception.Message
}
Write-RecommendedSummaryArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError
Write-RecommendedManifestArtifact -PhaseResults @($phaseResults) -SurfaceCheckStatus $surfaceCheckStatus -SurfaceCheckError $surfaceCheckError -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -SurfaceCheckRecord $surfaceCheckRecord -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError -GuideRecord $guideRecord
Show-RecommendedSummary -PhaseResults @($phaseResults) -SurfaceCheckArtifactPath $surfaceCheckArtifactPath -GuideArtifactPath $guideArtifactPath -BoundaryArtifactPath $phaseBoundaryArtifactPath -ManifestArtifactPath $manifestArtifactPath -GuideArtifactError $guideArtifactError -BoundaryArtifactError $boundaryArtifactError -GuideRecord $guideRecord

$failedPhase = @($phaseResults | Where-Object { $_.status -ne "passed" } | Select-Object -First 1)
if ($failedPhase.Count -gt 0) {
    $guideMessage = if ($guideArtifactError) {
        " Guide artifact error: $guideArtifactError"
    } else {
        " Guide JSON: $guideArtifactPath"
    }
    $boundaryMessage = if ($boundaryArtifactError) {
        " Boundary artifact error: $boundaryArtifactError"
    } else {
        " Boundary JSON: $phaseBoundaryArtifactPath"
    }
    throw ("Google issue #3 recommended validation stopped at phase '{0}': {1}. Surface JSON: {2}. Summary JSON: {3}. Manifest JSON: {4}.{5}{6}" -f $failedPhase[0].name, $failedPhase[0].error, $surfaceCheckArtifactPath, $SummaryPath, $manifestArtifactPath, $guideMessage, $boundaryMessage)
}
if ($guideArtifactError) {
    Write-Warning ("Google issue #3 validation guide artifact could not be generated: {0}" -f $guideArtifactError)
}
if ($boundaryArtifactError) {
    Write-Warning ("Google issue #3 phase boundary artifact could not be generated: {0}" -f $boundaryArtifactError)
}
