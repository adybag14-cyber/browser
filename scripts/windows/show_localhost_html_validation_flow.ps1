[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$Json
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

$suiteHelper = '.\scripts\windows\show_headed_validation_suites.ps1'
$summaryHelper = '.\scripts\windows\summarize_localhost_html_pages.ps1'
$localhostHelper = '.\scripts\windows\start_localhost_html_validation.ps1'
$stagedHelper = '.\scripts\windows\start_staged_localhost_html_validation.ps1'
$googleRunner = '.\scripts\windows\run_google_input_validation.ps1'
$googleSavedFlowHelper = '.\scripts\windows\show_saved_page_google_validation_flow.ps1'
$preferredInitialPageArgument = ""
if ($PreferredInitialPage) {
    $quotedPreferredInitialPage = ConvertTo-PowerShellSingleQuotedLiteral -Value $PreferredInitialPage
    $preferredInitialPageArgument = " -PreferredInitialPage $quotedPreferredInitialPage"
}
$manualInitialPageArgument = if ($PreferredInitialPage) {
    " -ManualInitialPage $quotedPreferredInitialPage"
} else {
    ""
}
$launchInitialPageArgument = if ($PreferredInitialPage) {
    " -InitialPage $quotedPreferredInitialPage"
} else {
    ""
}

if ($PageRoot) {
    $quotedPageRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $PageRoot
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot $quotedPageRoot -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $localhostHelper -PageRoot $quotedPageRoot -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait"
    $googleSavedFlowCommand = "powershell -ExecutionPolicy Bypass -File $googleSavedFlowHelper -PageRoot $quotedPageRoot -Port $Port$preferredInitialPageArgument"
} else {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>' -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $localhostHelper -PageRoot '<saved-page-dir>' -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait"
    $googleSavedFlowCommand = "powershell -ExecutionPolicy Bypass -File $googleSavedFlowHelper -PageRoot '<saved-page-dir>' -Port $Port -PreferredInitialPage '<preferred-initial-page>'"
}

if ($InputPath -and $InputPath.Count -gt 0) {
    $quotedPaths = $InputPath | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }
    $joinedPaths = $quotedPaths -join ", "
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath $joinedPaths -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait"
    $googleManualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualInputPath $joinedPaths"
    $googleSavedFlowCommand = "powershell -ExecutionPolicy Bypass -File $googleSavedFlowHelper -InputPath $joinedPaths -Port $Port$preferredInitialPageArgument"
} else {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath '<saved-html-or-folder>' -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait"
    $googleManualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'"
}

$flow = [ordered]@{
    issue = "Saved localhost HTML validation flow"
    focus = "First-pass command order for attached or saved HTML pages after the matching bounded headed suite is green."
    preferred_initial_page = $PreferredInitialPage
    steps = @(
        [ordered]@{
            name = "suite-map"
            goal = "Choose the closest bounded suite before starting the real saved-page pass."
            command = "powershell -ExecutionPolicy Bypass -File $suiteHelper -ChangeArea manual-html"
        }
        [ordered]@{
            name = "summary"
            goal = "Inventory titles, interactive surfaces, and suggested bounded suites for the saved-page set."
            command = $summaryCommand
        }
        [ordered]@{
            name = "direct"
            goal = "Serve one saved-page directory directly on localhost and launch the headed browser against it."
            command = $directCommand
        }
        [ordered]@{
            name = "staged"
            goal = "Stage mixed standalone HTML files and saved-page folders into one clean localhost session."
            command = $stagedCommand
        }
        [ordered]@{
            name = "google-flow"
            goal = "When the saved-page follow-up belongs to issue #3, print the dedicated Google-style saved-page flow so the reduced localhost, quick, reduced homepage, and shared Enter-order gates run before the manual headed pass and the live trace step stays close at hand when real Google still diverges."
            command = $googleSavedFlowCommand
        }
        [ordered]@{
            name = "google-manual"
            goal = "Use the Google validation runner manual phase only after the dedicated Google-style saved-page flow has already narrowed the matching bounded phases."
            command = $googleManualCommand
        }
    )
    notes = @(
        "Run the matching bounded suite first, then move into direct or staged localhost validation.",
        "Use summary before the manual pass when you need help picking the first page or closest bounded suite.",
        "Use google-flow before google-manual when the saved-page follow-up is part of the Google-style headed typing investigation, especially when the reduced homepage gate should run before the manual pass and the next likely evidence may need to come from the live trace step after the saved-page pass.",
        "When PreferredInitialPage is set, the direct, staged, Google-style flow, and Google manual commands keep that page as the first headed target instead of falling back to a generated index or another arbitrary file."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Saved localhost HTML validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
if ($PreferredInitialPage) {
    Write-Host ("Preferred initial page: {0}" -f $PreferredInitialPage)
}
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
