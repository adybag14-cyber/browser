[CmdletBinding()]
param(
  [int]$ManualPort = 8123,
  [string]$ManualInitialPage = "google-saved-page.html",
  [switch]$ManualGoogleStyle,
  [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manualFlags = @(
  "-ManualPort $ManualPort",
  "-ManualInitialPage $ManualInitialPage"
)
if ($ManualGoogleStyle) {
  $manualFlags += "-ManualGoogleStyle"
}
if ($LeaveOpen) {
  $manualFlags += "-LeaveOpen"
}
$manualSuffix = if ($manualFlags.Count -gt 0) { " " + ($manualFlags -join " ") } else { "" }

$lines = @(
  "Issue #3 bounded validation flow",
  "",
  "1. Read the suite map and title markers first:",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_suite_validation_flow.ps1",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_probe_trace_guide.ps1",
  "",
  "2. Read the narrowed bounded ladders before any broader manual pass:",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1",
  "",
  "3. Run the bounded execution surface that matches the current stage:",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1$manualSuffix",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1",
  "",
  "4. Only after the bounded phases are green, widen into attached or saved-page follow-up:",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
  "   powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'",
  "",
  "Working rule:",
  "- Keep localhost, title, reduced homepage, saved homepage fixture, submit-path, submit-order, and shared Enter-order agreement ahead of any live-Google or long manual replay.",
  "- Treat KEYDOWN:<text>|13|13 before SUBMIT:<text> as the Enter-order acceptance edge on the bounded probes."
)

$lines -join [Environment]::NewLine
