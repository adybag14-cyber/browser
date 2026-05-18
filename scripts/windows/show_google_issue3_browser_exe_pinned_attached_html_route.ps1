[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
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

    $fallbackArguments = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
        } else {
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
        }
    }

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    if ($fallbackArguments.Count -gt 0) {
        $command += " " + ($fallbackArguments -join ' ')
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

$browserPinnedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $browserPinnedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $browserPinnedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $browserPinnedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $browserPinnedArguments -Name InputPath -Values $InputPath

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $googleAttachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $googleAttachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$validationSuiteArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
if ($BrowserExe) {
    $validationSuiteArguments['BrowserExe'] = $BrowserExe
}
if ($InputPath) {
    $validationSuiteArguments['InputPath'] = @($InputPath)
}

$route = [ordered]@{
    issue = 'Google issue #3 browser-exe pinned attached HTML route'
    purpose = 'Print the current safe issue #3 attached-page route that keeps a non-default headed browser binary pinned through the broader Google attached-page flow, the top-level issue #3 attached-page quickstart, and the pinned bundle-first helper.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    commands = [ordered]@{
        validation_router_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $validationSuiteArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $browserPinnedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserPinnedArguments
    }
    note_paths = [ordered]@{
        windows_runbook = 'docs/WINDOWS_FULL_USE.md'
        google_attached_html_validation_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        top_level_attached_html_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
        attached_bundle_first = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        pinned_route = 'docs/ISSUE3_BROWSER_EXE_PINNED_ATTACHED_HTML_ROUTE.md'
    }
    notes = @(
        'Use this helper when issue #3 replay should stay pinned to a non-default headed browser build instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.',
        'Start with validation_router_google_attached_html when you still want the broader validation-router view before narrowing into the Google-shaped attached-page helper surface.',
        'Use google_attached_html_flow when the current inputs are already Google-shaped and you want the current attached-page flow helper plus its asset-closure checks printed with the same BrowserExe value.',
        'Use top_level_attached_html_quickstart when replay is ready to drop into the issue-specific attached-page helper chain while keeping BrowserExe pinned.',
        'Use attached_bundle_first when the current saved or attached pages are the known three-page compatibility bundle and the next replay should stay on that narrower path with the same BrowserExe value.'
    )
}

$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif ([string]::IsNullOrWhiteSpace($route.browser_exe)) {
    'google_attached_html_flow'
} else {
    'top_level_attached_html_quickstart'
}
$route.recommended_next_command = $route.commands[$route.recommended_next_key]
$route.recommended_next_reason = if ($route.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep the replay on the known three-page compatibility bundle with the same BrowserExe value.'
} elseif ($route.recommended_next_key -eq 'google_attached_html_flow') {
    'No BrowserExe override is currently pinned, so start from the broader Google attached-page flow and add BrowserExe there before narrowing further.'
} else {
    'A BrowserExe override is already in play and no bundle inputs are pinned yet, so jump straight into the top-level issue #3 attached-page quickstart while preserving that same binary path.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 browser-exe pinned attached HTML route'
Write-Host ''
if ($route.repo_root) {
    Write-Host (("Repo root:   {0}") -f $route.repo_root)
}
if ($route.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($route.summary_path)"))
}
if ($route.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $route.browser_exe)
}
if ($route.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $route.recommended_next_command)
Write-Host (("Why:                    {0}") -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Pinned route:'
Write-Host (("  1. Validation router: {0}") -f $route.commands.validation_router_google_attached_html)
Write-Host (("  2. Google flow:       {0}") -f $route.commands.google_attached_html_flow)
Write-Host (("  3. Top-level issue #3:{0}") -f (' ' + $route.commands.top_level_attached_html_quickstart))
Write-Host (("  4. Bundle-first path: {0}") -f $route.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Pinned route note:      {0}") -f (' ' + $route.note_paths.pinned_route))
Write-Host (("Windows runbook:        {0}") -f (' ' + $route.note_paths.windows_runbook))
Write-Host (("Google flow note:       {0}") -f (' ' + $route.note_paths.google_attached_html_validation_flow))
Write-Host (("Top-level quickstart:   {0}") -f (' ' + $route.note_paths.top_level_attached_html_quickstart))
Write-Host (("Bundle quickstart note: {0}") -f (' ' + $route.note_paths.attached_bundle_first))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}
