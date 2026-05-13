[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$TitlePort = 8159,
    [string]$InputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments = $null
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }

    return $command
}

function Format-SuiteRouterCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [string]$ArgumentName,
        [Parameter(Mandatory = $true)]
        [string]$ArgumentValue,
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return ".\\scripts\\windows\\$ScriptName -$ArgumentName $ArgumentValue"
    }

    $escapedRepoRoot = $RepoRootOverride -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; & '.\\scripts\\windows\\$ScriptName' -$ArgumentName $ArgumentValue`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$wrapperArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $wrapperArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $wrapperArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $wrapperArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $wrapperArguments -Name TitlePort -Value $TitlePort
Add-SharedArgument -Arguments $wrapperArguments -Name InputText -Value $InputText
Add-SharedArgument -Arguments $wrapperArguments -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $wrapperArguments -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $wrapperArguments -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $wrapperArguments -Name HomePollMilliseconds -Value $HomePollMilliseconds

$directProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $directProbeArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $directProbeArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $directProbeArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $directProbeArguments -Name Port -Value $TitlePort
Add-SharedArgument -Arguments $directProbeArguments -Name InputText -Value $InputText
Add-SharedArgument -Arguments $directProbeArguments -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $directProbeArguments -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $directProbeArguments -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $directProbeArguments -Name PollMilliseconds -Value $HomePollMilliseconds

$googleHomeCommand = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home'

$handoff = [ordered]@{
    issue = 'Google issue #3 title suite router handoff'
    purpose = 'Keep the suite-router title entry, the narrower title surface checker, the marker guide, the wrapper-first flow, and the raw probe on one compact command surface.'
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    suite_router_commands = [ordered]@{
        google_title = Format-SuiteRouterCommand -ScriptName 'show_headed_validation_suites.ps1' -ArgumentName 'SuiteName' -ArgumentValue 'google-title' -RepoRootOverride $RepoRoot
        google_input = Format-SuiteRouterCommand -ScriptName 'show_headed_validation_suites.ps1' -ArgumentName 'ChangeArea' -ArgumentValue 'google-input' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        title_surface_check = Format-HelperCommand -ScriptName 'check_google_title_validation_surface.ps1'
        title_marker_guide = Format-HelperCommand -ScriptName 'show_google_title_probe_trace_guide.ps1'
        title_flow = Format-HelperCommand -ScriptName 'show_google_title_validation_flow.ps1' -Arguments $wrapperArguments
        title_wrapper = Format-HelperCommand -ScriptName 'run_google_title_validation.ps1' -Arguments $wrapperArguments
        title_direct_probe = Format-HelperCommand -ScriptName 'run_google_home_title_probe.ps1' -Arguments $directProbeArguments
        google_quick = Format-HelperCommand -ScriptName 'run_google_quick_validation.ps1'
        google_home = $googleHomeCommand
    }
    notes = @(
        'Start with the google-title suite-router entry when you want the shared suite catalog to reintroduce the bounded title gate before a replay.',
        'Use the google-input change area when you need the broader issue #3 ladder printed before deciding whether to stay on the title slice or widen later.',
        'Run the title surface checker first so missing fixtures, guides, or helper wiring fail fast before a narrower replay looks trustworthy.',
        'Keep the marker guide beside the wrapper so the bounded title markers stay mapped to focus, text-commit, and Enter-submit stages.',
        'Prefer the wrapper over the raw probe unless you already need the direct probe output files from tmp-browser-smoke/google-investigation-next.',
        'Use google_quick after the title wrapper is green when you want the fast title-plus-watch follow-up.',
        'Use google_home after the title wrapper is green when the next replay should widen into the reduced homepage stage without reopening the full issue #3 chain.'
    )
}

$handoff.bridge_sequence = [ordered]@{
    google_title = $handoff.suite_router_commands.google_title
    google_input = $handoff.suite_router_commands.google_input
    title_surface_check = $handoff.helper_commands.title_surface_check
    title_marker_guide = $handoff.helper_commands.title_marker_guide
    title_flow = $handoff.helper_commands.title_flow
    title_wrapper = $handoff.helper_commands.title_wrapper
}

$handoff.recommended_next_command = $handoff.helper_commands.title_flow
$handoff.recommended_next_reason = 'The suite-router title entry is easiest to follow when it lands immediately on the read-first title flow before the wrapper or raw probe is chosen.'

if ($Json) {
    $handoff | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 title suite router handoff'
Write-Host ''
if ($handoff.repo_root) {
    Write-Host ("Repo root:   {0}" -f $handoff.repo_root)
}
if ($handoff.browser_exe) {
    Write-Host ("Browser exe: {0}" -f $handoff.browser_exe)
}
Write-Host ''
Write-Host ("Recommended next command: {0}" -f $handoff.recommended_next_command)
Write-Host ("Why:                    {0}" -f $handoff.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first bridge:'
Write-Host ("  1. Google title suite: {0}" -f $handoff.bridge_sequence.google_title)
Write-Host ("  2. Google input area:  {0}" -f $handoff.bridge_sequence.google_input)
Write-Host ("  3. Surface check:      {0}" -f $handoff.bridge_sequence.title_surface_check)
Write-Host ("  4. Marker guide:       {0}" -f $handoff.bridge_sequence.title_marker_guide)
Write-Host ("  5. Title flow:         {0}" -f $handoff.bridge_sequence.title_flow)
Write-Host ("  6. Title wrapper:      {0}" -f $handoff.bridge_sequence.title_wrapper)
Write-Host ''
Write-Host 'Suite-router entrypoints:'
Write-Host ("  Google title: {0}" -f $handoff.suite_router_commands.google_title)
Write-Host ("  Google input: {0}" -f $handoff.suite_router_commands.google_input)
Write-Host ''
Write-Host 'Title helpers:'
Write-Host ("  Surface check: {0}" -f $handoff.helper_commands.title_surface_check)
Write-Host ("  Marker guide:  {0}" -f $handoff.helper_commands.title_marker_guide)
Write-Host ("  Title flow:    {0}" -f $handoff.helper_commands.title_flow)
Write-Host ("  Title wrapper: {0}" -f $handoff.helper_commands.title_wrapper)
Write-Host ("  Raw probe:     {0}" -f $handoff.helper_commands.title_direct_probe)
Write-Host ''
Write-Host 'Follow-up commands:'
Write-Host ("  Google quick:  {0}" -f $handoff.helper_commands.google_quick)
Write-Host ("  Google home:   {0}" -f $handoff.helper_commands.google_home)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $handoff.notes) {
    Write-Host ("- {0}" -f $note)
}
