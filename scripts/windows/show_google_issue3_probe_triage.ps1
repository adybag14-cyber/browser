[CmdletBinding()]
param(
    [string]$SummaryPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }
        $cursor = $parent
    }
}

function Resolve-ArtifactCandidatePath {
    param(
        [string]$ConfiguredPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactRoot,
        [Parameter(Mandatory = $true)]
        [string]$FallbackName
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return $ConfiguredPath
    }

    return Join-Path $ArtifactRoot $FallbackName
}

function Read-ArtifactJson {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$phaseBoundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$titleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
$submitGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$formGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$submitRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$sharedEnterRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$summary = $null
$artifactRoot = Split-Path -Parent $SummaryPath
if ($summaryExists) {
    $summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
        $artifactRoot = $summary.artifact_root
    }
}

$refreshArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
} else {
    Join-Path $artifactRoot 'google-issue3-validation-handoff-chain-refresh.json'
}
$handoffArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
} else {
    Join-Path $artifactRoot 'google-issue3-validation-handoff.json'
}
$manifestArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
} else {
    Join-Path $artifactRoot 'google-issue3-recommended-validation-manifest.json'
}
$bundleArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
} else {
    Join-Path $artifactRoot 'google-issue3-validation-artifact-bundle.json'
}
$boundaryArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.boundary_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
} else {
    Join-Path $artifactRoot 'google-issue3-phase-boundary.json'
}
$guideArtifactPath = if ($summaryExists) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.guide_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
} else {
    Join-Path $artifactRoot 'google-issue3-recommended-validation-guide.json'
}

$summaryRecordsRefreshArtifactPath = [bool]($summaryExists -and -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_path))
$summaryRecordsHandoffArtifactPath = [bool]($summaryExists -and -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_path))
$refreshArtifactExists = Test-Path -LiteralPath $refreshArtifactPath -PathType Leaf
$handoffArtifactExists = Test-Path -LiteralPath $handoffArtifactPath -PathType Leaf
$manifestArtifactExists = Test-Path -LiteralPath $manifestArtifactPath -PathType Leaf
$bundleArtifactExists = Test-Path -LiteralPath $bundleArtifactPath -PathType Leaf
$boundaryArtifactExists = Test-Path -LiteralPath $boundaryArtifactPath -PathType Leaf
$guideArtifactExists = Test-Path -LiteralPath $guideArtifactPath -PathType Leaf
$refreshRecord = Read-ArtifactJson $refreshArtifactPath
$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshArtifactExists) {
    'present-unreadable'
} else {
    'missing'
}
$bundleRecord = Read-ArtifactJson $bundleArtifactPath
$artifactBundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($bundleArtifactExists) {
    'present-unreadable'
} else {
    'missing'
}
$handoffRecord = Read-ArtifactJson $handoffArtifactPath
$handoffReady = [bool]($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))

$triageOrder = @()
$quickDiagnosis = @()
$nextStep = $recommendedRunnerCommand
$reason = 'No saved issue #3 recommended-validation summary exists yet, so the bounded runner should create the first summary and helper artifacts.'

