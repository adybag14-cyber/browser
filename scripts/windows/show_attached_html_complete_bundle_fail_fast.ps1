[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [switch]$GoogleStyle,
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

function Resolve-RepoRootFromScript {
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

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRootFromScript -StartPath $PSScriptRoot
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot 'zig-out\bin\lightpanda.exe'
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
        $command += ' ' + ($Arguments -join ' ')
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }
        $command += " -$switchName"
    }

    return $command
}

function Get-AttachedCatalogCommand {
    param(
        [string[]]$TargetInputPath,
        [switch]$GoogleStyle,
        [string[]]$ExtraSwitches = @()
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    if ($GoogleStyle) {
        $arguments.Add('-GoogleStyle')
    }
    Add-SharedArgument -Arguments $arguments -Name RepoRoot -Value $RepoRoot
    Add-SharedPathArrayArgument -Arguments $arguments -Name InputPath -Values $TargetInputPath

    return Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $arguments -Switches $ExtraSwitches
}

$surface = [ordered]@{
    profile = 'attached-html-complete-bundle-fail-fast'
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    commands = [ordered]@{
        audit_sidecars = Get-AttachedCatalogCommand -TargetInputPath $InputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditSidecars')
        audit_assets = Get-AttachedCatalogCommand -TargetInputPath $InputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditAssets')
        manifest = Get-AttachedCatalogCommand -TargetInputPath $InputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('PrintManifest')
        strict_manifest = Get-AttachedCatalogCommand -TargetInputPath $InputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets', 'PrintManifest')
        strict_catalog = Get-AttachedCatalogCommand -TargetInputPath $InputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets')
        browse_catalog = "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    }
    notes = @(
        'Run the sidecar audit first so missing sibling _files directories fail before the browser is blamed.',
        'Run the asset audit second so missing local CSS, JS, font, or image files stay visible before headed replay is blamed.',
        'Use the strict manifest command after both audits pass when you want the manifest to stop on either missing sidecars or missing assets.',
        'Use the strict catalog command after both audits pass when you want the localhost catalog launch itself to fail fast on incomplete bundles.',
        'Pass -GoogleStyle when the pinned replay should keep the strongest Google-like saved page first during attached-page auto-discovery.',
        'Pass one or more -InputPath values when you want this helper to stay pinned to a specific saved page or known compatibility bundle.'
    )
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Attached HTML complete-bundle fail-fast surface'
Write-Host ''
Write-Host (("Repo root:   {0}") -f $surface.repo_root)
Write-Host (("Browser exe: {0}") -f $surface.browser_exe)
if ($surface.input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $surface.input_path_count)
}
Write-Host ''
Write-Host 'Commands:'
Write-Host (("  Sidecars audit: {0}") -f $surface.commands.audit_sidecars)
Write-Host (("  Assets audit:   {0}") -f $surface.commands.audit_assets)
Write-Host (("  Manifest:       {0}") -f $surface.commands.manifest)
Write-Host (("  Strict manifest:{0}") -f (" $($surface.commands.strict_manifest)"))
Write-Host (("  Strict catalog: {0}") -f $surface.commands.strict_catalog)
Write-Host (("  Browse catalog: {0}") -f $surface.commands.browse_catalog)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $surface.notes) {
    Write-Host (("- {0}") -f $note)
}
