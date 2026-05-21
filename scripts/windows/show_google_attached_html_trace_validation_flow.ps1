[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
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

$attachedHtmlFlow = '.\\scripts\\windows\\show_attached_html_validation_flow.ps1'
$googleAttachedHtmlFlow = '.\\scripts\\windows\\show_google_attached_html_validation_flow.ps1'
$issue3Runner = '.\\scripts\\windows\\run_google_issue3_recommended_validation.ps1'
$traceFlow = '.\\scripts\\windows\\show_google_trace_validation_flow.ps1'
$traceArtifacts = '.\\scripts\\windows\\show_google_trace_artifact_guide.ps1'
$topLevelQuickstart = '.\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1'

$attachedHtmlArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $attachedHtmlArgs -Name Port -Value $Port
$attachedHtmlArgs.Add('-GoogleStyle')
if ($LeaveOpen) {
    $attachedHtmlArgs.Add('-LeaveOpen')
}

$issue3RunnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $issue3RunnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $issue3RunnerArgs -Name Host -Value $Host
$issue3RunnerArgs.Add('-ManualGoogleStyle')
if ($LeaveOpen) {
    $issue3RunnerArgs.Add('-LeaveOpen')
}

$traceFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $traceFlowArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $traceFlowArgs -Name WindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $traceFlowArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $traceFlowArgs.Add('-LeaveOpen')
}

$artifactArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $artifactArgs -Name RepoRoot -Value $RepoRoot

$flow = [ordered]@{
    issue = "Headed Windows attached HTML trace bridge"
    focus = "Bridge the saved Google-style attached pages back into the existing issue #3 live-trace lane once the localhost-first page checks have narrowed the problem far enough."
    host = $Host
    port = $Port
    input_text = $InputText
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "attached-html-router"
            goal = "Start from the saved-page router so the Google-shaped attached pages stay on the localhost-first validation path before any live trace jump."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $attachedHtmlFlow, $(if ($attachedHtmlArgs.Count -gt 0) { " " + ($attachedHtmlArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "google-attached-flow"
            goal = "Print the narrower Google-style attached-page helper stack when the saved Safety Centre page is the closest repro surface."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $googleAttachedHtmlFlow)
        }
        [ordered]@{
            name = "issue3-runner"
            goal = "Run the shared issue #3 Windows validation ladder in manual Google-style mode before switching to live trace capture."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $issue3Runner, $(if ($issue3RunnerArgs.Count -gt 0) { " " + ($issue3RunnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "live-trace-flow"
            goal = "Hand off into the live Google trace flow with the same browser path, host, input text, and LeaveOpen mode."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $traceFlow, $(if ($traceFlowArgs.Count -gt 0) { " " + ($traceFlowArgs -join " ") } else { "" }))
        }
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} after any live or reduced-home trace capture to print the current trace files, tails, and nearest follow-up helpers on one repeatable surface." -f $traceArtifacts, $(if ($artifactArgs.Count -gt 0) { " " + ($artifactArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0} when you need the compact top-level attached-page quickstart before replaying the saved Google-style fixtures again." -f $topLevelQuickstart)
    )
    notes = @(
        "Use this helper only after the attached-page route has already shown that the saved Google-style pages are the nearest useful repro surface.",
        "The bridge keeps localhost-first validation ahead of live Google capture, which makes later trace artifacts easier to interpret.",
        "LeaveOpen is forwarded to the runner and live-trace flow so the headed browser can stay visible during manual inspection."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows attached HTML trace bridge"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Port: {0}" -f $flow.port)
Write-Host ("Input text: {0}" -f $flow.input_text)
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