if (-not $summaryExists) {
    $triageOrder = @(
        '1. Run the recommended issue #3 validation runner to create the first summary and helper artifacts.',
        '2. Reopen this triage helper after the run so it can point at the current refresh, handoff, manifest, bundle, and boundary files.',
        '3. Only widen to attached HTML or live Google replay after the bounded runner leaves a usable failing checkpoint.'
    )
    $quickDiagnosis = @(
        'Without a saved summary, the recommended runner is still the source of truth for the first failing phase.',
        'Once the summary exists, prefer the handoff helper when the refresh and bundle state are healthy, and fall back to refresh repair when they are not.'
    )
} else {
    if ($artifactBundleStatus -ne 'complete') {
        $nextStep = $refreshStatusCommand
        $reason = "The saved artifact bundle reports '$artifactBundleStatus', so start with refresh status and repair the helper chain before trusting the narrower handoff or manifest guidance."
    } elseif ($refreshStatus -ne 'refreshed') {
        $nextStep = $refreshStatusCommand
        $reason = "The saved refresh artifact reports '$refreshStatus', so start there before trusting the narrower handoff guidance."
    } elseif (-not $refreshArtifactExists) {
        $nextStep = $refreshStatusCommand
        $reason = 'The saved summary exists, but the refresh artifact is missing, so the next replay should start by checking refresh status and then regenerating the helper chain if needed.'
    } elseif (-not $summaryRecordsRefreshArtifactPath) {
        $nextStep = $refreshStatusCommand
        $reason = 'The saved summary exists and the refresh artifact exists, but the summary does not record that pointer yet, so start with refresh status to keep the helper chain aligned.'
    } elseif (-not $handoffArtifactExists) {
        $nextStep = $refreshStatusCommand
        $reason = 'The saved summary exists, but the handoff artifact is missing, so refresh status should repair the helper chain before narrower replay.'
    } elseif (-not $summaryRecordsHandoffArtifactPath) {
        $nextStep = $refreshStatusCommand
        $reason = 'The saved summary exists and the handoff artifact exists, but the summary does not record that pointer yet, so refresh status should keep the helper chain aligned before narrower replay.'
    } elseif ($handoffReady) {
        $nextStep = $handoffGuideCommand
        $reason = 'The saved summary, refresh artifact, bundle audit, and handoff artifact are already coherent, so start with the handoff helper and follow its next_artifact_to_open guidance.'
    } else {
        $nextStep = $refreshStatusCommand
        $reason = 'The saved handoff artifact exists but does not yet point at a reusable next artifact, so start with refresh status and then repair the helper chain if needed.'
    }

    $triageOrder = @(
        '1. Start with the handoff helper when the saved refresh and artifact-bundle state are healthy; otherwise start with refresh status for the current summary.',
        '2. If refresh status or the artifact-bundle helper says the chain is stale or incomplete, run the refresh-chain helper before trusting the saved handoff, manifest, guide, or boundary outputs.',
        '3. Once the helper chain is coherent, open the handoff helper and follow its next_artifact_to_open guidance.',
        '4. Use the manifest helper when you want the richest artifact index for the current replay, and use the boundary helper when you need the exact last-pass / first-fail split.',
        '5. Stay on the title, reduced-home submit, or shared Enter-order slices until those bounded checkpoints agree before widening back out.'
    )
    $quickDiagnosis = @(
        ('Saved summary first_failed_phase: {0}' -f $(if ($summary.first_failed_phase) { $summary.first_failed_phase } else { 'none recorded' })),
        ('Saved summary surface_check_status: {0}' -f $(if ($summary.surface_check_status) { $summary.surface_check_status } else { 'unknown' })),
        ('Artifact bundle status: {0}' -f $artifactBundleStatus),
        ('Refresh status: {0}' -f $refreshStatus),
        ('Handoff ready: {0}' -f $handoffReady),
        ('Summary records refresh pointer: {0}' -f $summaryRecordsRefreshArtifactPath),
        ('Summary records handoff pointer: {0}' -f $summaryRecordsHandoffArtifactPath),
        ('Refresh artifact exists: {0}' -f $refreshArtifactExists),
        ('Handoff artifact exists: {0}' -f $handoffArtifactExists),
        ('Manifest artifact exists: {0}' -f $manifestArtifactExists),
        ('Bundle artifact exists: {0}' -f $bundleArtifactExists),
        ('Boundary artifact exists: {0}' -f $boundaryArtifactExists),
        ('Guide artifact exists: {0}' -f $guideArtifactExists)
    )
}

