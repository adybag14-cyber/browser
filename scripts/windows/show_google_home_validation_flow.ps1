[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "QZ",
    [int]$Port = 8168,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
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

$surfaceCheck = '.\\scripts\\windows\\check_google_home_validation_surface.ps1'
$quickFlowRunner = '.\\scripts\\windows\\show_google_quick_validation_flow.ps1'
$quickRunner = '.\\scripts\\windows\\run_google_quick_validation.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_home_validation.ps1'
$rawProbe = '.\\tmp-browser-smoke\\google-home\\chrome-google-home-enter-probe.ps1'

$quickFlowArguments = ""
$quickArguments = ""
$wrapperArguments = ""
$rawProbeArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $quickFlowArguments += " -RepoRoot $quotedRepoRoot"
    $quickArguments += " -RepoRoot $quotedRepoRoot"
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $rawProbeArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $quickFlowArguments += " -BrowserExe $quotedBrowserExe"
    $quickArguments += " -BrowserExe $quotedBrowserExe"
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $rawProbeArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $quickFlowArguments += " -Host $quotedHost"
    $quickArguments += " -Host $quotedHost"
    $wrapperArguments += " -Host $quotedHost"
    $rawProbeArguments += " -Host $quotedHost"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $quickFlowArguments += " -InputText $quotedInputText"
    $quickArguments += " -InputText $quotedInputText"
    $wrapperArguments += " -InputText $quotedInputText"
    $rawProbeArguments += " -InputText $quotedInputText"
}
if ($Port) {
    $wrapperArguments += " -Port $Port"
    $rawProbeArguments += " -Port $Port"
}
if ($ServerReadyTimeoutSeconds) {
    $quickFlowArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $quickArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $rawProbeArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($WindowReadyAttempts) {
    $quickFlowArguments += " -HomeWindowReadyAttempts $WindowReadyAttempts"
    $quickArguments += " -HomeWindowReadyAttempts $WindowReadyAttempts"
    $wrapperArguments += " -WindowReadyAttempts $WindowReadyAttempts"
    $rawProbeArguments += " -WindowReadyAttempts $WindowReadyAttempts"
}
if ($TitleWaitAttempts) {
    $quickFlowArguments += " -HomeTitleWaitAttempts $TitleWaitAttempts"
    $quickArguments += " -HomeTitleWaitAttempts $TitleWaitAttempts"
    $wrapperArguments += " -TitleWaitAttempts $TitleWaitAttempts"
    $rawProbeArguments += " -TitleWaitAttempts $TitleWaitAttempts"
}
if ($PollMilliseconds) {
    $quickFlowArguments += " -HomePollMilliseconds $PollMilliseconds"
    $quickArguments += " -HomePollMilliseconds $PollMilliseconds"
    $wrapperArguments += " -PollMilliseconds $PollMilliseconds"
    $rawProbeArguments += " -PollMilliseconds $PollMilliseconds"
}
if ($LeaveOpen) {
    $quickFlowArguments += " -LeaveOpen"
    $quickArguments += " -LeaveOpen"
    $wrapperArguments += " -LeaveOpen"
    $rawProbeArguments += " -LeaveOpen"
}

$flow = [ordered]@{
    issue = "Headed Windows Google reduced homepage validation flow"
    focus = "Read-first handoff from the bounded localhost and quick/title gates into the reduced homepage Enter-submit pass on the real headed surface, with a dedicated fail-fast surface check before the wrapper or raw probe runs."
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced-homepage guide, helper, runner, or raw probe drifted before you trust this smaller real-surface issue #3 gate."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $surfaceCheck)
        }
        [ordered]@{
            name = "quick-flow"
            goal = "Print the faster title-plus-watch handoff when you want the last narrower gate spelled out before the reduced homepage pass."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $quickFlowRunner, $quickFlowArguments)
        }
        [ordered]@{
            name = "quick-wrapper"
            goal = "Run the dedicated quick wrapper when you want the title markers and watch phase rechecked before the reduced homepage step."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $quickRunner, $quickArguments)
        }
        [ordered]@{
            name = "reduced-homepage"
            goal = "Run the dedicated reduced homepage wrapper so the real-surface focus, typed-text, and Enter-submit proof stays on one reusable command surface."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $wrapperRunner, $wrapperArguments)
        }
        [ordered]@{
            name = "raw-probe"
            goal = "Run the underlying reduced homepage probe directly when you need the exact headed localhost script without the wrapper layer."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $rawProbe, $rawProbeArguments)
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1 after the reduced homepage wrapper is green when you want the bounded saved-homepage checkpoint printed next.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 after the reduced homepage wrapper is green when the next question is keydown, keypress, and submit ordering.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 after the reduced homepage wrapper is green when you need the stricter shared Enter-order ladder before manual or live replay."
    )
    notes = @(
        "Run the reduced-homepage surface checker first so missing guides, helpers, runner wiring, or the raw probe fail before the later-stage real-surface pass looks trustworthy.",
        "Keep the quick-flow and quick-wrapper steps ahead of the reduced-homepage wrapper when you still want the last narrower title-plus-watch gate visible in the same printed ladder.",
        "Prefer the dedicated wrapper unless you already know you need the raw direct probe output from tmp-browser-smoke/google-home.",
        "Use the same host, port, input text, and timing overrides here when you need the reduced homepage pass aligned with the broader issue #3 helpers.",
        "When LeaveOpen is set, the quick and reduced-homepage commands keep the headed browser open after the bounded phases finish so the real surface is easier to inspect."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google reduced homepage validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Leave open after reduced-homepage pass: {0}" -f ([bool]$LeaveOpen))
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
