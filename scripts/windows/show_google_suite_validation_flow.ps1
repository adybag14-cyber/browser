[CmdletBinding()]
param(
  [int]$ManualPort = 8123,
  [string]$ManualInitialPage = "google-saved-page.html",
  [switch]$ManualGoogleStyle,
  [switch]$LeaveOpen,
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

$manualFlags = [System.Collections.Generic.List[string]]::new()
$manualFlags.Add("-ManualPort $ManualPort")
if (-not [string]::IsNullOrWhiteSpace($ManualInitialPage)) {
  $manualFlags.Add("-ManualInitialPage $(ConvertTo-PowerShellSingleQuotedLiteral -Value $ManualInitialPage)")
}
if ($ManualGoogleStyle) {
  $manualFlags.Add("-ManualGoogleStyle")
}
if ($LeaveOpen) {
  $manualFlags.Add("-LeaveOpen")
}
$manualSuffix = if ($manualFlags.Count -gt 0) { " " + ($manualFlags -join " ") } else { "" }

$flow = [ordered]@{
  issue = "Issue #3 bounded validation flow"
  focus = "Compact first-stop helper for the headed Windows Google input ladder: fail fast on validation-surface drift, read the bounded flow helpers in order, then run the smallest issue #3 command surface that matches the current stage."
  manual_port = $ManualPort
  manual_initial_page = $ManualInitialPage
  manual_google_style = [bool]$ManualGoogleStyle
  leave_open = [bool]$LeaveOpen
  steps = @(
    [ordered]@{
      name = "surface-check"
      goal = "Fail fast if a linked issue #3 guide or helper drifted out of sync before you trust any broader validation output."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1"
    }
    [ordered]@{
      name = "surface-check-attached-html"
      goal = "Fail fast on the attached or saved-page follow-up surface before you widen into the Google-style localhost handoff."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1 -Profile attached-html"
    }
    [ordered]@{
      name = "title-guide"
      goal = "Read the reduced title markers first so the bounded headed output maps cleanly to focus, typed text, and Enter-submit stages."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_probe_trace_guide.ps1"
    }
    [ordered]@{
      name = "title-flow"
      goal = "Print the narrower title ladder before any broader manual or live replay."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
    }
    [ordered]@{
      name = "homepage-fixture-flow"
      goal = "Print the bounded saved-homepage fixture ladder when the next follow-up is itself a captured Google homepage."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
    }
    [ordered]@{
      name = "submit-timing-flow"
      goal = "Print the bounded Google-shaped keydown, keypress, and submit-ordering slice before you execute it."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
    }
    [ordered]@{
      name = "shared-enter-order-flow"
      goal = "Print the stricter shared Enter-order ladder before you widen back out to attached, saved-page, or live Google follow-up."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1"
    }
    [ordered]@{
      name = "recommended-runner"
      goal = "Run the current localhost-first issue #3 bounded pass when the earlier helpers look intact and you want the full reduced ladder in one command."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1$manualSuffix"
    }
    [ordered]@{
      name = "submit-path-runner"
      goal = "Run the later-stage saved-homepage-fixture, submit-timing, and shared Enter-order stack without replaying the earlier localhost title gates."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
    }
    [ordered]@{
      name = "attached-html-flow"
      goal = "Only after the bounded phases are green, print the Google-style attached HTML handoff for current-run snapshots."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
    }
    [ordered]@{
      name = "saved-page-flow"
      goal = "Only after the bounded phases are green, print the explicit saved-page follow-up for manually staged HTML inputs."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'"
    }
    [ordered]@{
      name = "broader-flow"
      goal = "Use the larger reusable issue #3 helper when you want the same checker-first order surfaced through the full command map."
      command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1$manualSuffix"
    }
  )
  notes = @(
    "Start with the validation-surface checks, not the attached or live Google pass.",
    "Use the printed flow helpers first when you want the current bounded ladder explained before you execute the matching runner.",
    "Keep localhost, title, reduced homepage, saved homepage fixture, submit timing, and shared Enter-order agreement ahead of any saved-page, attached-page, or live-homepage replay.",
    "Treat KEYDOWN:<text>|13|13 before SUBMIT:<text> as the bounded Enter-order acceptance edge.",
    "ManualInitialPage is single-quoted here on purpose so saved HTML filenames with spaces stay intact when you copy the printed command."
  )
}

if ($Json) {
  $flow | ConvertTo-Json -Depth 6
  exit 0
}

Write-Host $flow.issue
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Manual port: {0}" -f $flow.manual_port)
Write-Host ("Manual initial page: {0}" -f $flow.manual_initial_page)
Write-Host ("Manual Google-style follow-up: {0}" -f $flow.manual_google_style)
Write-Host ("Leave open after bounded phases: {0}" -f $flow.leave_open)
Write-Host ""
foreach ($step in $flow.steps) {
  Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
  Write-Host ("  {0}" -f $step.command)
  Write-Host ""
}
Write-Host "Working rule:"
foreach ($note in $flow.notes) {
  Write-Host ("- {0}" -f $note)
}
