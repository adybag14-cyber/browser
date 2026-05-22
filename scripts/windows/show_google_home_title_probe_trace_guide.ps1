[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [int]$Port = 9582,
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

$guidePath = "docs/GOOGLE_HOME_TITLE_PROBE_VALIDATION.md"
$surfaceCheckScript = ".\scripts\windows\check_google_home_title_probe_validation_surface.ps1"
$sharedFlowScript = ".\scripts\windows\show_google_shared_enter_order_validation_flow.ps1"
$runtimeNotePath = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
$rawProbeScript = ".\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$sharedGuideArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedGuideArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedGuideArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedGuideArgs -Name SharedInputText -Value $InputText
Add-SharedArgument -Arguments $sharedGuideArgs -Name TitleProbePort -Value $Port
Add-SharedArgument -Arguments $sharedGuideArgs -Name HomePollMilliseconds -Value $PollMilliseconds

$rawProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $rawProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $rawProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $rawProbeArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $rawProbeArgs -Name Port -Value $Port
Add-SharedArgument -Arguments $rawProbeArgs -Name TimeoutSeconds -Value $TimeoutSeconds
Add-SharedArgument -Arguments $rawProbeArgs -Name PollMilliseconds -Value $PollMilliseconds

$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File $surfaceCheckScript$(if ($surfaceCheckArgs.Count -gt 0) { ' ' + ($surfaceCheckArgs -join ' ') } else { '' })"
$sharedFlowCommand = "powershell -ExecutionPolicy Bypass -File $sharedFlowScript$(if ($sharedGuideArgs.Count -gt 0) { ' ' + ($sharedGuideArgs -join ' ') } else { '' })"
$rawProbeCommand = "powershell -ExecutionPolicy Bypass -File $rawProbeScript$(if ($rawProbeArgs.Count -gt 0) { ' ' + ($rawProbeArgs -join ' ') } else { '' })"

$guide = [ordered]@{
    issue = "Google home title-probe trace guide"
    purpose = "Translate the reduced Google homepage title-probe markers and JSON fields into query-binding, click-focus, typed-text, Enter-submit, and runtime-handoff stages before widening issue #3 validation again."
    guide_path = $guidePath
    runtime_note_path = $runtimeNotePath
    input_text = $InputText
    port = $Port
    surface_check_command = $surfaceCheckCommand
    shared_flow_command = $sharedFlowCommand
    raw_probe_command = $rawProbeCommand
    quick_diagnosis = @(
        "No helper_ready_marker or a helper_ready_marker of NOQ means the reduced homepage fixture never exposed the query input.",
        "A helper_ready_marker of BOUND without FOCUSIN or FOCUSED means the probe found the query input but click focus did not settle.",
        "A helper_typed_marker that never reaches TYPED:<text> means the click-first path still is not committing visible text to the query field.",
        "A helper_enter_marker that never reaches SUBMIT:<text> means Enter ordering or submit delivery still failed after visible text was present.",
        "A helper_failure_stage of typed_title or enter_title means the reduced homepage stayed on the right surface long enough to narrow the failure to post-focus typing or post-typing submit.",
        "helper_trace_tail_markers should show the typed marker before the submit marker; if submit appears first, reopen the Enter-order runtime note immediately.",
        "backend_trace_tails and wndproc_trace_tails are the next evidence to read when the title markers stop changing even though the window stayed open."
    )
    next_step = "Run the dedicated surface checker first, rerun the reduced homepage title probe, then widen into the shared Enter-order flow or the runtime revalidation note depending on whether the reduced homepage gate fails before submit or only at Enter ordering."
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Google home title-probe trace guide"
Write-Host ""
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Guide:   {0}" -f $guide.guide_path)
Write-Host ("Runtime: {0}" -f $guide.runtime_note_path)
Write-Host ("Input:   {0}" -f $guide.input_text)
Write-Host ("Port:    {0}" -f $guide.port)
Write-Host ("Check:   {0}" -f $guide.surface_check_command)
Write-Host ("Flow:    {0}" -f $guide.shared_flow_command)
Write-Host ("Run:     {0}" -f $guide.raw_probe_command)
Write-Host ""
Write-Host "Quick diagnosis:"
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ""
Write-Host ("Next step: {0}" -f $guide.next_step)
