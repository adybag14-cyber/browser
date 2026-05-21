[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @(),
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            if ($entry.Value -is [System.Collections.IEnumerable] -and -not ($entry.Value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($entry.Value)
                continue
            }

            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $valueList = @($value | Where-Object {
                if ($_ -is [string]) {
                    -not [string]::IsNullOrWhiteSpace($_)
                } else {
                    $null -ne $_
                }
            })
            if ($valueList.Count -eq 0) {
                continue
            }

            $command += " -$($entry.Key)"
            foreach ($item in $valueList) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$routeSurfaceArguments = [ordered]@{}
$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$attachedPagesLauncherArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedPagesLauncherArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $attachedPagesLauncherArguments -Name InputPath -Values $InputPath

$attachedHtmlChangeAreaSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments -RepoRootOverride $RepoRoot
$attachedHtmlChangeAreaQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
$attachedHtmlFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
$attachedPagesSidecarAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('AuditSidecars')
$attachedPagesGoogleSidecarAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('GoogleStyle', 'AuditSidecars')
$attachedPagesAssetAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('AuditAssets')
$attachedPagesManifestPrintCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('PrintManifest')
$attachedPagesStrictLaunchCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')
$attachedPagesLauncherCompanionSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments -RepoRootOverride $RepoRoot
$attachedPagesLauncherCompanionCommand = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $attachedPagesLauncherArguments
$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $routeSurfaceArguments -RepoRootOverride $RepoRoot
$googleIssue3AttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments -RepoRootOverride $RepoRoot
$googleAttachedHtmlFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
$topLevelAttachedHtmlEntryPointCommand = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
$topLevelAttachedHtmlCatalogQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
$windowsReplayAttachedHtmlQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments

$entrypoint = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML preflight'
    purpose = 'Keep the sidecar-first launcher-backed preflight visible from the top-level attached-page route before the replay narrows into the shorter issue-specific helper chain.'
    repo_root = $RepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    recommended_next_key = 'attached_pages_sidecar_audit'
    recommended_next_reason = 'The wrapper-backed sidecar audit is the cheapest honest preflight: it rules out a missing sibling `_files` bundle before the replay widens into deeper attached-page or Google-shaped helpers.'
    helper_commands = [ordered]@{
        attached_html_change_area_surface_check = $attachedHtmlChangeAreaSurfaceCheckCommand
        attached_html_change_area_quickstart = $attachedHtmlChangeAreaQuickstartCommand
        attached_html_flow = $attachedHtmlFlowCommand
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
        attached_pages_google_sidecar_audit = $attachedPagesGoogleSidecarAuditCommand
        attached_pages_asset_audit = $attachedPagesAssetAuditCommand
        attached_pages_print_manifest = $attachedPagesManifestPrintCommand
        attached_pages_strict_launch = $attachedPagesStrictLaunchCommand
        attached_pages_launcher_companion_surface_check = $attachedPagesLauncherCompanionSurfaceCheckCommand
        attached_pages_launcher_companion = $attachedPagesLauncherCompanionCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = $googleAttachedHtmlFlowCommand
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        top_level_attached_html_entrypoint = $topLevelAttachedHtmlEntryPointCommand
        top_level_attached_html_catalog_quickstart = $topLevelAttachedHtmlCatalogQuickstartCommand
    }
    note_paths = [ordered]@{
        attached_pages_guide = 'tmp-browser-smoke/attached-pages/README.md'
        windows_runbook = 'docs/WINDOWS_FULL_USE.md'
        top_level_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        top_level_catalog_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    }
    notes = @(
        'Run the sidecar audit first to rule out a missing sibling `_files` bundle before treating a replay failure as a browser regression.',
        'Use the Google-style sidecar audit when the current export is already Google-shaped and you want the strongest Google-like fixture kept first while the bundle is checked.',
        'Use the asset audit only after the sidecar bundle exists and you need the exact missing local asset references.',
        'Use the manifest print when you want the selected page order and localhost routes without starting the server.',
        'Use the strict launch command when both sidecars and referenced assets must be complete before the localhost replay is trusted.',
        'Use the launcher companion surface check before the smaller companion helper when that helper or its note pointers may have drifted.',
        'Keep the top-level attached-page bridge, the attached-pages guide, the Windows runbook, and the Google attached-page flow note nearby when you widen back into the broader issue #3 helper chain.'
    )
}

$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML preflight'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level attached-page preflight:'
Write-Host (("  1. Change-area check:      {0}") -f $entrypoint.helper_commands.attached_html_change_area_surface_check)
Write-Host (("  2. Change-area quickstart: {0}") -f $entrypoint.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  3. Attached flow helper:   {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host (("  4. Sidecar audit:          {0}") -f $entrypoint.helper_commands.attached_pages_sidecar_audit)
Write-Host (("  5. Google sidecar audit:   {0}") -f $entrypoint.helper_commands.attached_pages_google_sidecar_audit)
Write-Host (("  6. Asset audit:            {0}") -f $entrypoint.helper_commands.attached_pages_asset_audit)
Write-Host (("  7. Print manifest:         {0}") -f $entrypoint.helper_commands.attached_pages_print_manifest)
Write-Host (("  8. Strict launch:          {0}") -f $entrypoint.helper_commands.attached_pages_strict_launch)
Write-Host (("  9. Companion check:        {0}") -f $entrypoint.helper_commands.attached_pages_launcher_companion_surface_check)
Write-Host ((" 10. Companion helper:       {0}") -f $entrypoint.helper_commands.attached_pages_launcher_companion)
Write-Host ((" 11. Google surface check:   {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host ((" 12. Issue-specific Google:  {0}") -f $entrypoint.helper_commands.google_issue3_attached_html_surface_check)
Write-Host ((" 13. Google flow helper:     {0}") -f $entrypoint.helper_commands.google_attached_html_flow)
Write-Host ((" 14. Replay quickstart:      {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 15. Top-level bridge:       {0}") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)
Write-Host ((" 16. Catalog quickstart:     {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ''
Write-Host (("Attached-pages guide:       {0}") -f $entrypoint.note_paths.attached_pages_guide)
Write-Host (("Windows runbook:            {0}") -f $entrypoint.note_paths.windows_runbook)
Write-Host (("Top-level bridge note:      {0}") -f $entrypoint.note_paths.top_level_bridge)
Write-Host (("Top-level catalog note:     {0}") -f $entrypoint.note_paths.top_level_catalog_quickstart)
Write-Host (("Google flow note:           {0}") -f $entrypoint.note_paths.google_attached_html_flow)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
