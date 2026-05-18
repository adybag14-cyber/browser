[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$RepoRoot,
    [switch]$AllowMissingSidecars,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Resolve-DisplayRepoRoot {
    param(
        [string]$RepoRootOverride
    )

    if (-not [string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return $RepoRootOverride
    }

    return "<repo-root>"
}

function Get-WrapperCommand {
    param(
        [string]$RepoRootOverride,
        [string[]]$ResolvedInputPath,
        [bool]$AllowMissingSidecars
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -AuditSidecars"
    if (-not [string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $command += " -RepoRoot " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRootOverride)
    }
    if ($AllowMissingSidecars) {
        $command += " -AllowMissingSidecars"
    }
    if ($ResolvedInputPath -and $ResolvedInputPath.Count -gt 0) {
        $quotedInputs = @(
            $ResolvedInputPath | ForEach-Object {
                ConvertTo-PowerShellSingleQuotedLiteral -Value $_
            }
        )
        $command += " -InputPath " + ($quotedInputs -join " ")
    }

    return $command
}

function Get-PageRootFallbackCommand {
    param(
        [string]$RepoRootOverride,
        [string]$ResolvedPageRoot,
        [bool]$AllowMissingSidecars
    )

    $repoRootForPath = Resolve-DisplayRepoRoot -RepoRootOverride $RepoRootOverride
    $scriptPath = Join-Path $repoRootForPath "tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py"
    $command = "python " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $scriptPath)
    if ($AllowMissingSidecars) {
        $command += " --allow-missing-sidecars"
    }
    if (-not [string]::IsNullOrWhiteSpace($ResolvedPageRoot)) {
        $command += " --root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $ResolvedPageRoot)
    }

    return $command
}

$resolvedPageRoot = if ($PageRoot) { $PageRoot } else { $null }
$resolvedInputPath = if ($InputPath) { @($InputPath) } else { @() }

$wrapperCommand = Get-WrapperCommand -RepoRootOverride $RepoRoot -ResolvedInputPath $resolvedInputPath -AllowMissingSidecars ([bool]$AllowMissingSidecars)
$pageRootFallbackCommand = Get-PageRootFallbackCommand -RepoRootOverride $RepoRoot -ResolvedPageRoot $resolvedPageRoot -AllowMissingSidecars ([bool]$AllowMissingSidecars)
$recommendedMode = if ($PSCmdlet.ParameterSetName -eq "PageRoot") { "page-root-fallback" } else { "wrapper-backed-attached-pages" }
$recommendedCommand = if ($PSCmdlet.ParameterSetName -eq "PageRoot") { $pageRootFallbackCommand } else { $wrapperCommand }

$result = [ordered]@{
    issue = "Google issue #3 attached HTML sidecar audit"
    recommended_mode = $recommendedMode
    recommended_command = $recommendedCommand
    wrapper_command = $wrapperCommand
    page_root_fallback_command = $pageRootFallbackCommand
    repo_root = $RepoRoot
    explicit_input_count = $resolvedInputPath.Count
    page_root = $resolvedPageRoot
    allow_missing_sidecars = [bool]$AllowMissingSidecars
    companion_note = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_SIDECAR_AUDIT.md"
    notes = @(
        "Use the wrapper-backed command for auto-discovered or explicit attached HTML inputs so the sidecar audit stays aligned with the current attached-pages launcher surface.",
        "Use the page-root fallback only when the replay is already organized around a single page root, because start_attached_pages_catalog.ps1 does not currently accept -PageRoot.",
        "Pass -RepoRoot when the replay is running from a non-default checkout and the sidecar audit should stay pinned to that branch root.",
        "Pass -AllowMissingSidecars only when the missing _files bundles are already understood and the replay should continue in degraded mode."
    )
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Google issue #3 attached HTML sidecar audit"
Write-Host ""
Write-Host ("Recommended mode: {0}" -f $result.recommended_mode)
Write-Host ("Recommended command: {0}" -f $result.recommended_command)
Write-Host ""
Write-Host ("Wrapper-backed attached-pages audit: {0}" -f $result.wrapper_command)
Write-Host ("Page-root fallback audit:           {0}" -f $result.page_root_fallback_command)
Write-Host ("Companion note:                     {0}" -f $result.companion_note)
Write-Host ""
Write-Host "Notes:"
foreach ($note in $result.notes) {
    Write-Host ("- {0}" -f $note)
}
