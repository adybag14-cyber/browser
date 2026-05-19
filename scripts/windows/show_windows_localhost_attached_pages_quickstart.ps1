[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8235,
    [ValidateSet("page1", "links", "next")]
    [string]$PreferredInitialPage = "page1",
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

function Resolve-HelperRepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return (Resolve-Path -LiteralPath $RepoRoot).Path
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return (Resolve-Path -LiteralPath $env:LIGHTPANDA_REPO_ROOT).Path
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT or pass -RepoRoot."
        }
        $cursor = $parent
    }
}

function Resolve-HelperBrowserExe([string]$ResolvedRepoRoot) {
    if (-not [string]::IsNullOrWhiteSpace($BrowserExe)) {
        return $BrowserExe
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) {
        return $env:LIGHTPANDA_BROWSER_EXE
    }
    return (Join-Path $ResolvedRepoRoot "zig-out\bin\lightpanda.exe")
}

function Format-AttachedCatalogCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRepoRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$InputPaths,
        [string[]]$Switches = @()
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("powershell")
    $parts.Add("-ExecutionPolicy")
    $parts.Add("Bypass")
    $parts.Add("-File")
    $parts.Add(".\scripts\windows\start_attached_pages_catalog.ps1")
    $parts.Add("-RepoRoot")
    $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedRepoRoot))
    $parts.Add("-InputPath")
    foreach ($path in $InputPaths) {
        $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $path))
    }
    foreach ($switchName in $Switches) {
        if (-not [string]::IsNullOrWhiteSpace($switchName)) {
            $parts.Add("-$switchName")
        }
    }

    return ($parts -join " ")
}

function Format-LaunchCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$ResolvedBrowserExe,
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("powershell")
    $parts.Add("-NoProfile")
    $parts.Add("-ExecutionPolicy")
    $parts.Add("Bypass")
    $parts.Add("-Command")

    $repoLiteral = ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedRepoRoot
    $browserLiteral = ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedBrowserExe
    $urlLiteral = ConvertTo-PowerShellSingleQuotedLiteral -Value $Url
    $commandBody = "& $browserLiteral browse --browser_mode headed --window_width 1366 --window_height 768 $urlLiteral"
    $parts.Add("`"`$env:LIGHTPANDA_REPO_ROOT = $repoLiteral; $commandBody`"")

    return ($parts -join " ")
}

$resolvedRepoRoot = Resolve-HelperRepoRoot $PSScriptRoot
$resolvedBrowserExe = Resolve-HelperBrowserExe $resolvedRepoRoot
$inputPaths = @(
    (Join-Path $resolvedRepoRoot "tmp-browser-smoke\page1.html")
    (Join-Path $resolvedRepoRoot "tmp-browser-smoke\next.html")
    (Join-Path $resolvedRepoRoot "tmp-browser-smoke\links.html")
)

$missingInputs = @($inputPaths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })

$bundleUrls = [ordered]@{
    page1 = "http://$Host`:$Port/page1.html"
    links = "http://$Host`:$Port/links.html"
    next = "http://$Host`:$Port/next.html"
}

