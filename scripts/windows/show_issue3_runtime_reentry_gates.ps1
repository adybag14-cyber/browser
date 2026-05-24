[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$ToolchainsRoot,
    [string]$MemoryChecker,
    [string]$RestoredCheckoutRoot,
    [string]$Zig = "zig",
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Format-RepoRootCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @()
    )

    $escapedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot
    $command = "& '.\\$ScriptPath'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $command += " -$($entry.Key)"
        if ($value -is [string]) {
            $command += " " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $value)
        } else {
            $command += " $value"
        }
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }
        $command += " -$switchName"
    }

    return "powershell -NoProfile -ExecutionPolicy Bypass -Command ``"`$env:LIGHTPANDA_REPO_ROOT = $escapedRepoRoot; $command``""
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$resolvedToolchainsRoot = if ($ToolchainsRoot) {
    (Resolve-Path -LiteralPath $ToolchainsRoot).Path
} else {
    Join-Path (Split-Path -Parent $resolvedRepoRoot) "toolchains"
}

$resolvedMemoryChecker = if ($MemoryChecker) {
    (Resolve-Path -LiteralPath $MemoryChecker).Path
} else {
    Join-Path $resolvedRepoRoot "scripts/check_issue3_saved_memory_inputs.py"
}

$resolvedRestoredCheckoutRoot = if ($RestoredCheckoutRoot) {
    $RestoredCheckoutRoot
} else {
    Join-Path (Split-Path -Parent $resolvedRepoRoot) "browser-memory-snapshot"
}

$route = [ordered]@{
    issue = "Google issue #3 runtime re-entry gate route"
    purpose = "Keep the publication gate, the toolchain gate, and the recovery routes on one Windows-first helper surface before the direct Page.zig and win32_backend.zig runtime patch is reopened."
    repo_root = $resolvedRepoRoot
    toolchains_root = $resolvedToolchainsRoot
    saved_memory_checker = $resolvedMemoryChecker
    restored_checkout_root = $resolvedRestoredCheckoutRoot
    zig = $Zig
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    )
    commands = [ordered]@{
        surface_check = "bash " + (ConvertTo-PowerShellSingleQuotedLiteral -Value (Join-Path $resolvedRepoRoot "scripts/linux/check_issue3_runtime_reentry_gates_surface.sh")) + " --repo-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
        gate_check = "python " + (ConvertTo-PowerShellSingleQuotedLiteral -Value (Join-Path $resolvedRepoRoot "scripts/check_issue3_runtime_reentry_gates.py")) + " --repo-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot) + " --toolchains-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedToolchainsRoot) + " --memory-checker " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedMemoryChecker) + " --restored-checkout-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRestoredCheckoutRoot) + " --zig " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $Zig)
        restore_route = "bash " + (ConvertTo-PowerShellSingleQuotedLiteral -Value (Join-Path $resolvedRepoRoot "scripts/linux/show_issue3_saved_browser_snapshot_route.sh")) + " --repo-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
        zig_recovery_route = "bash " + (ConvertTo-PowerShellSingleQuotedLiteral -Value (Join-Path $resolvedRepoRoot "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")) + " --repo-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
        build_route = "bash " + (ConvertTo-PowerShellSingleQuotedLiteral -Value (Join-Path $resolvedRepoRoot "scripts/linux/show_issue3_linux_build_readiness_route.sh")) + " --repo-root " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
        runtime_route = Format-RepoRootCommand -ScriptPath "scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1"
    }
    notes = @(
        "Run the gate-route surface checker first so missing helper files fail fast.",
        "Run the gate check next so publication and toolchain status comes from the branch-local checker instead of guesswork.",
        "If the publication gate stays closed, reopen the saved-browser-snapshot route before retrying the direct runtime patch.",
        "If the toolchain gate stays closed, reopen the Zig recovery route before trusting focused runtime validation.",
        "If restore and toolchain recovery are no longer the blocker, use the Linux build-readiness route before the final Windows runtime handoff.",
        "Use the Windows runtime revalidation helper only after the gate check passes."
    )
}

if ($Json) {
    $route | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google issue #3 runtime re-entry gate route"
Write-Host ""
Write-Host ("Repo root:              {0}" -f $route.repo_root)
Write-Host ("Toolchains root:        {0}" -f $route.toolchains_root)
Write-Host ("Saved-memory checker:   {0}" -f $route.saved_memory_checker)
Write-Host ("Restored checkout root: {0}" -f $route.restored_checkout_root)
Write-Host ("Zig command:            {0}" -f $route.zig)
Write-Host ""
Write-Host "Read first"
Write-Host "=========="
foreach ($path in $route.read_first) {
    Write-Host ("  {0}" -f $path)
}
Write-Host ""
Write-Host "Suggested route"
Write-Host "==============="
Write-Host ("  Route surface:`n    {0}" -f $route.commands.surface_check)
Write-Host ""
Write-Host ("  Gate check:`n    {0}" -f $route.commands.gate_check)
Write-Host ""
Write-Host ("  Saved-browser restore route when the publication gate is still closed:`n    {0}" -f $route.commands.restore_route)
Write-Host ""
Write-Host ("  Zig recovery route when the toolchain gate is still closed:`n    {0}" -f $route.commands.zig_recovery_route)
Write-Host ""
Write-Host ("  Linux build-readiness route when restore or Zig recovery already happened:`n    {0}" -f $route.commands.build_route)
Write-Host ""
Write-Host ("  Windows runtime revalidation route after the gates pass:`n    {0}" -f $route.commands.runtime_route)
Write-Host ""
Write-Host "Working rules"
Write-Host "============="
foreach ($note in $route.notes) {
    Write-Host ("  - {0}" -f $note)
}
