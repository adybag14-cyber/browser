[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Url = 'https://www.google.com/',
    [string]$SearchText = 'lightpanda',
    [int]$WindowWidth = 1366,
    [int]$WindowHeight = 768,
    [int]$InputX = 683,
    [int]$InputY = 352,
    [int]$PostLaunchSleepMs = 1200,
    [int]$PostTypeSleepMs = 600,
    [int]$PostEnterSleepMs = 1800,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$probePath = Join-Path $resolvedRepoRoot 'tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1'
if (-not (Test-Path -LiteralPath $probePath -PathType Leaf)) {
    throw "Google input trace probe not found at $probePath"
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $resolvedRepoRoot 'zig-out/bin/lightpanda.exe'
}

$traceRoot = Split-Path $probePath -Parent
$displayProbePath = Convert-ToDisplayPath -Path $probePath -RepoRoot $resolvedRepoRoot
$displayTraceRoot = Convert-ToDisplayPath -Path $traceRoot -RepoRoot $resolvedRepoRoot

function Quote-PowerShellLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

$commandParts = @(
    'powershell',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    ".\$($displayProbePath -replace '/', '\')",
    '-BrowserExe',
    (Quote-PowerShellLiteral -Value $BrowserExe),
    '-Url',
    (Quote-PowerShellLiteral -Value $Url),
    '-SearchText',
    (Quote-PowerShellLiteral -Value $SearchText),
    '-WindowWidth',
    [string]$WindowWidth,
    '-WindowHeight',
    [string]$WindowHeight,
    '-InputX',
    [string]$InputX,
    '-InputY',
    [string]$InputY,
    '-PostLaunchSleepMs',
    [string]$PostLaunchSleepMs,
    '-PostTypeSleepMs',
    [string]$PostTypeSleepMs,
    '-PostEnterSleepMs',
    [string]$PostEnterSleepMs
)

$helper = [ordered]@{
    issue = 'Google issue #3 input trace probe'
    purpose = 'Print the smallest live-Google headed trace route already tracked on the branch so the current probe command, output files, and likely interpretation path stay discoverable.'
    repo_root = $resolvedRepoRoot
    browser_exe = $BrowserExe
    trace_root = $traceRoot
    commands = [ordered]@{
        surface_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_input_trace_probe_surface.ps1'
        run_probe = ($commandParts -join ' ')
    }
    artifacts = @(
        "$displayTraceRoot/google-input-trace.before.png",
        "$displayTraceRoot/google-input-trace.browser.stdout.txt",
        "$displayTraceRoot/google-input-trace.browser.stderr.txt",
        "$displayTraceRoot/browse-render.log",
        "$displayTraceRoot/session-wait.log",
        "$displayTraceRoot/runtime-renderer.log",
        "$displayTraceRoot/runtime-input-backend-*.log",
        "$displayTraceRoot/wndproc-input-*.log"
    )
    signals = @(
        'Use title_before, title_after_type, and title_after_enter from the probe JSON to see whether the failure stayed in focus, text commit, or Enter submit.',
        'Compare runtime-input-backend and wndproc-input tails when later text appears to be suppressed or reordered.',
        'If the probe still points at the Enter/text-input boundary, reopen docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md before touching Page.zig or win32_backend.zig.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Issue #3 Google input trace probe'
Write-Host ''
Write-Host 'Run this first when the live headed Google surface still needs the smallest branch-tracked text/Enter trace route.'
Write-Host ''
Write-Host ('  Surface check: {0}' -f $helper.commands.surface_check)
Write-Host ('  Run probe:     {0}' -f $helper.commands.run_probe)
Write-Host ''
Write-Host 'Artifacts written under the trace root:'
foreach ($artifact in $helper.artifacts) {
    Write-Host ('  - {0}' -f $artifact)
}
Write-Host ''
Write-Host 'What to look for next:'
foreach ($signal in $helper.signals) {
    Write-Host ('  - {0}' -f $signal)
}
