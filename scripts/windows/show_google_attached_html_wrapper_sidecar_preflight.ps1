[CmdletBinding()]
param(
    [string]$RepoRoot,
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

function Format-WrapperCommand {
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

$surfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArguments -Name RepoRoot -Value $resolvedRepoRoot

$helper = [ordered]@{
    issue = 'Google attached HTML wrapper sidecar preflight'
    purpose = 'Keep the wrapper-backed sidecar audit, manifest, and strict Google-style launcher path together on one small surface before broader attached-page or issue #3 replay helpers take over.'
    repo_root = $resolvedRepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    recommended_next_key = 'wrapper_google_sidecar_audit'
    recommended_next_reason = 'The wrapper-backed Google-style sidecar audit is the cheapest honest preflight for the attached-pages export, so it should run before the broader validation-flow helper or a strict localhost launch.'
    surface_check_command = Format-WrapperCommand -ScriptName 'check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1' -Arguments $surfaceCheckArguments
    surface_check_reason = 'Use this first when the compact wrapper-backed preflight note, helper, or companion launcher pointers may have drifted.'
    helper_commands = [ordered]@{
        wrapper_google_sidecar_audit = Format-WrapperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'AuditSidecars')
        wrapper_google_sidecar_audit_allow_missing = Format-WrapperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'AuditSidecars', 'AllowMissingSidecars')
        wrapper_google_manifest = Format-WrapperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'PrintManifest')
        wrapper_google_strict_launch = Format-WrapperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars')
        broader_google_flow = Format-WrapperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $wrapperArguments
        python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @('--google-style', '--audit-sidecars')
    }
    companion_paths = [ordered]@{
        preflight_surface_check = 'scripts/windows/check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1'
        preflight_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_WRAPPER_SIDECAR_PREFLIGHT.md'
        broader_google_flow_note = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        broader_google_flow_helper = 'scripts/windows/show_google_attached_html_validation_flow.ps1'
        attached_pages_launcher_wrapper = 'scripts/windows/start_attached_pages_catalog.ps1'
        attached_pages_launcher_entrypoint = 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py'
        attached_pages_launcher_readme = 'tmp-browser-smoke/attached-pages/README.md'
    }
    notes = @(
        'Run the compact surface check first when this wrapper-backed preflight note or helper output may have drifted.',
        'Prefer the wrapper-backed Google-style sidecar audit before the broader Google attached-page helper when the saved export itself may be incomplete.',
        'Use the manifest print when you need to confirm which attached pages the launcher will serve before a strict localhost launch.',
        'Use the strict launch only after the sidecar audit is clean enough that a missing sibling _files bundle should stop the route immediately.',
        'Use the lower-level Python launcher directly only when you need to bypass the wrapper while keeping the same Google-style attached-page preflight context.'
    )
}

$helper.recommended_next_command = $helper.helper_commands[$helper.recommended_next_key]

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google attached HTML wrapper sidecar preflight'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
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
Write-Host 'Wrapper-backed ladder:'
Write-Host (("  1. Google sidecars:    {0}") -f $helper.helper_commands.wrapper_google_sidecar_audit)
Write-Host (("  2. Allow-missing mode: {0}") -f $helper.helper_commands.wrapper_google_sidecar_audit_allow_missing)
Write-Host (("  3. Google manifest:    {0}") -f $helper.helper_commands.wrapper_google_manifest)
Write-Host (("  4. Strict launch:      {0}") -f $helper.helper_commands.wrapper_google_strict_launch)
Write-Host (("  5. Broader flow:       {0}") -f $helper.helper_commands.broader_google_flow)
Write-Host ''
Write-Host 'Lower-level fallback:'
Write-Host (("  1. Python sidecars:    {0}") -f $helper.helper_commands.python_google_sidecar_audit)
Write-Host ''
Write-Host (("Preflight note:         {0}") -f $helper.companion_paths.preflight_note)
Write-Host (("Broader flow note:      {0}") -f $helper.companion_paths.broader_google_flow_note)
Write-Host (("Broader flow helper:    {0}") -f $helper.companion_paths.broader_google_flow_helper)
Write-Host (("Wrapper launcher:       {0}") -f $helper.companion_paths.attached_pages_launcher_wrapper)
Write-Host (("Python launcher:        {0}") -f $helper.companion_paths.attached_pages_launcher_entrypoint)
Write-Host (("Attached-pages guide:   {0}") -f $helper.companion_paths.attached_pages_launcher_readme)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