$guide = [ordered]@{
    issue = 'Google issue #3 probe triage'
    purpose = 'Use the current recommended-validation summary to surface the exact refresh, handoff, manifest, bundle, guide, and boundary artifact paths, and prefer the saved handoff helper once the helper chain is coherent.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_exists = [bool]$summaryExists
    summary_generated_at_utc = if ($summaryExists) { $summary.generated_at_utc } else { $null }
    summary_completed = if ($summaryExists) { [bool]$summary.completed } else { $false }
    first_failed_phase = if ($summaryExists) { $summary.first_failed_phase } else { $null }
    surface_check_status = if ($summaryExists) { $summary.surface_check_status } else { $null }
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
    handoff_guide_command = $handoffGuideCommand
    manifest_guide_command = $manifestGuideCommand
    summary_guide_command = $summaryGuideCommand
    artifact_bundle_command = $artifactBundleCommand
    phase_boundary_command = $phaseBoundaryCommand
    title_trace_guide_command = $titleGuideCommand
    submit_path_trace_guide_command = $submitGuideCommand
    form_controls_trace_guide_command = $formGuideCommand
    recommended_runner_command = $recommendedRunnerCommand
    submit_path_runner_command = $submitRunnerCommand
    shared_enter_runner_command = $sharedEnterRunnerCommand
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    refresh_artifact_path = $refreshArtifactPath
    refresh_artifact_exists = [bool]$refreshArtifactExists
    refresh_status = $refreshStatus
    handoff_artifact_path = $handoffArtifactPath
    handoff_artifact_exists = [bool]$handoffArtifactExists
    handoff_ready = [bool]$handoffReady
    manifest_artifact_path = $manifestArtifactPath
    manifest_artifact_exists = [bool]$manifestArtifactExists
    artifact_bundle_path = $bundleArtifactPath
    artifact_bundle_exists = [bool]$bundleArtifactExists
    artifact_bundle_status = $artifactBundleStatus
    boundary_artifact_path = $boundaryArtifactPath
    boundary_artifact_exists = [bool]$boundaryArtifactExists
    guide_artifact_path = $guideArtifactPath
    guide_artifact_exists = [bool]$guideArtifactExists
    triage_order = @($triageOrder)
    quick_diagnosis = @($quickDiagnosis)
    next_step = $nextStep
    reason = $reason
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 probe triage'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Summary:  {0}" -f $guide.summary_path)
Write-Host ("Exists:   {0}" -f $guide.summary_exists)
if ($guide.summary_generated_at_utc) {
    Write-Host ("Generated: {0}" -f $guide.summary_generated_at_utc)
}
if ($summaryExists) {
    Write-Host ("Completed: {0}" -f $guide.summary_completed)
    Write-Host ("Surface:   {0}" -f $guide.surface_check_status)
    Write-Host ("Bundle:    {0}" -f $guide.artifact_bundle_status)
    Write-Host ("Refresh:   {0}" -f $guide.refresh_status)
    Write-Host ("Handoff ready: {0}" -f $guide.handoff_ready)
    Write-Host ("First fail:{0}" -f $(if ($guide.first_failed_phase) { ' ' + $guide.first_failed_phase } else { ' none' }))
}
Write-Host ''
Write-Host ("Refresh status: {0}" -f $guide.refresh_status_command)
Write-Host ("Refresh chain:  {0}" -f $guide.refresh_chain_command)
Write-Host ("Handoff:        {0}" -f $guide.handoff_guide_command)
Write-Host ("Manifest:       {0}" -f $guide.manifest_guide_command)
Write-Host ("Summary guide:  {0}" -f $guide.summary_guide_command)
Write-Host ("Bundle:         {0}" -f $guide.artifact_bundle_command)
Write-Host ("Boundary:       {0}" -f $guide.phase_boundary_command)
Write-Host ("Title:          {0}" -f $guide.title_trace_guide_command)
Write-Host ("Submit:         {0}" -f $guide.submit_path_trace_guide_command)
Write-Host ("Shared:         {0}" -f $guide.form_controls_trace_guide_command)
Write-Host ''
Write-Host ("Refresh artifact: {0}" -f $guide.refresh_artifact_path)
Write-Host ("Refresh exists:   {0}" -f $guide.refresh_artifact_exists)
Write-Host ("Handoff artifact: {0}" -f $guide.handoff_artifact_path)
Write-Host ("Handoff exists:   {0}" -f $guide.handoff_artifact_exists)
Write-Host ("Manifest artifact: {0}" -f $guide.manifest_artifact_path)
Write-Host ("Manifest exists:   {0}" -f $guide.manifest_artifact_exists)
Write-Host ("Bundle artifact:   {0}" -f $guide.artifact_bundle_path)
Write-Host ("Bundle exists:     {0}" -f $guide.artifact_bundle_exists)
Write-Host ("Boundary artifact: {0}" -f $guide.boundary_artifact_path)
Write-Host ("Boundary exists:   {0}" -f $guide.boundary_artifact_exists)
Write-Host ("Guide artifact:    {0}" -f $guide.guide_artifact_path)
Write-Host ("Guide exists:      {0}" -f $guide.guide_artifact_exists)
Write-Host ''
Write-Host 'Triage order:'
foreach ($step in $guide.triage_order) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Reason:    {0}" -f $guide.reason)
Write-Host ("Next step: {0}" -f $guide.next_step)
