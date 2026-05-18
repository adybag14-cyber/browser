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

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $env:LIGHTPANDA_REPO_ROOT
} else {
    $null
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 Windows replay attached HTML sidecar audit'
    purpose = 'Print the wrapper-backed sibling `_files` sidecar audit commands that should run before the replay-side or Google-shaped attached-page ladders widen into deeper localhost diagnosis.'
    repo_root = $resolvedRepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    attached_pages_readme_path = 'tmp-browser-smoke/attached-pages/README.md'
    attached_pages_sidecar_audit_path = 'tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py'
    attached_pages_launcher_path = 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py'
    wrapper_path = 'scripts/windows/start_attached_pages_catalog.ps1'
    commands = [ordered]@{
        audit_sidecars = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $sharedArguments -Switches @('AuditSidecars')
        audit_sidecars_json = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $sharedArguments -Switches @('AuditSidecars', 'AuditSidecarsJson')
        allow_missing_sidecars = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $sharedArguments -Switches @('AuditSidecars', 'AllowMissingSidecars')
    }
    notes = @(
        'Start here when the replay is already on the attached localhost branch and you want the cheapest honest export-integrity check before widening back into the replay-side or Google-shaped helper ladders.',
        'Use audit_sidecars first when the next question is whether a sibling `_files` bundle is missing altogether for one of the saved exports.',
        'Use audit_sidecars_json when a later helper or saved summary needs structured output instead of the plain-text report.',
        'Use allow_missing_sidecars only when you intentionally want the audit to report missing sidecars without failing the step.',
        'Keep docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md, docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md, docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md, docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md, tmp-browser-smoke/attached-pages/README.md, tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py, tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py, and scripts/windows/start_attached_pages_catalog.ps1 nearby when you want the written route beside these audit commands.'
    )
}

$helper.recommended_next_key = 'audit_sidecars'
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.explicit_input_path_count -gt 0) {
    'Explicit bundle paths are already pinned, so fail fast on missing sibling `_files` sidecars for those same inputs before widening into deeper replay or Google-shaped diagnosis.'
} elseif ($helper.repo_root) {
    'A non-default repo root is already pinned, so keep the wrapper-backed sidecar audit on that same checkout before widening back into the broader attached-page helper chain.'
} else {
    'No explicit bundle paths or repo-root override are in play yet, so start with the wrapper-backed sidecar audit and rule out a missing sibling `_files` bundle before deeper replay diagnosis starts.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows replay attached HTML sidecar audit'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Sidecar audit commands:'
Write-Host (("  Strict audit:           {0}") -f $helper.commands.audit_sidecars)
Write-Host (("  JSON audit:             {0}") -f $helper.commands.audit_sidecars_json)
Write-Host (("  Report-only audit:      {0}") -f $helper.commands.allow_missing_sidecars)
Write-Host ''
Write-Host (("Replay attached note:     {0}") -f (' ' + $helper.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Windows catalog note:     {0}") -f (' ' + $helper.windows_full_use_attached_html_catalog_quickstart_note_path))
Write-Host (("Google flow note:         {0}") -f (' ' + $helper.google_attached_html_validation_flow_note_path))
Write-Host (("Bundle suite note:        {0}") -f (' ' + $helper.attached_html_target_bundle_suite_surface_note_path))
Write-Host (("Attached-pages readme:    {0}") -f (' ' + $helper.attached_pages_readme_path))
Write-Host (("Sidecar audit script:     {0}") -f (' ' + $helper.attached_pages_sidecar_audit_path))
Write-Host (("Python launcher:          {0}") -f (' ' + $helper.attached_pages_launcher_path))
Write-Host (("Windows wrapper:          {0}") -f (' ' + $helper.wrapper_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
