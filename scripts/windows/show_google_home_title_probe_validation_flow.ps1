[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [int]$Port = 9582,
    [int]$TimeoutSeconds = 90,
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

$reducedProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1'
$sharedFormControls = '.\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1'
$sharedEnterOrder = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$traceGuide = '.\\scripts\\windows\\show_google_home_title_probe_trace_guide.ps1'
$runtimeNote = 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md'
$windowsRunbook = 'docs/WINDOWS_FULL_USE.md'

$reducedProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reducedProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reducedProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $reducedProbeArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $reducedProbeArgs -Name Port -Value $Port
Add-SharedArgument -Arguments $reducedProbeArgs -Name TimeoutSeconds -Value $TimeoutSeconds
Add-SharedArgument -Arguments $reducedProbeArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $reducedProbeArgs.Add('-LeaveOpen')
}

$titleTraceGuideArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name Port -Value $Port
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name TimeoutSeconds -Value $TimeoutSeconds
Add-SharedArgument -Arguments $titleTraceGuideArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $titleTraceGuideArgs.Add('-LeaveOpen')
}

$sharedArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedArgs -Name SharedInputText -Value $InputText

function Join-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prefix,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments
    )

    if ($Arguments.Count -eq 0) {
        return $Prefix
    }

    return $Prefix + ' ' + ($Arguments -join ' ')
}

$reducedProbeCommand = Join-Command -Prefix ("powershell -ExecutionPolicy Bypass -File {0}" -f $reducedProbe) -Arguments $reducedProbeArgs
$sharedFormControlsCommand = Join-Command -Prefix ("powershell -ExecutionPolicy Bypass -File {0}" -f $sharedFormControls) -Arguments $sharedArgs
$sharedEnterOrderCommand = Join-Command -Prefix ("powershell -ExecutionPolicy Bypass -File {0}" -f $sharedEnterOrder) -Arguments $sharedArgs
$traceGuideCommand = Join-Command -Prefix ("powershell -ExecutionPolicy Bypass -File {0}" -f $traceGuide) -Arguments $titleTraceGuideArgs
$manualGoogleCommand = if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
    '& ".\\zig-out\\bin\\lightpanda.exe" browse --headed "https://www.google.com/"'
} else {
    "& {0} browse --headed \"https://www.google.com/\"" -f (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe)
}

$flow = [ordered]@{
    issue = 'Headed Windows Google home title-probe validation flow'
    focus = 'Keep the reduced Google homepage title probe, the shared Enter-order ladder, and the runtime revalidation note on one smaller Windows command surface before the full live Google pass widens again.'
    reduced_probe = $reducedProbe
    runtime_note = $runtimeNote
    windows_runbook = $windowsRunbook
    input_text = $InputText
    port = $Port
    timeout_seconds = $TimeoutSeconds
    poll_milliseconds = $PollMilliseconds
    steps = @(
        [ordered]@{
            name = 'reduced-home-probe'
            goal = 'Run the reduced Google homepage probe first so focus, typed text, and Enter-submit ordering stay on the smallest headed runtime surface.'
            command = $reducedProbeCommand
        }
        [ordered]@{
            name = 'trace-guide'
            goal = 'Keep the dedicated reduced-home trace guide nearby when the reduced probe shows that focus, typing, or submit still diverges before the full live Google pass.'
            command = $traceGuideCommand
        }
        [ordered]@{
            name = 'shared-form-controls-gate'
            goal = 'Reopen the dedicated shared form-controls Enter-order gate when the reduced homepage probe needs comparison against the reusable localhost ladder.'
            command = $sharedFormControlsCommand
        }
        [ordered]@{
            name = 'shared-enter-order-flow'
            goal = 'Print the broader shared Enter-order ladder when the next rerun should keep the reduced homepage probe, shared gate, and wider localhost flow visible together.'
            command = $sharedEnterOrderCommand
        }
        [ordered]@{
            name = 'manual-google-follow-up'
            goal = 'Only widen back to the live homepage after the reduced probe and the shared gate agree on the same Enter-submit ordering.'
            command = $manualGoogleCommand
        }
    )
    notes = @(
        'Use the reduced homepage probe before live Google when the remaining bug is still about focus, typed text, or Enter-submit ordering on the headed Win32 surface.',
        'Keep docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md nearby because it names the exact Page.zig and win32_backend.zig slice that still explains the reduced probe outcome.',
        'Use docs/WINDOWS_FULL_USE.md when the replay needs to widen back into the broader Windows-first validation router or attached-page ladders.',
        'Keep the same InputText across the reduced probe, the reduced-home trace guide, and the shared Enter-order helpers so query-value comparisons stay easy to read in logs and issue notes.',
        'Port 9582 stays local to the reduced homepage probe so it does not disturb the shared form-controls port while you compare the two ladders side by side.',
        'Use -LeaveOpen only when you need the reduced homepage window to remain available for a manual follow-up after the scripted title probe finishes.'
    )
    next_steps = @(
        'If the reduced probe never reaches typed text, stay on the focus and text-delivery side of issue #3 before blaming Enter-submit timing.',
        'If the reduced probe shows typed text but no submit transition, compare it immediately with the dedicated shared form-controls gate.',
        'If both reduced and shared gates agree, move on to the manual live Google pass or the broader Windows validation router without reopening the older large-file runtime patch blindly.'
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Headed Windows Google home title-probe validation flow'
Write-Host ''
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Runtime note: {0}" -f $flow.runtime_note)
Write-Host ("Windows runbook: {0}" -f $flow.windows_runbook)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ("Port: {0}" -f $flow.port)
Write-Host ''
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ''
}
Write-Host 'Notes:'
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
Write-Host ''
Write-Host 'Next steps:'
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}