$helper = [ordered]@{
    route = 'Windows localhost attached pages quickstart'
    purpose = 'Print the shortest Windows-first path for the repo-bundled localhost smoke pages so headed validation can start from page1.html, links.html, and next.html before widening into the heavier attached-export or issue-specific helper ladders.'
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    host = $Host
    port = $Port
    preferred_initial_page = $PreferredInitialPage
    input_paths = $inputPaths
    missing_inputs = $missingInputs
    commands = [ordered]@{
        manifest = Format-AttachedCatalogCommand -ResolvedRepoRoot $resolvedRepoRoot -InputPaths $inputPaths -Switches @('PrintManifest')
        audit_sidecars = Format-AttachedCatalogCommand -ResolvedRepoRoot $resolvedRepoRoot -InputPaths $inputPaths -Switches @('AuditSidecars')
        audit_assets = Format-AttachedCatalogCommand -ResolvedRepoRoot $resolvedRepoRoot -InputPaths $inputPaths -Switches @('AuditAssets')
        require_complete_manifest = Format-AttachedCatalogCommand -ResolvedRepoRoot $resolvedRepoRoot -InputPaths $inputPaths -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')
        localhost_catalog = Format-AttachedCatalogCommand -ResolvedRepoRoot $resolvedRepoRoot -InputPaths $inputPaths -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')
        launch_page1 = Format-LaunchCommand -ResolvedRepoRoot $resolvedRepoRoot -ResolvedBrowserExe $resolvedBrowserExe -Url $bundleUrls.page1
        launch_links = Format-LaunchCommand -ResolvedRepoRoot $resolvedRepoRoot -ResolvedBrowserExe $resolvedBrowserExe -Url $bundleUrls.links
        launch_next = Format-LaunchCommand -ResolvedRepoRoot $resolvedRepoRoot -ResolvedBrowserExe $resolvedBrowserExe -Url $bundleUrls.next
    }
    note_path = 'docs/WINDOWS_LOCALHOST_ATTACHED_PAGES_QUICKSTART.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Run the manifest command first when you want the exact localhost routes printed for the bundled three-page set without starting the server.',
        'Run the sidecar audit before blaming headed mode so missing sibling _files bundles fail fast when these inputs later widen into saved-export testing.',
        'Run the asset audit next when the replay should prove the local HTML set is materially complete before the browser is blamed.',
        'Use the require-complete manifest or localhost catalog launch when the run should stop on incomplete sidecars or missing assets instead of silently widening into partial replay.',
        'Launch page1 first when you want the simplest click-through route from the bundled set, launch links when you want the bordered-box and nested-link rendering route first, and launch next when you only need the trivial second-page checkpoint.'
    )
}

$helper.recommended_next_key = if ($missingInputs.Count -gt 0) {
    'manifest'
} else {
    "launch_$PreferredInitialPage"
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($missingInputs.Count -gt 0) {
    'One or more bundled smoke pages are missing from the checkout, so print the manifest route first and fix the local file set before attempting headed localhost replay.'
} else {
    "The bundled smoke pages are present, so start with the $PreferredInitialPage launch command after the manifest and audits when you want the shortest headed localhost checkpoint."
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Windows localhost attached pages quickstart'
Write-Host ''
Write-Host ("Repo root:   {0}" -f $helper.repo_root)
Write-Host ("Browser exe: {0}" -f $helper.browser_exe)
Write-Host ("Host/port:   {0}:{1}" -f $helper.host, $helper.port)
Write-Host ("Preferred page: {0}" -f $helper.preferred_initial_page)
Write-Host ''
Write-Host ("Recommended next helper: {0}" -f $helper.recommended_next_command)
Write-Host ("Why:                    {0}" -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Bundled inputs:'
foreach ($path in $helper.input_paths) {
    Write-Host ("- {0}" -f $path)
}
if ($helper.missing_inputs.Count -gt 0) {
    Write-Host ''
    Write-Host 'Missing bundled inputs:'
    foreach ($path in $helper.missing_inputs) {
        Write-Host ("- {0}" -f $path)
    }
}
Write-Host ''
Write-Host 'Commands:'
Write-Host ("  Manifest:              {0}" -f $helper.commands.manifest)
Write-Host ("  Sidecar audit:         {0}" -f $helper.commands.audit_sidecars)
Write-Host ("  Asset audit:           {0}" -f $helper.commands.audit_assets)
Write-Host ("  Strict manifest:       {0}" -f $helper.commands.require_complete_manifest)
Write-Host ("  Localhost catalog:     {0}" -f $helper.commands.localhost_catalog)
Write-Host ("  Launch page1:          {0}" -f $helper.commands.launch_page1)
Write-Host ("  Launch links:          {0}" -f $helper.commands.launch_links)
Write-Host ("  Launch next:           {0}" -f $helper.commands.launch_next)
Write-Host ''
Write-Host ("Runbook note:            {0}" -f $helper.windows_runbook_note_path)
Write-Host ("Companion quickstart:    {0}" -f $helper.note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host ("- {0}" -f $note)
}
