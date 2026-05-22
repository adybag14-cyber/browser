[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string]$BrowserExe,
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

    $Arguments.Add("-$Name") | Out-Null
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value)) | Out-Null
    } else {
        $Arguments.Add([string]$Value) | Out-Null
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

    $Arguments.Add("-$Name") | Out-Null
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value)) | Out-Null
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

function Format-PowerShellFileCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\$RelativePath"
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

function Resolve-BuilderAttachedBundle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRepoRoot
    )

    $bundleSpec = @(
        [pscustomobject]@{
            label = 'Google Safety Centre'
            file_name = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
            is_preferred = $true
        },
        [pscustomobject]@{
            label = 'Anthropic application'
            file_name = 'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
            is_preferred = $false
        },
        [pscustomobject]@{
            label = 'UAP encounters page'
            file_name = 'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
            is_preferred = $false
        }
    )

    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $ResolvedRepoRoot)
    $resolvedEntries = @()
    $missingEntries = @()

    foreach ($spec in $bundleSpec) {
        $resolvedPath = $null
        foreach ($root in $searchRoots) {
            $candidate = Join-Path $root $spec.file_name
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $resolvedPath = (Resolve-Path -LiteralPath $candidate).Path
                break
            }
        }

        if ($resolvedPath) {
            $resolvedEntries += [pscustomobject]@{
                label = $spec.label
                file_name = $spec.file_name
                resolved_path = $resolvedPath
                is_preferred = $spec.is_preferred
            }
        } else {
            $missingEntries += [pscustomobject]@{
                label = $spec.label
                file_name = $spec.file_name
                is_preferred = $spec.is_preferred
            }
        }
    }

    return [pscustomobject]@{
        search_roots = $searchRoots
        resolved_entries = $resolvedEntries
        missing_entries = $missingEntries
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$bundle = Resolve-BuilderAttachedBundle -ResolvedRepoRoot $resolvedRepoRoot
$resolvedInputPaths = @($bundle.resolved_entries | ForEach-Object { $_.resolved_path })
$preferredInitialPage = $null
foreach ($entry in $bundle.resolved_entries) {
    if ($entry.is_preferred) {
        $preferredInitialPage = $entry.resolved_path
        break
    }
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $sharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedArguments -Name PreferredInitialPage -Value $preferredInitialPage
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $resolvedInputPaths

$replayQuickstartArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayQuickstartArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $replayQuickstartArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $replayQuickstartArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $replayQuickstartArguments -Name PreferredInitialPage -Value $preferredInitialPage
Add-SharedPathArrayArgument -Arguments $replayQuickstartArguments -Name InputPath -Values $resolvedInputPaths

$bundleEntryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleEntryArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedArgument -Arguments $bundleEntryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $bundleEntryArguments -Name PreferredInitialPage -Value $preferredInitialPage
Add-SharedPathArrayArgument -Arguments $bundleEntryArguments -Name InputPath -Values $resolvedInputPaths

$fallbackManifestArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $fallbackManifestArguments -Name RepoRoot -Value $resolvedRepoRoot

$entrypoint = [ordered]@{
    issue = 'Google issue #3 builder-attached bundle entrypoint'
    purpose = 'Resolve the current builder-attached compatibility pages automatically and reprint the existing replay-attached quickstart, pinned bundle route, delegated bundle runner, and proof follow-up with those exact inputs already pinned.'
    repo_root = $resolvedRepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    search_roots = @($bundle.search_roots)
    resolved_bundle_count = $resolvedInputPaths.Count
    resolved_bundle = @($bundle.resolved_entries)
    missing_bundle = @($bundle.missing_entries)
    preferred_initial_page = $preferredInitialPage
    commands = [ordered]@{
        replay_attached_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $replayQuickstartArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleEntryArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $sharedArguments -Switches @('Wait')
        bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $bundleEntryArguments
        fixed_list_proof = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1' -Arguments $sharedArguments
        broader_attached_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $bundleEntryArguments
        google_attached_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleEntryArguments
        safe_route = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleEntryArguments
        manifest_fallback = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $fallbackManifestArguments -Switches @('GoogleStyle', 'PrintManifest')
        preflight_fallback = Format-HelperCommand -ScriptName 'show_attached_pages_preflight_report.ps1' -Arguments $fallbackManifestArguments -Switches @('GoogleStyle')
    }
    notes = @(
        'Use this helper when the next replay should stay pinned to the current builder-attached three-page compatibility bundle instead of rediscovering the inputs manually.',
        'The helper resolves the expected files from the repo workspace search roots that the attached-pages harness already knows about, then carries those exact paths into the replay-attached quickstart, the pinned bundle entrypoint, the delegated bundle runner, and the proof follow-up.',
        'The Google Safety Centre page stays first as the preferred initial page when it is present, so the narrower issue #3 Google-shaped follow-up route stays aligned with the pinned builder-attached bundle.',
        'If one or more expected builder-attached files are missing, treat that as a bundle-discovery problem first and use the manifest and preflight fallbacks before you read the failure as a browser regression.',
        'Widen back out with the broader attached-page flow, the Google-shaped attached-page flow, replay shortcuts, or the safe-route map only after the pinned bundle route makes the next failure state clear.'
    )
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 builder-attached bundle entrypoint'
Write-Host ''
Write-Host (("Repo root: {0}") -f $entrypoint.repo_root)
if ($entrypoint.summary_path) {
    Write-Host (("Summary path: {0}") -f $entrypoint.summary_path)
}
if ($entrypoint.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $entrypoint.browser_exe)
}
Write-Host ''
Write-Host 'Search roots:'
foreach ($root in $entrypoint.search_roots) {
    Write-Host (("  - {0}") -f $root)
}
Write-Host ''
Write-Host 'Resolved bundle:'
foreach ($item in $entrypoint.resolved_bundle) {
    Write-Host (("  - {0}: {1}") -f $item.label, $item.resolved_path)
}
if ($entrypoint.missing_bundle.Count -gt 0) {
    Write-Host ''
    Write-Host 'Missing expected bundle files:'
    foreach ($item in $entrypoint.missing_bundle) {
        Write-Host (("  - {0}: {1}") -f $item.label, $item.file_name)
    }
}
Write-Host ''
if ($entrypoint.preferred_initial_page) {
    Write-Host (("Preferred initial page: {0}") -f $entrypoint.preferred_initial_page)
    Write-Host ''
}
if ($entrypoint.missing_bundle.Count -eq 0) {
    Write-Host 'Pinned builder-attached route:'
    Write-Host (("  Replay quickstart: {0}") -f $entrypoint.commands.replay_attached_quickstart)
    Write-Host (("  Bundle entrypoint: {0}") -f $entrypoint.commands.bundle_first_entrypoint)
    Write-Host (("  Bundle runner: {0}") -f $entrypoint.commands.bundle_runner)
    Write-Host (("  Proof entrypoint: {0}") -f $entrypoint.commands.bundle_proof_entrypoint)
    Write-Host (("  Fixed-list proof: {0}") -f $entrypoint.commands.fixed_list_proof)
    Write-Host ''
    Write-Host 'Widen back out when needed:'
    Write-Host (("  Broader attached flow: {0}") -f $entrypoint.commands.broader_attached_flow)
    Write-Host (("  Google attached flow: {0}") -f $entrypoint.commands.google_attached_flow)
    Write-Host (("  Replay shortcuts: {0}") -f $entrypoint.commands.replay_shortcuts)
    Write-Host (("  Safe route: {0}") -f $entrypoint.commands.safe_route)
} else {
    Write-Host 'Fallback bundle discovery commands:'
    Write-Host (("  Manifest: {0}") -f $entrypoint.commands.manifest_fallback)
    Write-Host (("  Preflight: {0}") -f $entrypoint.commands.preflight_fallback)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}