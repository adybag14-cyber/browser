[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

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

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$surfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArguments -Name RepoRoot -Value $resolvedRepoRoot

$launcherArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $launcherArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $launcherArguments -Name InputPath -Values $InputPath

$googleFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleFlowArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $googleFlowArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 Windows replay Google attached preflight'
    purpose = 'Print the smaller replay-side preflight ladder that rules out attached-pages sidecar and asset drift before deeper Google-shaped headed-browser diagnosis resumes.'
    repo_root = $resolvedRepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    recommended_next_key = 'launcher_companion'
    recommended_next_reason = 'Run the dedicated launcher companion first so the wrapper-backed sidecar and asset audit ladder stays visible before narrowing into the Google attached-page flow and issue-specific entrypoint.'
    surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_google_attached_preflight_validation_surface.ps1' -Arguments $surfaceCheckArguments
    surface_check_reason = 'Use this first when the replay-side preflight helper, launcher companion lane, or Google attached-page follow-up may have drifted.'
    helper_commands = [ordered]@{
        launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments
        launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        wrapper_google_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $launcherArguments -Switches @('GoogleStyle', 'AuditSidecars')
        wrapper_google_asset_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $launcherArguments -Switches @('GoogleStyle', 'AuditAssets')
        wrapper_google_manifest = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $launcherArguments -Switches @('GoogleStyle', 'PrintManifest')
        wrapper_google_launch = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $launcherArguments -Switches @('GoogleStyle')
        google_attached_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $surfaceCheckArguments
        google_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleFlowArguments -Switches @('GoogleStyle')
        google_attached_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleFlowArguments
        google_entrypoint_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments
        google_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
    }
    companion_paths = [ordered]@{
        preflight_surface_check = 'scripts/windows/check_google_issue3_windows_replay_google_attached_preflight_validation_surface.ps1'
        replay_quickstart_note = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
        replay_attached_quickstart_note = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        attached_pages_launcher_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'
        attached_pages_launcher_companion = 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1'
        attached_pages_launcher_wrapper = 'scripts/windows/start_attached_pages_catalog.ps1'
        attached_pages_launcher_readme = 'tmp-browser-smoke/attached-pages/README.md'
        google_attached_html_validation_flow_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        google_attached_html_entrypoint_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        suite_router_next_steps_note = 'docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md'
    }
    notes = @(
        'Run the preflight surface check first when the replay-side launcher lane itself may have drifted.',
        'Run the launcher companion surface check before trusting the wrapper-backed ladder if attached-pages helper names, note paths, or wrapper switches may have moved.',
        'Prefer launcher_companion first, then wrapper_google_sidecar_audit, then wrapper_google_asset_audit. That keeps missing sibling _files bundles and missing local assets from looking like headed-browser regressions.',
        'Use wrapper_google_manifest when you want the pinned Google-style selection surfaced without starting the localhost server yet.',
        'Use wrapper_google_launch only after the sidecar and asset audits are clear enough that the next failure is likely browser-side rather than export-side.',
        'Keep the replay quickstart notes, the attached-pages README, the dedicated Google attached-page flow note, and the issue-specific Google entrypoint note nearby so the written route stays aligned with this replay-side preflight helper.'
    )
}

$helper.recommended_next_command = $helper.helper_commands[$helper.recommended_next_key]

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows replay Google attached preflight'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host (("Surface check:         {0}") -f $helper.surface_check_command)
Write-Host (("Guard reason:          {0}") -f $helper.surface_check_reason)
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Replay-side launcher lane:'
Write-Host (("  1. Launcher check:      {0}") -f $helper.helper_commands.launcher_surface_check)
Write-Host (("  2. Launcher helper:     {0}") -f $helper.helper_commands.launcher_companion)
Write-Host (("  3. Sidecar audit:       {0}") -f $helper.helper_commands.wrapper_google_sidecar_audit)
Write-Host (("  4. Asset audit:         {0}") -f $helper.helper_commands.wrapper_google_asset_audit)
Write-Host (("  5. Print manifest:      {0}") -f $helper.helper_commands.wrapper_google_manifest)
Write-Host (("  6. Launch catalog:      {0}") -f $helper.helper_commands.wrapper_google_launch)
Write-Host ''
Write-Host 'Google attached follow-up:'
Write-Host (("  1. Surface check:       {0}") -f $helper.helper_commands.google_attached_surface_check)
Write-Host (("  2. Asset closure:       {0}") -f $helper.helper_commands.google_asset_closure)
Write-Host (("  3. Flow guide:          {0}") -f $helper.helper_commands.google_attached_flow)
Write-Host (("  4. Entry check:         {0}") -f $helper.helper_commands.google_entrypoint_surface_check)
Write-Host (("  5. Entry helper:        {0}") -f $helper.helper_commands.google_entrypoint)
Write-Host (("  6. Next-step matrix:    {0}") -f $helper.helper_commands.suite_router_next_steps)
Write-Host ''
Write-Host (("Preflight check:          {0}") -f $helper.companion_paths.preflight_surface_check)
Write-Host (("Replay quickstart note:   {0}") -f $helper.companion_paths.replay_quickstart_note)
Write-Host (("Replay attached note:     {0}") -f $helper.companion_paths.replay_attached_quickstart_note)
Write-Host (("Launcher surface check:   {0}") -f $helper.companion_paths.attached_pages_launcher_surface_check)
Write-Host (("Launcher companion:       {0}") -f $helper.companion_paths.attached_pages_launcher_companion)
Write-Host (("Launcher wrapper:         {0}") -f $helper.companion_paths.attached_pages_launcher_wrapper)
Write-Host (("Launcher guide:           {0}") -f $helper.companion_paths.attached_pages_launcher_readme)
Write-Host (("Google flow note:         {0}") -f $helper.companion_paths.google_attached_html_validation_flow_note)
Write-Host (("Google entrypoint note:   {0}") -f $helper.companion_paths.google_attached_html_entrypoint_note)
Write-Host (("Next-step note:           {0}") -f $helper.companion_paths.suite_router_next_steps_note)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
