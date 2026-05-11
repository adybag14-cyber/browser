[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$InputPhasePort = 8178,
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

$surfaceCheck = '.\\scripts\\windows\\check_google_home_input_phase_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_home_input_phase_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-home-input-phase-localhost-probe.ps1'

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
if ($InputPhasePort) {
    $wrapperArguments += " -InputPhasePort $InputPhasePort"
    $directProbeArguments += " -Port $InputPhasePort"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}

$flow = [ordered]@{
    issue = "Headed Windows Google home input-phase localhost validation flow"
    focus = "Reduced-home localhost keypress-before-submit checkpoint on the real headed surface after the homepage-fixture gate and before the later submit-timing or shared Enter-order ladders."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced-home localhost note, helper, wrapper, or raw probe drifted before you trust this narrower issue #3 checkpoint."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated reduced-home localhost wrapper first so the keypress-before-submit checkpoint stays on the same reusable command surface as the other issue #3 Windows helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw reduced-home localhost probe only when you need to narrow a wrapper failure to the underlying Google-style headed click, type, and Enter-order path."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1 before this wrapper when you want the earlier saved-homepage checkpoint printed first.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 after this wrapper is green when you want the later Google-shaped timing ladder printed before you run it.",
        "Use .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1 when you want the same reduced-home localhost checkpoint kept inside the broader localhost-first issue #3 stack."
    )
    notes = @(
        "Start with the surface check when you want the reduced-home localhost checkpoint to fail fast on missing guide, helper, wrapper, or raw-probe drift before the broader issue #3 ladder.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/google-investigation-next.",
        "Keep the same host, port, and input text here when you want the reduced-home localhost checkpoint aligned with the broader issue #3 flow.",
        "Treat this as the smaller bridge between the homepage-fixture checkpoint and the later submit-timing or shared Enter-order ladders."
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
