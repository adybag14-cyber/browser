[CmdletBinding()]
param(
    [switch]$Json,
    [string[]]$ManualInputPath,
    [int]$ManualPort = 8123
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$runner = '.\scripts\windows\run_google_input_validation.ps1'
$titleCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase title"
$quickCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase quick"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase home"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared"
$watchCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase watch"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase all -IncludeTitleProbe -IncludeSharedInput -IncludeWatch"

$manualCommand = $null
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $quotedPaths = $ManualInputPath | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort -ManualInputPath " + ($quotedPaths -join ", ")
}

$flow = [ordered]@{
    issue = "Headed Windows Google input validation flow"
    focus = "Issue #3 first-pass validation order for title readiness, reduced homepage submit, shared submit gates, watch mode, and saved-page localhost follow-up."
    steps = @(
        [ordered]@{
            name = "title"
            goal = "Check bounded readiness and title updates on the reduced Google-style page."
            command = $titleCommand
        }
        [ordered]@{
            name = "quick"
            goal = "Run the fast first pass that combines the title probe and self-starting watch probe."
            command = $quickCommand
        }
        [ordered]@{
            name = "home"
            goal = "Run the reduced homepage Enter-submit pass on the headed surface."
            command = $homeCommand
        }
        [ordered]@{
            name = "shared"
            goal = "Run the nearest shared submit gates before the live Google manual pass."
            command = $sharedCommand
        }
        [ordered]@{
            name = "watch"
            goal = "Re-run the self-starting watcher when you need live title-stream confirmation like SUBMIT:QZ."
            command = $watchCommand
        }
        [ordered]@{
            name = "full"
            goal = "Fold the fast title, shared submit gates, and watcher into the broader Google-input validation flow."
            command = $fullCommand
        }
    )
    saved_page_follow_up = if ($manualCommand) {
        [ordered]@{
            goal = "Compare the attached or saved localhost pages against the bounded Google and shared-input probes."
            command = $manualCommand
        }
    } else {
        [ordered]@{
            goal = "After the matching bounded suite is green, rerun with -ManualInputPath to stage the saved or attached localhost pages."
            command = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort -ManualInputPath '<saved-html-or-folder>'"
        }
    }
    notes = @(
        "Start with title or quick before the broader homepage pass.",
        "Use shared before a live Google manual check when input or submit behavior still looks suspicious.",
        "Use manual only after the closest bounded suite is already green."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google input validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "[manual] $($flow.saved_page_follow_up.goal)"
Write-Host ("  {0}" -f $flow.saved_page_follow_up.command)
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
