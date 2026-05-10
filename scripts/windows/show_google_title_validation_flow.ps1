[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$TitlePort = 8159,
    [string]$InputText = "Q",
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

$wrapperRunner = '.\\scripts\\windows\\run_google_title_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-title-probe.ps1'

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
if ($TitlePort) {
    $wrapperArguments += " -TitlePort $TitlePort"
    $directProbeArguments += " -Port $TitlePort"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}
if ($ServerReadyTimeoutSeconds) {
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $directProbeArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($HomeWindowReadyAttempts) {
    $wrapperArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
    $directProbeArguments += " -WindowReadyAttempts $HomeWindowReadyAttempts"
}
if ($HomeTitleWaitAttempts) {
    $wrapperArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
    $directProbeArguments += " -TitleWaitAttempts $HomeTitleWaitAttempts"
}
if ($HomePollMilliseconds) {
    $wrapperArguments += " -HomePollMilliseconds $HomePollMilliseconds"
    $directProbeArguments += " -PollMilliseconds $HomePollMilliseconds"
}

$flow = [ordered]@{
    issue = "Headed Windows Google title validation flow"
    focus = "Bounded localhost readiness, click-focus, typed-text, and Enter-submit markers on the Google-style title probe before wider homepage or shared Enter-order passes."
    steps = @(
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated title wrapper first so the bounded probe stays on the same reusable command surface as the other Windows validation helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw title probe only when you need to narrow a wrapper failure to the underlying localhost fixture or headed click,type,submit path."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_quick_validation.ps1 after the title wrapper is green when you want the fast title-plus-watch first pass.",
        "Use .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home after the title wrapper is green when you want the reduced headed homepage submit pass.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 when the title wrapper is green and you want the stricter shared Enter-order stack printed before you run it."
    )
    notes = @(
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/google-investigation-next.",
        "Keep the title wrapper bounded to localhost before moving into the reduced homepage, shared, or live Google trace phases.",
        "Reuse the same host, port, input text, and timing overrides here when you need the title probe to stay aligned with the broader issue #3 validation flow."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google title validation flow"
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
