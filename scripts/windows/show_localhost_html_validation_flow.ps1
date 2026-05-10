[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [int]$Port = 8123,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$suiteHelper = '.\scripts\windows\show_headed_validation_suites.ps1'
$summaryHelper = '.\scripts\windows\summarize_localhost_html_pages.ps1'
$localhostHelper = '.\scripts\windows\start_localhost_html_validation.ps1'
$stagedHelper = '.\scripts\windows\start_staged_localhost_html_validation.ps1'
$googleRunner = '.\scripts\windows\run_google_input_validation.ps1'

if ($PageRoot) {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '$PageRoot' -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $localhostHelper -PageRoot '$PageRoot' -Port $Port -LaunchBrowser -Wait"
} else {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>' -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $localhostHelper -PageRoot '<saved-page-dir>' -Port $Port -LaunchBrowser -Wait"
}

if ($InputPath -and $InputPath.Count -gt 0) {
    $quotedPaths = $InputPath | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }
    $joinedPaths = $quotedPaths -join ", "
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath $joinedPaths -Port $Port -LaunchBrowser -Wait"
    $googleManualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInputPath $joinedPaths"
} else {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath '<saved-html-or-folder>' -Port $Port -LaunchBrowser -Wait"
    $googleManualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInputPath '<saved-html-or-folder>'"
}

$flow = [ordered]@{
    issue = "Saved localhost HTML validation flow"
    focus = "First-pass command order for attached or saved HTML pages after the matching bounded headed suite is green."
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
            name = "google-manual"
            goal = "When the saved-page follow-up belongs to issue #3, run the Google validation runner's manual phase against the same staged inputs."
            command = $googleManualCommand
        }
    )
    notes = @(
        "Run the matching bounded suite first, then move into direct or staged localhost validation.",
        "Use summary before the manual pass when you need help picking the first page or closest bounded suite.",
        "Use google-manual only when the saved-page follow-up is part of the Google-style headed typing investigation."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Saved localhost HTML validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
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
