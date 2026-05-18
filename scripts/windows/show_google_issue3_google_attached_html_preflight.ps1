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
            $value = $entry.Value
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
            }
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

function Format-SidecarAuditCommand {
    param(
        [string]$RepoRootOverride,
        [string[]]$InputPathOverride
    )

    $scriptPath = if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        '.\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py'
    } else {
        Join-Path $RepoRootOverride 'tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py'
    }

    $command = "python " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $scriptPath)
    $command += ' --google-style --audit-sidecars'
    if (-not [string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $command += ' --repo-root ' + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRootOverride)
    }
    if ($InputPathOverride -and $InputPathOverride.Count -gt 0) {
        foreach ($value in $InputPathOverride) {
            $command += ' --input ' + (ConvertTo-PowerShellSingleQuotedLiteral -Value $value)
        }
    }

    return $command
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$attachedHtmlArguments = [ordered]@{}
if ($InputPath -and @($InputPath).Count -gt 0) {
    $attachedHtmlArguments['InputPath'] = @($InputPath)
}

$helper = [ordered]@{
    issue = 'Google issue #3 Google attached-html preflight'
    purpose = 'Print the sidecar-first Google attached-html preflight route so missing sibling _files bundles, broader attached-page drift, and deeper local asset gaps can be ruled out before the issue-specific entrypoint narrows replay further.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    helper_commands = [ordered]@{
        top_level_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        sidecar_audit = Format-SidecarAuditCommand -RepoRootOverride $RepoRoot -InputPathOverride $InputPath
        broader_google_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_asset_audit = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $attachedHtmlArguments -Switches @('GoogleStyle') -RepoRootOverride $RepoRoot
        google_attached_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlArguments -RepoRootOverride $RepoRoot
        issue_specific_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
        issue_specific_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    note_paths = [ordered]@{
        replay_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
        google_attached_entrypoint = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        google_attached_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        suite_router_bridge = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    }
    notes = @(
        'Use this helper when the replay is already narrowed to the Google-shaped attached localhost branch and you want a stable read-first route before the issue-specific entrypoint takes over.',
        'Run sidecar_audit first when the current saved export may simply be missing its whole sibling `_files` bundle and you want that lighter failure mode ruled in or out before the deeper asset crawl.',
        'Run broader_google_surface_check next when you want the wider Google attached-html surface to fail fast before the route narrows into the issue-specific checker.',
        'Run google_asset_audit after the broader surface check when missing nested assets might explain the current Google-shaped attached-page failure.',
        'Use google_attached_flow when you still want the broader localhost-first helper chain visible before you narrow into the issue-specific entrypoint.',
        'Use issue_specific_surface_check immediately before issue_specific_entrypoint when helper or note edits may have moved the compact issue-specific route.',
        'Use shortcut_entrypoint after the issue-specific entrypoint when no stronger replay context needs to stay visible first.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Google attached-html preflight'
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
Write-Host ''
Write-Host 'Read-first preflight:'
Write-Host (("  1. Top-level route:        {0}") -f $helper.helper_commands.top_level_google_attached_html)
Write-Host (("  2. Sidecar audit:          {0}") -f $helper.helper_commands.sidecar_audit)
Write-Host (("  3. Broader surface check: {0}") -f $helper.helper_commands.broader_google_surface_check)
Write-Host (("  4. Asset audit:           {0}") -f $helper.helper_commands.google_asset_audit)
Write-Host (("  5. Google attached flow:  {0}") -f $helper.helper_commands.google_attached_flow)
Write-Host (("  6. Issue-specific check:  {0}") -f $helper.helper_commands.issue_specific_surface_check)
Write-Host (("  7. Issue entrypoint:      {0}") -f $helper.helper_commands.issue_specific_entrypoint)
Write-Host (("  8. Shortcut bridge:       {0}") -f $helper.helper_commands.shortcut_entrypoint)
Write-Host ''
Write-Host 'Companion notes:'
Write-Host (("  Replay quickstart: {0}") -f $helper.note_paths.replay_quickstart)
Write-Host (("  Issue entrypoint:  {0}") -f $helper.note_paths.google_attached_entrypoint)
Write-Host (("  Google flow note:  {0}") -f $helper.note_paths.google_attached_flow)
Write-Host (("  Shortcut bridge:   {0}") -f $helper.note_paths.suite_router_bridge)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
