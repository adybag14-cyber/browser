[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$OutputPath,
    [string]$LogPath,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Resolve-PowerShellHost {
    if (Get-Command powershell -ErrorAction SilentlyContinue) {
        return "powershell"
    }
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return "pwsh"
    }
    throw "PowerShell executable not found in PATH."
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$artifactRoot = Join-Path $resolvedRepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (-not $OutputPath) {
    $OutputPath = Join-Path $artifactRoot "google-issue3-recommended-validation-surface.json"
}
if (-not $LogPath) {
    $LogPath = Join-Path $artifactRoot "google-issue3-recommended-validation-surface.log"
}

$checker = Join-Path $PSScriptRoot "check_google_issue3_recommended_validation_surface.ps1"
if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
    throw "Google issue #3 recommended validation surface checker not found: $checker"
}

if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Force
}
if (Test-Path -LiteralPath $LogPath) {
    Remove-Item -LiteralPath $LogPath -Force
}

$hostExe = Resolve-PowerShellHost
$hostArgs = @(
    "-NoProfile"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    $checker
    "-RepoRoot"
    $resolvedRepoRoot
    "-Json"
)

$outputLines = & $hostExe @hostArgs 2>&1
$exitCode = $LASTEXITCODE
$outputText = ($outputLines | ForEach-Object {
    if ($_ -is [string]) {
        return $_
    }
    return ($_ | Out-String).TrimEnd()
}) -join [Environment]::NewLine
$outputText | Set-Content -Path $LogPath -Encoding Ascii

if ([string]::IsNullOrWhiteSpace($outputText)) {
    throw "Google issue #3 recommended validation surface checker returned no JSON output. Log: $LogPath"
}

try {
    $surfaceCheck = $outputText | ConvertFrom-Json -Depth 8
} catch {
    throw "Google issue #3 recommended validation surface checker returned non-JSON output. Log: $LogPath"
}

$missingReferences = @($surfaceCheck.references | Where-Object { -not $_.Exists })
$artifact = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    profile = "google-issue3-recommended"
    repo_root = $resolvedRepoRoot
    checker = (Convert-ToDisplayPath -Path $checker -RepoRoot $resolvedRepoRoot)
    output_path = $OutputPath
    output_display_path = (Convert-ToDisplayPath -Path $OutputPath -RepoRoot $resolvedRepoRoot)
    log_path = $LogPath
    log_display_path = (Convert-ToDisplayPath -Path $LogPath -RepoRoot $resolvedRepoRoot)
    status = if ($exitCode -eq 0) { "passed" } else { "failed" }
    exit_code = $exitCode
    checked_count = $surfaceCheck.checked_count
    missing_count = $surfaceCheck.missing_count
    missing_paths = @($missingReferences | ForEach-Object { $_.Path })
    surface_check = $surfaceCheck
}

$artifactJson = $artifact | ConvertTo-Json -Depth 10
$artifactJson | Set-Content -Path $OutputPath -Encoding Ascii

Write-Host "Google issue #3 recommended validation surface artifact"
Write-Host ""
Write-Host ("Status: {0}" -f $artifact.status)
Write-Host ("Checked references: {0}" -f $artifact.checked_count)
Write-Host ("Missing references: {0}" -f $artifact.missing_count)
Write-Host ("Artifact JSON: {0}" -f $artifact.output_display_path)
Write-Host ("Checker log: {0}" -f $artifact.log_display_path)
if ($missingReferences.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing paths:"
    foreach ($missing in $missingReferences) {
        Write-Host ("- {0}" -f $missing.Path)
    }
}

if ($PassThru) {
    $artifactJson
}

if ($exitCode -ne 0) {
    throw ("Google issue #3 recommended validation surface is incomplete. Artifact JSON: {0}" -f $OutputPath)
}
