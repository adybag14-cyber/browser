[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
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

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
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

function Format-PythonLauncherCommand {
    param(
        [string]$RepoRootOverride,
        [string[]]$InputValues,
        [string]$PreferredInitialPage,
        [string[]]$Flags = @()
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add('python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py')

    if (-not [string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $parts.Add('--repo-root')
        $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRootOverride))
    }

    if ($InputValues) {
        foreach ($value in $InputValues) {
            if ([string]::IsNullOrWhiteSpace($value)) {
                continue
            }
            $parts.Add('--input')
            $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
        $parts.Add('--preferred-initial-page')
        $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $PreferredInitialPage))
    }

    foreach ($flag in $Flags) {
        if ([string]::IsNullOrWhiteSpace($flag)) {
            continue
        }
        $parts.Add($flag)
    }

    return ($parts -join ' ')
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$wrapperArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $wrapperArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $wrapperArguments -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $wrapperArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$surfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArguments -Name RepoRoot -Value $resolvedRepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 attached-pages launcher companion'
    purpose = 'Keep the sidecar-first attached-pages launcher path visible beside the issue #3 Google attached localhost replay helpers so localhost bundle problems can be ruled out quickly before deeper headed-browser diagnosis, including the stricter sidecar and asset-gated launch path when the bundle still needs to fail fast before serving, the preferred-first-page wrapper handoff for the pinned three-page compatibility bundle, and the pinned proof-entrypoint checker/helper pair when replay is already locked to the known three-page bundle.'
    repo_root = $resolvedRepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    preferred_initial_page = $PreferredInitialPage
    recommended_next_key = 'wrapper_sidecar_audit'
    recommended_next_reason = 'The wrapper-backed sidecar audit is the cheapest honest preflight for issue #3 attached-page replay, so it should run before the broader asset audit, manifest print, strict-launch gates, or the narrower proof-only bundle follow-up.'
    surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments
    surface_check_reason = 'Use this first when the launcher companion itself, its note pointers, or the wrapper-backed attached-pages route may have drifted.'
    helper_commands = [ordered]@{
        wrapper_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('AuditSidecars')
        wrapper_asset_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('AuditAssets')
        wrapper_print_manifest = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('PrintManifest')
        wrapper_strict_launch = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteSidecars')
        wrapper_strict_assets = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteAssets')
        wrapper_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')
        wrapper_google_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'AuditSidecars')
        wrapper_google_asset_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'AuditAssets')
        wrapper_google_manifest = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'PrintManifest')
        wrapper_google_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars', 'RequireCompleteAssets')
        wrapper_google_launch = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle')
        proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments
        proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments
        python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-sidecars')
        python_asset_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-assets')
        python_print_manifest = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--print-manifest')
        python_strict_launch = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--require-complete-sidecars')
        python_strict_assets = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--require-complete-assets')
        python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--require-complete-sidecars', '--require-complete-assets')
        python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--audit-sidecars')
        python_google_asset_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--audit-assets')
        python_google_manifest = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--print-manifest')
        python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')
        python_google_launch = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style')
    }
    companion_paths = [ordered]@{
        launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'
        attached_pages_launcher_readme = 'tmp-browser-smoke/attached-pages/README.md'
        attached_pages_launcher_wrapper = 'scripts/windows/start_attached_pages_catalog.ps1'
        attached_pages_launcher_entrypoint = 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py'
        attached_html_target_bundle_proof_entrypoint_note = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        google_attached_html_validation_flow_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        google_attached_html_entrypoint_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        windows_full_use_attached_html_catalog_quickstart_note = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        windows_replay_attached_html_quickstart_note = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    }
    notes = @(
        'Run the surface check first when the launcher companion itself, its note pointers, or the wrapper-backed attached-pages route may have drifted.',
        'Use this helper when the issue #3 replay has already moved into attached localhost follow-up and you want the wrapper-backed preflight ladder and the lower-level Python launcher kept on one compact surface.',
        'Prefer wrapper_sidecar_audit first, then wrapper_asset_audit, then wrapper_print_manifest, wrapper_strict_launch, wrapper_strict_assets, or wrapper_strict_bundle. That keeps missing sibling _files bundles or still-missing local assets from being mistaken for headed-browser regressions.',
        'Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.',
        'Prefer the GoogleStyle variants when the current attached-page set should keep the strongest Google-like page first while replay narrows back into the issue-specific helper chain.',
        'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.',
        'Keep the attached-pages README, the Windows wrapper, and the lower-level Python launcher visible beside the issue #3 Google attached HTML flow and entrypoint notes so the preflight order stays aligned across Windows and cross-platform replay.'
    )
}

