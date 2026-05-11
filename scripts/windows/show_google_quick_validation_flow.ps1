[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "QZ",
    [int]$TitlePort = 9582,
    [int]$WatchPort = 9582,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
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

$surfaceCheck = '.\\scripts\\windows\\check_google_quick_validation_surface.ps1'
$titleFlowRunner = '.\\scripts\\windows\\show_google_title_validation_flow.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_quick_validation.ps1'

$titleFlowArguments = ""
$wrapperArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $titleFlowArguments += " -RepoRoot $quotedRepoRoot"
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $titleFlowArguments += " -BrowserExe $quotedBrowserExe"
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $titleFlowArguments += " -Host $quotedHost"
    $wrapperArguments += " -Host $quotedHost"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $titleFlowArguments += " -InputText $quotedInputText"
    $wrapperArguments += " -InputText $quotedInputText"
}
if ($TitlePort) {
    $titleFlowArguments += " -TitlePort $TitlePort"
    $wrapperArguments += " -TitlePort $TitlePort"
}
if ($WatchPort) {
    $wrapperArguments += " -WatchPort $WatchPort"
}
if ($ServerReadyTimeoutSeconds) {
    $titleFlowArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($HomeWindowReadyAttempts) {
    $titleFlowArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
    $wrapperArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
}
if ($HomeTitleWaitAttempts) {
    $titleFlowArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
    $wrapperArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
}
if ($HomePollMilliseconds) {
    $titleFlowArguments += " -HomePollMilliseconds $HomePollMilliseconds"
    $wrapperArguments += " -HomePollMilliseconds $HomePollMilliseconds"
}
if ($WatchTimeoutSeconds) {
    $wrapperArguments += " -WatchTimeoutSeconds $WatchTimeoutSeconds"
}
if ($WatchPollMilliseconds) {
    $wrapperArguments += " -WatchPollMilliseconds $WatchPollMilliseconds"
}
if ($LeaveOpen) {
    $wrapperArguments += " -LeaveOpen"
}

$flow = [ordered]@{
    issue = "Headed Windows Google quick validation flow"
    focus = "Fast title-plus-watch triage for issue #3 after the reduced localhost probes are green, with a dedicated fail-fast surface check before the bounded title markers and self-starting watch pass."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the quick-validation guide, quick wrapper, watch helper, or title dependencies drifted before you trust this fast issue #3 path."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "title-flow"
            goal = "Print the bounded title-wrapper flow next when you want the focus, typed-text, and Enter-submit markers translated before the fast quick pass."
            command = "powershell -ExecutionPolicy Bypass -File $titleFlowRunner$titleFlowArguments"
        }
        [ordered]@{
            name = "quick-wrapper"
            goal = "Run the dedicated quick wrapper so the title probe and self-starting watch phase stay on the same reusable issue #3 command surface."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_home_validation.ps1 after the quick wrapper is green when you want the reduced headed homepage submit pass.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 after the quick wrapper is green when you want the bounded Google-shaped submit-ordering slice printed before you run it.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 after the quick wrapper is green when you want the stricter shared Enter-order stack printed before you run it."
    )
    notes = @(
        "Start with the surface-check when you want the fast quick slice to fail early on missing guide, wrapper, watch helper, or title-fixture drift before the broader issue #3 ladder.",
        "The title-flow step stays next so the bounded title markers are still explained before you rely on the quick wrapper's faster watch handoff.",
        "The quick wrapper is the preferred fast pass when you want the title probe and the watch phase paired without restating the longer flag bundle by hand.",
        "Use the same host, title port, watch port, input text, and timing overrides here when you need the quick pass aligned with the broader issue #3 flow.",
        "Use -LeaveOpen when you want the quick wrapper to keep the headed browser open after the bounded phases finish so the live state is easier to inspect."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google quick validation flow"
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
