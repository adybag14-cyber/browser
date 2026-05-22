[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$InputPath = "",
    [string]$PreferredInitialPage = "",
    [string]$SummaryPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }
        $cursor = $parent
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Format-QuotedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-OptionalArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    $Arguments.Add((Format-QuotedArgument -Value $Value))
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [string[]]$ExtraArgs = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    if ($ExtraArgs.Count -gt 0) {
        $command += " " + ($ExtraArgs -join " ")
    }

    return $command
}

$sharedArgs = [System.Collections.Generic.List[string]]::new()
Add-OptionalArgument -Arguments $sharedArgs -Name RepoRoot -Value $RepoRoot
Add-OptionalArgument -Arguments $sharedArgs -Name InputPath -Value $InputPath
Add-OptionalArgument -Arguments $sharedArgs -Name PreferredInitialPage -Value $PreferredInitialPage
Add-OptionalArgument -Arguments $sharedArgs -Name SummaryPath -Value $SummaryPath

$surfaceArgs = [System.Collections.Generic.List[string]]::new()
Add-OptionalArgument -Arguments $surfaceArgs -Name RepoRoot -Value $RepoRoot

Write-Section "Issue #3 Attached HTML Bundle Checklist"
Write-Host "Use this compact route when the replay should stay pinned to the known three-page compatibility bundle."
Write-Host ("Repo root: {0}" -f $RepoRoot)
if ($InputPath) {
    Write-Host ("Input path: {0}" -f $InputPath)
} else {
    Write-Host "Input path: pass -InputPath to pin a saved HTML file or folder."
}
if ($PreferredInitialPage) {
    Write-Host ("Preferred initial page: {0}" -f $PreferredInitialPage)
} else {
    Write-Host "Preferred initial page: pass -PreferredInitialPage to keep the Google Safety Centre page first."
}
if ($SummaryPath) {
    Write-Host ("Summary path: {0}" -f $SummaryPath)
}

Write-Section "Pinned Bundle"
Write-Host "Keep this exact file set together:"
Write-Host "  - Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html"
Write-Host "  - Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html"
Write-Host "  - Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"

Write-Section "Preflight"
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -ExtraArgs $surfaceArgs))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "start_attached_pages_catalog.ps1" -ExtraArgs ($sharedArgs + @("-AuditSidecars"))))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "start_attached_pages_catalog.ps1" -ExtraArgs ($sharedArgs + @("-AuditAssets"))))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "start_attached_pages_catalog.ps1" -ExtraArgs ($sharedArgs + @("-RequireCompleteSidecars", "-RequireCompleteAssets", "-PrintManifest"))))
Write-Host "  note: stop here if the sidecar or asset checks fail; that is an export-bundle problem first."

Write-Section "Router Re-entry"
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "show_headed_validation_suites.ps1" -ExtraArgs @("-ChangeArea", "attached-html-target-bundle")))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "show_headed_validation_suites.ps1" -ExtraArgs @("-ChangeArea", "google-attached-html")))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "show_google_issue3_windows_replay_attached_html_quickstart.ps1" -ExtraArgs $sharedArgs))
Write-Host ("  {0}" -f (Format-HelperCommand -ScriptName "show_google_attached_html_validation_flow.ps1" -ExtraArgs $sharedArgs))
Write-Host "  note: use the bundle route first, then widen only if the smaller attached-page signals pass."

Write-Section "Proof Loop"
Write-Host "  1. Google Safety Centre"
Write-Host "     Confirm the title resolves, the cookie bar renders, Agree and No thanks both activate, and one top navigation target can be focused or opened."
Write-Host "  2. Anthropic application"
Write-Host "     Confirm the form loads, one select-style field opens and closes, and Submit application stays reachable after scrolling."
Write-Host "  3. UAP page"
Write-Host "     Confirm the title renders, the search input accepts focus and typed text, one record-row opens the modal, Close returns to the list, and pagination advances."
Write-Host "  note: stop on the first failing page so the next fix stays narrow."

Write-Section "When To Escalate"
Write-Host "  - Use the rendering route first when the change touched layout, paint, screenshot timing, or visible headed-surface behavior."
Write-Host "  - Use the network route first when the change touched authenticated assets, fetch credentials, or shared subresource loading."
Write-Host "  - Reopen docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md when the bundle passes until focused text entry or Enter submit fails on the Google-shaped page."

Write-Section "Companion Notes"
Write-Host "  - docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
Write-Host "  - docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
Write-Host "  - docs/WINDOWS_FULL_USE.md"
Write-Host "  - docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
