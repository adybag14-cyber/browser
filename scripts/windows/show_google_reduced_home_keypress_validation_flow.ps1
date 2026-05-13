[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [int]$ReducedHomeKeypressPort = 8167,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
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

$surfaceCheck = '.\\scripts\\windows\\check_google_reduced_home_keypress_validation_surface.ps1'
$runner = '.\\scripts\\windows\\run_google_reduced_home_keypress_validation.ps1'
$rawProbe = '.\\tmp-browser-smoke\\google-home\\chrome-google-home-keypress-submit-probe.ps1'
$submitPathFlow = '.\\scripts\\windows\\show_google_submit_path_validation_flow.ps1'
$submitPathTraceGuide = '.\\scripts\\windows\\show_google_submit_path_trace_guide.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $runnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $runnerArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$rawProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $rawProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $rawProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $rawProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $rawProbeArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $rawProbeArgs -Name Port -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $rawProbeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $rawProbeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows Google reduced-home keypress validation flow"
    focus = "Print the smallest later-stage issue #3 command surface for proving the reduced Google-style homepage still records keydown before submit on the real headed Win32 path."
    shared_input_text = $SharedInputText
    reduced_home_keypress_port = $ReducedHomeKeypressPort
    host = $Host
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Run the dedicated fail-fast checker first so missing notes, helper scripts, or the raw reduced-home probe are caught before this smaller issue #3 gate starts."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $surfaceCheck, $(if ($surfaceCheckArgs.Count -gt 0) { " " + ($surfaceCheckArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "recommended"
            goal = "Run the dedicated wrapper so the reduced-home keypress checkpoint stays on one stable command surface before the broader submit-path ladder is reopened."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $runner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "raw-probe"
            goal = "Run the underlying reduced-home keypress probe directly when you need the exact headed localhost script without the wrapper layer."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $rawProbe, $(if ($rawProbeArgs.Count -gt 0) { " " + ($rawProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "broader-submit-path"
            goal = "Escalate to the wider later-stage submit-path ladder only after the reduced-home keypress checkpoint is green or when you need the saved homepage fixture, reduced Enter-trace, submit-timing, and shared Enter-order slices printed together again."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $submitPathFlow)
        }
    )
    notes = @(
        "Run the dedicated surface check before the wrapper when you want note, helper, or raw-probe drift to fail fast.",
        "Keep SharedInputText aligned with the broader issue #3 shared probes so the reduced-home keypress gate reports the same expected query string.",
        "Port 8167 is shared on purpose with the reduced-home keypress proof already used by the broader shared Enter-order ladder, so one override keeps the smaller gate and the wider stack in sync.",
        "Use the raw probe command only when you need the direct script surface; otherwise prefer the dedicated wrapper so the issue #3 notes keep pointing at one stable command.",
        "Use the later submit-path trace guide only after this reduced-home keypress gate is green but the broader later-stage wrappers still disagree."
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_reduced_home_keypress_validation.ps1 when you want to execute the smaller real-surface gate directly after the surface check passes.",
        "Use .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1 when this reduced-home keypress gate is green and you want the broader later-stage ladder printed again.",
        "Use .\\scripts\\windows\\show_google_submit_path_trace_guide.ps1 when the later-stage wrappers still disagree and you want the quickest explanation of which bounded checkpoint to reopen next.",
        "Move on to attached HTML or live Google replay only after this reduced-home keypress gate and the broader later-stage submit-path ladder stay green together."
    )
    trace_guide_command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $submitPathTraceGuide)
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google reduced-home keypress validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Reduced-home keypress port: {0}" -f $flow.reduced_home_keypress_port)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
Write-Host ""
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ("- Trace guide: {0}" -f $flow.trace_guide_command)
