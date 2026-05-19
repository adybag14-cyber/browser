[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SearchRoot,
    [string]$SummaryPath,
    [string]$BrowserExe,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bundleFileNames = @(
    'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html',
    'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html',
    'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
)

$preferredGoogleLikeFile = $bundleFileNames[0]

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Resolve-RepoRoot {
    param(
        [string]$ExplicitRepoRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepoRoot)) {
        return [System.IO.Path]::GetFullPath($ExplicitRepoRoot)
    }

    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return [System.IO.Path]::GetFullPath($env:LIGHTPANDA_REPO_ROOT)
    }

    $cursor = [System.IO.Path]::GetFullPath($PSScriptRoot)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw 'Could not resolve the Lightpanda repo root. Pass -RepoRoot to override.'
        }
        $cursor = $parent
    }
}

function Resolve-BundleRootCandidates {
    param(
        [string]$ResolvedRepoRoot,
        [string]$ExplicitSearchRoot
    )

    $roots = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $addRoot = {
        param([string]$PathValue)
        if ([string]::IsNullOrWhiteSpace($PathValue)) {
            return
        }

        $fullPath = [System.IO.Path]::GetFullPath($PathValue)
        if ($seen.Add($fullPath)) {
            $roots.Add($fullPath)
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ExplicitSearchRoot)) {
        & $addRoot $ExplicitSearchRoot
    }

    $cwd = (Get-Location).Path
    $repoParent = Split-Path $ResolvedRepoRoot -Parent

    & $addRoot $cwd
    & $addRoot (Join-Path $cwd 'agent_files')
    & $addRoot $ResolvedRepoRoot
    & $addRoot (Join-Path $ResolvedRepoRoot 'agent_files')

    if (-not [string]::IsNullOrWhiteSpace($repoParent)) {
        & $addRoot $repoParent
        & $addRoot (Join-Path $repoParent 'agent_files')
    }

    return $roots
}

function Resolve-AttachedBundle {
    param(
        [string[]]$CandidateRoots
    )

    foreach ($candidateRoot in $CandidateRoots) {
        if (-not (Test-Path $candidateRoot)) {
            continue
        }

        $resolvedFiles = [System.Collections.Generic.List[string]]::new()
        $missing = $false
        foreach ($bundleFileName in $bundleFileNames) {
            $candidateFile = Join-Path $candidateRoot $bundleFileName
            if (-not (Test-Path $candidateFile)) {
                $missing = $true
                break
            }

            $resolvedFiles.Add([System.IO.Path]::GetFullPath($candidateFile))
        }

        if (-not $missing) {
            return [pscustomobject]@{
                Root = [System.IO.Path]::GetFullPath($candidateRoot)
                Files = $resolvedFiles
            }
        }
    }

    return $null
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [string[]]$Arguments = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    if ($Arguments.Count -gt 0) {
        $command += ' ' + ($Arguments -join ' ')
    }

    return $command
}

function Add-OptionalArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
}

$RepoRoot = Resolve-RepoRoot -ExplicitRepoRoot $RepoRoot
$candidateRoots = Resolve-BundleRootCandidates -ResolvedRepoRoot $RepoRoot -ExplicitSearchRoot $SearchRoot
$resolvedBundle = Resolve-AttachedBundle -CandidateRoots $candidateRoots

if ($null -eq $resolvedBundle) {
    $searched = $candidateRoots | ForEach-Object { "- $_" }
    throw "Could not find the current issue #3 attached compatibility bundle. Checked:`n$($searched -join [Environment]::NewLine)"
}

$preferredFilePath = $resolvedBundle.Files | Where-Object { [System.IO.Path]::GetFileName($_) -eq $preferredGoogleLikeFile } | Select-Object -First 1

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-OptionalArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-OptionalArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-OptionalArgument -Arguments $sharedArguments -Name BrowserExe -Value $BrowserExe
$sharedArguments.Add('-InputPath')
$sharedArguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedBundle.Root))
$runnerArguments = @($sharedArguments) + @('-Wait')

$surface = [ordered]@{
    issue = 'Google issue #3 current attached compatibility bundle'
    purpose = 'Auto-resolve the pinned three-page compatibility bundle from the current workspace and print the exact attached-html-target-bundle commands that keep the localhost replay pinned to those saved pages.'
    repo_root = $RepoRoot
    search_roots_checked = @($candidateRoots)
    bundle_root = $resolvedBundle.Root
    preferred_google_like_page = $preferredFilePath
    bundle_files = @($resolvedBundle.Files)
    commands = [ordered]@{
        attached_html_target_bundle = Format-HelperCommand -ScriptName 'show_headed_validation_suites.ps1' -Arguments @('-ChangeArea', 'attached-html-target-bundle', '-InputPath', (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedBundle.Root))
        bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        bundle_validation_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $sharedArguments
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $sharedArguments
        bundle_validation_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $runnerArguments
    }
    notes = @(
        'Use this helper when the current replay should stay pinned to the known three-page compatibility bundle instead of relying on manual path re-entry.',
        'The bundle root printed here can be reused anywhere the existing issue #3 attached-html helpers accept -InputPath.',
        'Keep the preferred_google_like_page visible when the replay should start from the Google Safety Centre export while staying on the same pinned bundle.'
    )
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 6
    return
}

Write-Host ''
Write-Host 'Issue #3 Current Attached Compatibility Bundle'
Write-Host '============================================'
Write-Host ("Repo root: {0}" -f $surface.repo_root)
Write-Host ("Bundle root: {0}" -f $surface.bundle_root)
Write-Host ("Preferred Google-like page: {0}" -f $surface.preferred_google_like_page)
Write-Host ''
Write-Host 'Bundle files'
Write-Host '------------'
foreach ($bundleFile in $surface.bundle_files) {
    Write-Host ("- {0}" -f $bundleFile)
}

Write-Host ''
Write-Host 'Commands'
Write-Host '--------'
foreach ($entry in $surface.commands.GetEnumerator()) {
    Write-Host ("[{0}]" -f $entry.Key)
    Write-Host ("  {0}" -f $entry.Value)
}

Write-Host ''
Write-Host 'Notes'
Write-Host '-----'
foreach ($note in $surface.notes) {
    Write-Host ("- {0}" -f $note)
}
