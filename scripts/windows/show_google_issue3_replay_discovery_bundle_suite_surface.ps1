[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
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
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }
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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
            }
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\scripts\windows\$ScriptName'"
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
        $command += " -$($entry.Key) '$escapedValue'"
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

$reentryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reentryArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reentryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $reentryArguments -Name InputPath -Values $InputPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$attachedFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedFlowArguments['InputPath'] = @($InputPath)
}

$surface = [ordered]@{
    issue = 'Google issue #3 replay discovery bundle-suite surface'
    purpose = 'Keep the broader attached-page validation router, the compact attached bundle suite helper, and the pinned three-page bundle replay handoff on one smaller replay-discovery surface before the route narrows again.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    suite_commands = [ordered]@{
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $reentryArguments
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $bundleArguments
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $reentryArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $reentryArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $reentryArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    }
    note_paths = [ordered]@{
        replay_discovery = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
        bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        replay_route_shortcut = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    }
    notes = @(
        'Use this helper when replay discovery already points toward the attached localhost bundle lane, but you still want the broader attached-page and Google-shaped attached-page routes visible beside the compact bundle helper.',
        'Start with bundle_suite_surface when the current replay is already near the known three-page compatibility bundle and you want the smaller issue #3 surface before the broader replay-route helpers reopen.',
        'Keep broader_attached_html_flow and google_attached_html_flow nearby when a pinned-bundle assumption might still need to widen back into the broader attached-page routes.',
        'Run google_attached_html_surface_check before trusting the narrower Google-shaped attached-page route after a branch move.',
        'Run bundle_surface_check before delegating to bundle_first_entrypoint or bundle_runner after helper or note churn.'
    )
}

$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_entrypoint'
} else {
    'bundle_suite_surface'
}
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
$surface.recommended_next_reason = if ($surface.recommended_next_key -eq 'bundle_first_entrypoint') {
    'Explicit attached-page inputs are already pinned, so keep that same bundle context on the narrower issue #3 bundle-first bridge before widening again.'
} else {
    'No explicit bundle paths are pinned yet, so reopen the compact bundle suite surface first while the broader attached-page helper chain stays visible beside it.'
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 replay discovery bundle-suite surface'
Write-Host ''
if ($surface.repo_root) {
    Write-Host (('Repo root:   {0}') -f $surface.repo_root)
}
if ($surface.summary_path) {
    Write-Host (('Summary path:{0}') -f (" $($surface.summary_path)"))
}
if ($surface.explicit_input_path_count -gt 0) {
    Write-Host (('Input paths: {0}') -f $surface.explicit_input_path_count)
}
Write-Host ''
Write-Host (('Recommended next helper: {0}') -f $surface.recommended_next_command)
Write-Host (('Why:                    {0}') -f $surface.recommended_next_reason)
Write-Host ''
Write-Host 'Validation router re-entry:'
Write-Host (('  Attached HTML:        {0}') -f $surface.suite_commands.attached_html)
Write-Host (('  Google attached HTML: {0}') -f $surface.suite_commands.google_attached_html)
Write-Host (('  Bundle route:         {0}') -f $surface.suite_commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Compact bundle lane:'
Write-Host (('  Bundle suite helper:  {0}') -f $surface.helper_commands.bundle_suite_surface)
Write-Host (('  Broader flow:         {0}') -f $surface.helper_commands.broader_attached_html_flow)
Write-Host (('  Google surface check: {0}') -f $surface.helper_commands.google_attached_html_surface_check)
Write-Host (('  Google flow:          {0}') -f $surface.helper_commands.google_attached_html_flow)
Write-Host (('  Bundle surface check: {0}') -f $surface.helper_commands.bundle_surface_check)
Write-Host (('  Bundle flow:          {0}') -f $surface.helper_commands.bundle_flow)
Write-Host (('  Bundle-first helper:  {0}') -f $surface.helper_commands.bundle_first_entrypoint)
Write-Host (('  Bundle runner:        {0}') -f $surface.helper_commands.bundle_runner)
Write-Host ''
Write-Host 'Replay follow-up:'
Write-Host (('  Replay route:         {0}') -f $surface.helper_commands.replay_route)
Write-Host (('  Replay shortcut:      {0}') -f $surface.helper_commands.replay_route_shortcut)
