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

$bundleSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedArguments -Name InputPath -Values $InputPath

$surface = [ordered]@{
    issue = 'Google issue #3 attached-html context surface'
    purpose = 'Keep the attached-html change-area router, the Google-shaped attached-page helper chain, and the pinned three-page bundle route on one context-preserving command surface before replay narrows further.'
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
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $reentryArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $reentryArguments
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedArguments
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $reentryArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    }
    note_paths = [ordered]@{
        suite_catalog_entrypoints = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    }
    notes = @(
        'Use this helper when attached localhost replay already matters, but you still want the broader attached-page lane, the Google-shaped attached-page lane, and the pinned bundle lane printed with the same repo-root and input-path context.',
        'Start with suite_catalog_entrypoints when the route is still reopening from the broader validation catalog.',
        'Start with top_level_attached_html_entrypoint when the route is already narrowed to the issue #3 attached-page branch and you only need the shorter bridge reprinted first.',
        'Run google_attached_html_surface_check before trusting the narrower Google-shaped attached-page chain after a branch move.',
        'Run bundle_surface_check before delegating into the pinned three-page bundle flow or runner.',
        'Use bundle_first_entrypoint when explicit bundle inputs are already pinned and the replay should stay locked to that same three-page set.'
    )
}

$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_entrypoint'
} elseif (-not [string]::IsNullOrWhiteSpace($surface.summary_path) -or -not [string]::IsNullOrWhiteSpace($surface.repo_root)) {
    'suite_catalog_entrypoints'
} else {
    'google_attached_html_surface_check'
}
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
$surface.recommended_next_reason = switch ($surface.recommended_next_key) {
    'bundle_first_entrypoint' { 'Explicit attached-page inputs are already pinned, so keep the replay on that same bundle-aware branch before the broader flow widens again.' }
    'suite_catalog_entrypoints' { 'A non-default repo root or saved summary is already in play, so reopen the broader issue #3 catalog with that same context preserved.' }
    default { 'No saved replay context is pinned yet, so fail fast on the Google-shaped attached-page helper surface before choosing the broader or bundle-first branch.' }
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 attached-html context surface'
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
Write-Host 'Suite-router entrypoints:'
Write-Host (('  Attached HTML:        {0}') -f $surface.suite_commands.attached_html)
Write-Host (('  Google attached HTML: {0}') -f $surface.suite_commands.google_attached_html)
Write-Host (('  Bundle route:         {0}') -f $surface.suite_commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (('  Suite catalog:        {0}') -f $surface.helper_commands.suite_catalog_entrypoints)
Write-Host (('  Top-level bridge:     {0}') -f $surface.helper_commands.top_level_attached_html_entrypoint)
Write-Host (('  Broader flow:         {0}') -f $surface.helper_commands.broader_attached_html_flow)
Write-Host (('  Google surface check: {0}') -f $surface.helper_commands.google_attached_html_surface_check)
Write-Host (('  Google flow:          {0}') -f $surface.helper_commands.google_attached_html_flow)
Write-Host (('  Bundle surface check: {0}') -f $surface.helper_commands.bundle_surface_check)
Write-Host (('  Bundle flow:          {0}') -f $surface.helper_commands.bundle_flow)
Write-Host (('  Bundle-first helper:  {0}') -f $surface.helper_commands.bundle_first_entrypoint)
Write-Host (('  Bundle runner:        {0}') -f $surface.helper_commands.bundle_runner)
