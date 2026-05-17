[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$PageRoot,
    [string[]]$InputPath,
    [int]$Port = 8235,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Resolve-EffectiveRepoRoot {
    param(
        [string]$RepoRootOverride,
        [string]$ScriptRoot
    )

    if ($RepoRootOverride) {
        return (Resolve-Path -LiteralPath $RepoRootOverride).Path
    }

    return (Resolve-Path (Join-Path $ScriptRoot "..\.." )).Path
}

function Resolve-ExistingPaths {
    param(
        [string[]]$Paths
    )

    if (-not $Paths) {
        return @()
    }

    return @(
        $Paths | ForEach-Object {
            (Resolve-Path -LiteralPath $_).Path
        }
    )
}

function Join-QuotedValues {
    param(
        [string[]]$Values
    )

    return @(
        $Values | ForEach-Object {
            ConvertTo-PowerShellSingleQuotedLiteral -Value $_
        }
    ) -join " "
}

function Get-AttachedPagesServerCommands {
    param(
        [string]$ResolvedRepoRoot,
        [string]$ResolvedPageRoot,
        [string[]]$ResolvedInputPath,
        [int]$Port
    )

    $scriptPath = ".\tmp-browser-smoke\attached-pages\attached_pages_server.py"
    $testPath = ".\tmp-browser-smoke\attached-pages\test_attached_pages_server.py"
    $base = "python $scriptPath"

    if ($ResolvedInputPath.Count -gt 0) {
        $joinedInputs = Join-QuotedValues -Values $ResolvedInputPath
        $selection = "$base --input $joinedInputs"
        $selectionKind = "explicit input list"
    } elseif ($ResolvedPageRoot) {
        $quotedRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedPageRoot
        $selection = "$base --root $quotedRoot"
        $selectionKind = "page root"
    } else {
        $fallbackRoot = Join-Path $ResolvedRepoRoot "agent_files"
        $quotedRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $fallbackRoot
        $selection = "$base --root $quotedRoot"
        $selectionKind = "default agent_files root"
    }

    return [ordered]@{
        selection_kind = $selectionKind
        py_compile = "python -m py_compile $scriptPath $testPath"
        test = "python $testPath"
        print_manifest = "$selection --print-manifest"
        audit_assets = "$selection --audit-assets"
        allow_missing_assets_audit = "$selection --audit-assets --allow-missing-assets"
        serve = "$selection --port $Port"
    }
}

$resolvedRepoRoot = Resolve-EffectiveRepoRoot -RepoRootOverride $RepoRoot -ScriptRoot $PSScriptRoot
$resolvedPageRoot = if ($PageRoot) { (Resolve-Path -LiteralPath $PageRoot).Path } else { $null }
$resolvedInputPath = Resolve-ExistingPaths -Paths $InputPath
$commands = Get-AttachedPagesServerCommands -ResolvedRepoRoot $resolvedRepoRoot -ResolvedPageRoot $resolvedPageRoot -ResolvedInputPath $resolvedInputPath -Port $Port

$result = [ordered]@{
    repo_root = $resolvedRepoRoot
    page_root = $resolvedPageRoot
    input_count = $resolvedInputPath.Count
    resolved_input_path = $resolvedInputPath
    selection_kind = $commands.selection_kind
    note_path = "docs/ATTACHED_PAGES_SERVER_SELF_CHECK.md"
    commands = $commands
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Attached pages server self-check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
if ($resolvedPageRoot) {
    Write-Host ("Page root: {0}" -f $resolvedPageRoot)
}
if ($resolvedInputPath.Count -gt 0) {
    Write-Host ("Pinned inputs: {0}" -f $resolvedInputPath.Count)
}
Write-Host ("Selection mode: {0}" -f $commands.selection_kind)
Write-Host ""
Write-Host "Read-first commands:"
Write-Host ("  1. Syntax check:        {0}" -f $commands.py_compile)
Write-Host ("  2. Focused test suite:  {0}" -f $commands.test)
Write-Host ("  3. Print manifest:      {0}" -f $commands.print_manifest)
Write-Host ("  4. Asset audit:         {0}" -f $commands.audit_assets)
Write-Host ("  5. Allow-missing audit: {0}" -f $commands.allow_missing_assets_audit)
Write-Host ("  6. Start localhost:     {0}" -f $commands.serve)
Write-Host ""
Write-Host ("Companion note: {0}" -f $result.note_path)
