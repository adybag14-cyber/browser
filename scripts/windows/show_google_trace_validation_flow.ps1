[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "lightpanda",
    [int]$WindowReadyAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
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

$reducedTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-enter-trace-probe.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$liveTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-input-probe.ps1'

$reducedTraceArguments = ""
$wrapperArguments = ""
$liveTraceArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $reducedTraceArguments += " -RepoRoot $quotedRepoRoot"
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $liveTraceArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $reducedTraceArguments += " -BrowserExe $quotedBrowserExe"
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $liveTraceArguments += " -BrowserExe $quotedBrowserExe"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $reducedTraceArguments += " -InputText $quotedInputText"
    $wrapperArguments += " -TraceInputText $quotedInputText"
    $liveTraceArguments += " -InputText $quotedInputText"
}
if ($WindowReadyAttempts) {
    $reducedTraceArguments += " -WindowReadyAttempts $WindowReadyAttempts"
    $wrapperArguments += " -TraceWindowReadyAttempts $WindowReadyAttempts"
    $liveTraceArguments += " -WindowReadyAttempts $WindowReadyAttempts"
}
if ($PollMilliseconds) {
    $reducedTraceArguments += " -PollMilliseconds $PollMilliseconds"
    $wrapperArguments += " -TracePollMilliseconds $PollMilliseconds"
    $liveTraceArguments += " -PollMilliseconds $PollMilliseconds"
}
if ($LeaveOpen) {
    $reducedTraceArguments += " -LeaveOpen"
    $wrapperArguments += " -LeaveOpen"
    $liveTraceArguments += " -LeaveOpen"
}

$flow = [ordered]@{
    issue = "Headed Windows Google live trace validation flow"
    focus = "Read-first handoff from the bounded localhost, reduced homepage, submit-timing, and shared Enter-order gates into the reduced-home trace capture and the real Google homepage trace path."
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "reduced-trace"
            goal = "Run the reduced-home trace probe first when you want the real headed surface plus the Google-specific runtime logs without jumping straight to live Google."
            command = "powershell -ExecutionPolicy Bypass -File $reducedTraceProbe$reducedTraceArguments"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the live Google trace path through the shared issue #3 runner so the real-homepage capture stays on the same reusable command surface as the bounded phases."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner -Phase trace$wrapperArguments"
        }
        [ordered]@{
            name = "direct-live-probe"
            goal = "Run the raw live Google trace probe only when you need to narrow a wrapper failure to the underlying headed input and logging path."
            command = "powershell -ExecutionPolicy Bypass -File $liveTraceProbe$liveTraceArguments"
        }
    )
    next_steps = @(
        "Compare the reduced-trace and live trace logs with the closest bounded localhost, reduced homepage, submit-timing, and shared Enter-order phases before changing the headed input path.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 when you need to re-walk the bounded Google-shaped keydown, keypress, and submit ordering before another live capture.",
        "Use .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1 when the next question is whether the current attached or saved Google-like HTML pages diverge before the live Google homepage does."
    )
    notes = @(
        "Treat this helper as a later-stage investigation handoff, not the first gate. Start with the reduced localhost probes and shared input stacks first.",
        "Use the wrapper unless you already know you need the raw direct probe outputs from tmp-browser-smoke/google-investigation-next.",
        "When LeaveOpen is set, the reduced and live trace commands keep the headed window open after capture so the real surface can be inspected before teardown."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google live trace validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Leave open after trace capture: {0}" -f ([bool]$LeaveOpen))
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