$helper.recommended_next_command = $helper.helper_commands[$helper.recommended_next_key]
if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    $helper.notes += "Current preferred initial page: $PreferredInitialPage"
    $helper.notes += 'The wrapper-backed launcher ladder now preserves -PreferredInitialPage through the sidecar audit, asset audit, manifest print, strict gates, and Google-style launch variants so the known bundle can stay pinned to one first page without hand-editing each command.'
    $helper.notes += 'The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-pages launcher companion'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
if (-not [string]::IsNullOrWhiteSpace($helper.preferred_initial_page)) {
    Write-Host (("Preferred page: {0}") -f $helper.preferred_initial_page)
}
Write-Host (("Surface check:         {0}") -f $helper.surface_check_command)
Write-Host (("Guard reason:          {0}") -f $helper.surface_check_reason)
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Windows wrapper ladder:'
Write-Host (("  1. Sidecar audit:      {0}") -f $helper.helper_commands.wrapper_sidecar_audit)
Write-Host (("  2. Asset audit:        {0}") -f $helper.helper_commands.wrapper_asset_audit)
Write-Host (("  3. Print manifest:     {0}") -f $helper.helper_commands.wrapper_print_manifest)
Write-Host (("  4. Strict sidecars:    {0}") -f $helper.helper_commands.wrapper_strict_launch)
Write-Host (("  5. Strict assets:      {0}") -f $helper.helper_commands.wrapper_strict_assets)
Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle)
Write-Host (("  7. Google sidecars:    {0}") -f $helper.helper_commands.wrapper_google_sidecar_audit)
Write-Host (("  8. Google assets:      {0}") -f $helper.helper_commands.wrapper_google_asset_audit)
Write-Host (("  9. Google manifest:    {0}") -f $helper.helper_commands.wrapper_google_manifest)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle)
Write-Host (("  11. Google launch:     {0}") -f $helper.helper_commands.wrapper_google_launch)
Write-Host ''
Write-Host 'Pinned bundle proof follow-up:'
Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)
Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)
Write-Host ''
Write-Host 'Cross-platform launcher ladder:'
Write-Host (("  1. Sidecar audit:      {0}") -f $helper.helper_commands.python_sidecar_audit)
Write-Host (("  2. Asset audit:        {0}") -f $helper.helper_commands.python_asset_audit)
Write-Host (("  3. Print manifest:     {0}") -f $helper.helper_commands.python_print_manifest)
Write-Host (("  4. Strict sidecars:    {0}") -f $helper.helper_commands.python_strict_launch)
Write-Host (("  5. Strict assets:      {0}") -f $helper.helper_commands.python_strict_assets)
Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle)
Write-Host (("  7. Google sidecars:    {0}") -f $helper.helper_commands.python_google_sidecar_audit)
Write-Host (("  8. Google assets:      {0}") -f $helper.helper_commands.python_google_asset_audit)
Write-Host (("  9. Google manifest:    {0}") -f $helper.helper_commands.python_google_manifest)
Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)
Write-Host (("  11. Google launch:     {0}") -f $helper.helper_commands.python_google_launch)
Write-Host ''
Write-Host (("Launcher surface check: {0}") -f $helper.companion_paths.launcher_companion_surface_check)
Write-Host (("Attached-pages guide:    {0}") -f $helper.companion_paths.attached_pages_launcher_readme)
Write-Host (("Windows wrapper:         {0}") -f $helper.companion_paths.attached_pages_launcher_wrapper)
Write-Host (("Python launcher:         {0}") -f $helper.companion_paths.attached_pages_launcher_entrypoint)
Write-Host (("Bundle proof note:       {0}") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)
Write-Host (("Google flow note:        {0}") -f $helper.companion_paths.google_attached_html_validation_flow_note)
Write-Host (("Google entrypoint note:  {0}") -f $helper.companion_paths.google_attached_html_entrypoint_note)
Write-Host (("Windows catalog note:    {0}") -f $helper.companion_paths.windows_full_use_attached_html_catalog_quickstart_note)
Write-Host (("Windows replay note:     {0}") -f $helper.companion_paths.windows_replay_attached_html_quickstart_note)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
