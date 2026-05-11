[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [switch]$SkipBaseline,
    [switch]$KeepGoing
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

$recommendedRunner = '.\\scripts\\windows\\run_form_controls_validation_recommended.ps1'
$probeRunner = '.\\scripts\\windows\\run_form_controls_validation.ps1'

$recommendedCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner"
if ($RepoRoot) {
    $recommendedCommand += " -RepoRoot " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot)
}
if ($BrowserExe) {
    $recommendedCommand += " -BrowserExe " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe)
}
if ($Host) {
    $recommendedCommand += " -Host " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $Host)
}
if ($SkipBaseline) {
    $recommendedCommand += " -SkipBaseline"
}
if ($KeepGoing) {
    $recommendedCommand += " -KeepGoing"
}

$commonProbeArguments = ""
if ($RepoRoot) {
    $commonProbeArguments += " -RepoRoot " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot)
}
if ($BrowserExe) {
    $commonProbeArguments += " -BrowserExe " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe)
}
if ($Host) {
    $commonProbeArguments += " -Host " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $Host)
}

$flow = [ordered]@{
    issue = "Headed Windows form-controls validation flow"
    focus = "Shared label-click, immediate Enter-submit, deferred Enter-submit, bounded reduced Google title, reduced Google-home submit, and stricter keypress-before-submit gates for the headed input baseline."
    skip_baseline = [bool]$SkipBaseline
    keep_going = [bool]$KeepGoing
    steps = @(
        [ordered]@{
            name = "recommended"
            goal = "Run the one-command shared baseline, reduced Google title, reduced Google-home submit, and Enter-order stack before moving into inline-flow, Google shared Enter-order, or attached HTML follow-up."
            command = $recommendedCommand
        }
        [ordered]@{
            name = "label"
            goal = "Narrow failures to label activation only when the full recommended runner reports a baseline problem."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe label$commonProbeArguments"
        }
        [ordered]@{
            name = "default-enter"
            goal = "Check the immediate Enter-submit path in isolation after label activation is green."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe default-enter$commonProbeArguments"
        }
        [ordered]@{
            name = "deferred-enter"
            goal = "Check the deferred pending-submit path after the immediate Enter gate is green."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe deferred-enter$commonProbeArguments"
        }
        [ordered]@{
            name = "google-title"
            goal = "Run the bounded reduced Google title gate before the fuller reduced-home submit pass or the stricter shared Enter-order gate."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe google-title$commonProbeArguments"
        }
        [ordered]@{
            name = "reduced-google-home"
            goal = "Run the reduced Google-home submit gate after the smaller title pass is stable."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe reduced-google-home$commonProbeArguments"
        }
        [ordered]@{
            name = "google-enter-order"
            goal = "Run the stricter localhost keypress-before-submit gate before the broader Google shared runner or live manual follow-up."
            command = "powershell -ExecutionPolicy Bypass -File $probeRunner -Probe google-enter-order$commonProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 when the recommended runner is green and you want the stricter shared Enter-order stack printed in the intended order before you execute it with .\\scripts\\windows\\run_google_shared_enter_order_validation.ps1.",
        "Use .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1 when you want the localhost-first issue #3 order that folds these shared gates into the broader Google-specific flow.",
        "Use .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait only after the closest bounded form-controls or Google flow is already green."
    )
    notes = @(
        "Start with the recommended runner unless you are already narrowing an existing regression.",
        "Use SkipBaseline only when the label-click plus immediate Enter gate already passed elsewhere and you need a faster deferred or Google-shaped rerun.",
        "Use KeepGoing when you want one failing summary that still attempts later steps for comparison instead of stopping at the first broken gate.",
        "Treat the reduced Google title step as the smaller gateway into the reduced-home submit and shared Enter-order checks, not as a separate side path."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows form-controls validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Skip baseline in recommended runner: {0}" -f $flow.skip_baseline)
Write-Host ("Keep going after failures: {0}" -f $flow.keep_going)
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
