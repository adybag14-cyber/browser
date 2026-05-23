[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$AgentFilesRoot,
    [string]$BrowserExe,
    [string]$SummaryPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }
        $cursor = $parent
    }
}

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

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-RepoRoot -StartPath $PSScriptRoot
}

if (-not $AgentFilesRoot) {
    $AgentFilesRoot = Join-Path (Split-Path $resolvedRepoRoot -Parent) 'agent_files'
}
$resolvedAgentFilesRoot = [System.IO.Path]::GetFullPath($AgentFilesRoot)

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $resolvedRepoRoot 'zig-out\bin\lightpanda.exe'
}

$bundleFiles = @(
    'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html',
    'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html',
    'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
)
$preferredInitialPage = $bundleFiles[0]

$resolvedInputPaths = New-Object System.Collections.Generic.List[string]
$missingFiles = New-Object System.Collections.Generic.List[string]
foreach ($fileName in $bundleFiles) {
    $fullPath = Join-Path $resolvedAgentFilesRoot $fileName
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        $null = $resolvedInputPaths.Add((Resolve-Path -LiteralPath $fullPath).Path)
    } else {
        $null = $missingFiles.Add($fileName)
        $null = $resolvedInputPaths.Add($fullPath)
    }
}

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $bundleArguments -Name PreferredInitialPage -Value $preferredInitialPage
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values @($resolvedInputPaths.ToArray())

$bundleWithSummaryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleWithSummaryArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $bundleWithSummaryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $bundleWithSummaryArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $bundleWithSummaryArguments -Name PreferredInitialPage -Value $preferredInitialPage
Add-SharedPathArrayArgument -Arguments $bundleWithSummaryArguments -Name InputPath -Values @($resolvedInputPaths.ToArray())

$bundleCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleCheckArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $bundleCheckArguments -Name InputPath -Values @($resolvedInputPaths.ToArray())

$surfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArguments -Name RepoRoot -Value $resolvedRepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 builder-attached bundle entrypoint'
    repo_root = $resolvedRepoRoot
    agent_files_root = $resolvedAgentFilesRoot
    browser_exe = $BrowserExe
    summary_path = $SummaryPath
    preferred_initial_page = $preferredInitialPage
    bundle_files = $bundleFiles
    resolved_input_paths = @($resolvedInputPaths.ToArray())
    all_bundle_files_present = ($missingFiles.Count -eq 0)
    missing_bundle_files = @($missingFiles.ToArray())
    commands = [ordered]@{
        attached_bundle_suite = Format-HelperCommand -ScriptName 'show_headed_validation_suites.ps1' -Arguments $bundleArguments
        broader_attached_suite = Format-HelperCommand -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([System.Collections.Generic.List[string]]@('-ChangeArea', 'attached-html', '-RepoRoot', (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot), '-BrowserExe', (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe), '-PreferredInitialPage', (ConvertTo-PowerShellSingleQuotedLiteral -Value $preferredInitialPage), '-InputPath') + ($resolvedInputPaths | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }))
        google_attached_suite = Format-HelperCommand -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([System.Collections.Generic.List[string]]@('-ChangeArea', 'google-attached-html', '-RepoRoot', (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot), '-BrowserExe', (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe), '-PreferredInitialPage', (ConvertTo-PowerShellSingleQuotedLiteral -Value $preferredInitialPage), '-InputPath') + ($resolvedInputPaths | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }))
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $surfaceCheckArguments
        bundle_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckArguments
        strict_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $bundleArguments -Switches @('AuditSidecars')
        strict_asset_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $bundleArguments -Switches @('AuditAssets')
        strict_manifest = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $bundleArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleWithSummaryArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleWithSummaryArguments
    }
    notes = @(
        'Use this helper when the current run should stay pinned to the exact three HTML exports currently attached beside the workspace in agent_files.',
        'It prints the exact repeated -InputPath bundle so future runs do not have to hand-copy the saved filenames before bundle-first replay.',
        'Start with bundle_surface_check and bundle_check, then run the sidecar audit, asset audit, and strict manifest before the narrower attached-bundle replay helpers.',
        'Prefer the Google Safety Centre export as the first page so the current Google-shaped compatibility target stays first across the bundle route.',
        'If one or more bundle files are missing, treat that as an input problem first and refresh the attached files before blaming headed-mode behavior.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 builder-attached bundle entrypoint'
Write-Host ''
Write-Host ("Repo root:          {0}" -f $helper.repo_root)
Write-Host ("Agent files root:   {0}" -f $helper.agent_files_root)
Write-Host ("Browser exe:        {0}" -f $helper.browser_exe)
if ($helper.summary_path) {
    Write-Host ("Summary path:       {0}" -f $helper.summary_path)
}
Write-Host ("Preferred first:    {0}" -f $helper.preferred_initial_page)
Write-Host ("Bundle present:     {0}" -f ($(if ($helper.all_bundle_files_present) { 'yes' } else { 'no' })))
Write-Host ''
Write-Host 'Pinned bundle:'
foreach ($path in $helper.resolved_input_paths) {
    Write-Host ("  - {0}" -f $path)
}
if (-not $helper.all_bundle_files_present) {
    Write-Host ''
    Write-Host 'Missing bundle files:'
    foreach ($path in $helper.missing_bundle_files) {
        Write-Host ("  - {0}" -f $path)
    }
}
Write-Host ''
Write-Host 'Suggested route:'
Write-Host ("  Bundle suite:       {0}" -f $helper.commands.attached_bundle_suite)
Write-Host ("  Broader suite:      {0}" -f $helper.commands.broader_attached_suite)
Write-Host ("  Google suite:       {0}" -f $helper.commands.google_attached_suite)
Write-Host ("  Surface check:      {0}" -f $helper.commands.bundle_surface_check)
Write-Host ("  Bundle check:       {0}" -f $helper.commands.bundle_check)
Write-Host ("  Sidecar audit:      {0}" -f $helper.commands.strict_sidecar_audit)
Write-Host ("  Asset audit:        {0}" -f $helper.commands.strict_asset_audit)
Write-Host ("  Strict manifest:    {0}" -f $helper.commands.strict_manifest)
Write-Host ("  Bundle-first route: {0}" -f $helper.commands.bundle_first_entrypoint)
Write-Host ("  Replay quickstart:  {0}" -f $helper.commands.windows_replay_attached_html_quickstart)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host ("- {0}" -f $note)
}
