[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8178,
    [string]$InputText = "Q"
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

$surfaceCheck = '.\\scripts\\windows\\check_google_home_input_phase_localhost_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_home_input_phase_localhost_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-home-input-phase-localhost-probe.ps1'
$broaderFlow = '.\\scripts\\windows\\show_google_input_validation_flow.ps1'

$wrapperArguments = ""
$directProbeArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $directProbeArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $directProbeArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $wrapperArguments += " -Host $quotedHost"
    $directProbeArguments += " -Host $quotedHost"
}
if ($Port) {
    $wrapperArguments += " -Port $Port"
    $directProbeArguments += " -Port $Port"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}

$flow = [ordered]@{
    issue = "Headed Windows Google home input-phase localhost validation flow"
    focus = "Reduced Google-style localhost focus recovery, typed-text commit, and keypress-before-submit ordering on the real headed surface before the broader issue #3 ladder."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced localhost note, helper, wrapper, or raw probe drifted before you trust this smaller issue #3 gate."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated wrapper first so the reduced localhost input-phase gate stays on one stable command surface."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw localhost input-phase probe only when you need the direct output files from tmp-browser-smoke/google-investigation-next."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
        [ordered]@{
            name = "broader-flow"
            goal = "Return to the broader issue #3 ladder once this smaller gate is green."
            command = "powershell -ExecutionPolicy Bypass -File $broaderFlow"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_input_validation.ps1 -Phase localhost when you want the full reduced localhost stack around this smaller gate.",
        "Use .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home after this gate is green when you want the broader reduced-homepage headed pass.",
        "Use .\\scripts\\windows\\run_google_submit_timing_validation.ps1 when this gate is green but the broader Google-shaped timing slice still needs confirmation."
    )
    notes = @(
        "Start with the surface check when you want guide or helper drift to fail fast before the raw probe output is trusted.",
        "Start with the wrapper unless you already know you need the direct browser, server, and screenshot artifacts from the raw probe.",
        "Keep the same host, port, and input text here when you want this smaller gate aligned with the rest of the issue #3 localhost stack.",
        "Treat this as a narrower checkpoint between the generic localhost probes and the broader reduced-homepage or live Google passes."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google home input-phase localhost validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
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
