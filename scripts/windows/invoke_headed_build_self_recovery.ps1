[CmdletBinding()]
param(
    [string]$RepoRoot = $env:LIGHTPANDA_REPO_ROOT,
    [string[]]$BuildArgs = @("-Dtarget=x86_64-windows-msvc", "--summary", "all"),
    [string]$DefaultStdoutPath,
    [string]$DefaultStderrPath,
    [string]$RecoveryStdoutPath,
    [string]$RecoveryStderrPath,
    [string]$RecoveryCacheDir,
    [string]$RecoveryGlobalCacheDir,
    [switch]$SkipBuild,
    [switch]$SkipFreshCacheRetry,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [string]$Candidate
    )

    $resolved = $Candidate
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    }

    $resolvedItem = Get-Item -LiteralPath $resolved -ErrorAction Stop
    if (-not $resolvedItem.PSIsContainer) {
        throw "RepoRoot must point to the Lightpanda repository directory."
    }

    return $resolvedItem.FullName
}

function Get-InterestingProcesses {
    $names = @("zig", "cargo", "ninja", "build", "cl", "link", "lld-link")

    return @(Get-Process -Name $names -ErrorAction SilentlyContinue |
        Sort-Object ProcessName, Id |
        ForEach-Object {
            $startTime = $null
            $path = $null
            try {
                $startTime = $_.StartTime.ToUniversalTime().ToString("o")
            } catch {
                $startTime = $null
            }
            try {
                $path = $_.Path
            } catch {
                $path = $null
            }

            [pscustomobject]@{
                name = $_.ProcessName
                pid = $_.Id
                start_time_utc = $startTime
                path = $path
            }
        })
}

function Test-ZigAvailable {
    try {
        $version = (& zig version).Trim()
        if ([string]::IsNullOrWhiteSpace($version)) {
            return [pscustomobject]@{
                available = $false
                version = $null
                error = "zig version returned no output"
            }
        }

        return [pscustomobject]@{
            available = $true
            version = $version
            error = $null
        }
    } catch {
        return [pscustomobject]@{
            available = $false
            version = $null
            error = $_.Exception.Message
        }
    }
}

function Invoke-ZigBuildHelp {
    try {
        & zig build --help *> $null
        return [pscustomobject]@{
            exit_code = $LASTEXITCODE
            ok = ($LASTEXITCODE -eq 0)
            error = $null
        }
    } catch {
        return [pscustomobject]@{
            exit_code = -1
            ok = $false
            error = $_.Exception.Message
        }
    }
}

function Get-FileText {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ""
    }

    return Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
}

function Get-BuildClassification {
    param(
        [int]$ExitCode,
        [string]$StdoutText,
        [string]$StderrText
    )

    if ($ExitCode -eq 0) {
        return "success"
    }

    $combined = ($StdoutText + [Environment]::NewLine + $StderrText)
    if ($combined -match 'build\.exe: FileNotFound') {
        return "cache-corruption"
    }
    if ($combined -match 'GetLastError\(5\): Access is denied') {
        return "environment-access-denied"
    }
    if ($combined -match '(?im)^error: ' -or $combined -match '(?im)\berror\b:') {
        return "direct-diagnostics"
    }

    return "unknown-failure"
}

function Get-ClassificationSummary {
    param(
        [string]$Classification
    )

    switch ($Classification) {
        "success" { return "Build succeeded." }
        "cache-corruption" { return "Likely default-cache corruption around Zig's build runner or local cache state." }
        "environment-access-denied" { return "Likely Windows environment restriction while Zig tries to spawn child processes." }
        "direct-diagnostics" { return "Compiler, parser, linker, or build-script diagnostics were captured directly in the logs." }
        default { return "Build failed without matching a known recovery signature." }
    }
}

function Get-RecommendedNextSteps {
    param(
        [string]$Classification,
        [bool]$RecoverySucceeded,
        [string]$RepoRoot,
        [string]$RecoveryCacheDir,
        [string]$RecoveryGlobalCacheDir
    )

    switch ($Classification) {
        "success" {
            return @(
                "Proceed with the next headed validation or implementation slice."
            )
        }
        "cache-corruption" {
            if ($RecoverySucceeded) {
                return @(
                    "The fresh-cache retry succeeded, so recover the normal cache path with powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\manage_build_artifacts.ps1 -CleanBuildCaches.",
                    "Re-run the default build after cleanup to confirm the normal cache path is healthy again."
                )
            }

            return @(
                "Inspect the default-cache logs first, then retry with fresh caches if you have not already.",
                "If the fresh-cache retry succeeds later, clean the default caches with manage_build_artifacts.ps1 -CleanBuildCaches before returning to the normal build path."
            )
        }
        "environment-access-denied" {
            return @(
                "Treat this as an environment restriction first, not a source-code failure.",
                "Keep the captured logs, validate zig build --help in a fresh shell, and retry from a shell with fewer policy restrictions if possible."
            )
        }
        "direct-diagnostics" {
            return @(
                "Read the captured stderr file first and fix the direct compiler or linker diagnostics before trying broader cache cleanup.",
                "Only return to cache-recovery steps if the logs later show build.exe or access-denied signatures instead of source diagnostics."
            )
        }
        default {
            return @(
                "Inspect the captured stdout and stderr logs directly.",
                "Use the fresh-cache retry to separate cache state from a real source failure if the first failure does not explain itself."
            )
        }
    }
}

function Invoke-LoggedBuild {
    param(
        [string]$StdoutPath,
        [string]$StderrPath,
        [bool]$UseRecoveryCaches,
        [string]$RecoveryCacheDir,
        [string]$RecoveryGlobalCacheDir,
        [string[]]$BuildArgs
    )

    $stdoutParent = Split-Path -Path $StdoutPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($stdoutParent)) {
        New-Item -ItemType Directory -Force -Path $stdoutParent | Out-Null
    }
    $stderrParent = Split-Path -Path $StderrPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($stderrParent)) {
        New-Item -ItemType Directory -Force -Path $stderrParent | Out-Null
    }

    if (Test-Path -LiteralPath $StdoutPath) {
        Remove-Item -LiteralPath $StdoutPath -Force
    }
    if (Test-Path -LiteralPath $StderrPath) {
        Remove-Item -LiteralPath $StderrPath -Force
    }

    $arguments = @("build")
    if ($UseRecoveryCaches) {
        $arguments += @("--cache-dir", $RecoveryCacheDir, "--global-cache-dir", $RecoveryGlobalCacheDir)
    }
    $arguments += $BuildArgs

    try {
        & zig @arguments 1> $StdoutPath 2> $StderrPath
        $exitCode = $LASTEXITCODE
    } catch {
        $message = $_.Exception.Message
        Set-Content -LiteralPath $StderrPath -Value $message -Encoding Ascii
        $exitCode = -1
    }

    $stdoutText = Get-FileText -Path $StdoutPath
    $stderrText = Get-FileText -Path $StderrPath
    $classification = Get-BuildClassification -ExitCode $exitCode -StdoutText $stdoutText -StderrText $stderrText

    return [pscustomobject]@{
        exit_code = $exitCode
        ok = ($exitCode -eq 0)
        classification = $classification
        summary = Get-ClassificationSummary -Classification $classification
        stdout_path = $StdoutPath
        stderr_path = $StderrPath
        used_recovery_caches = $UseRecoveryCaches
        recovery_cache_dir = if ($UseRecoveryCaches) { $RecoveryCacheDir } else { $null }
        recovery_global_cache_dir = if ($UseRecoveryCaches) { $RecoveryGlobalCacheDir } else { $null }
    }
}

$RepoRoot = Resolve-RepoRoot -Candidate $RepoRoot

if (-not $DefaultStdoutPath) {
    $DefaultStdoutPath = Join-Path $RepoRoot "tmp-current-build.stdout.txt"
}
if (-not $DefaultStderrPath) {
    $DefaultStderrPath = Join-Path $RepoRoot "tmp-current-build.stderr.txt"
}
if (-not $RecoveryStdoutPath) {
    $RecoveryStdoutPath = Join-Path $RepoRoot "tmp-recover-build.stdout.txt"
}
if (-not $RecoveryStderrPath) {
    $RecoveryStderrPath = Join-Path $RepoRoot "tmp-recover-build.stderr.txt"
}
if (-not $RecoveryCacheDir) {
    $RecoveryCacheDir = Join-Path $RepoRoot ".zig-cache-recover"
}
if (-not $RecoveryGlobalCacheDir) {
    $RecoveryGlobalCacheDir = Join-Path $RepoRoot ".zig-global-cache-recover"
}

$processSnapshot = Get-InterestingProcesses
$zigStatus = Test-ZigAvailable
$zigHelp = if ($zigStatus.available) { Invoke-ZigBuildHelp } else {
    [pscustomobject]@{
        exit_code = -1
        ok = $false
        error = $zigStatus.error
    }
}

$defaultBuild = $null
$recoveryBuild = $null
if (-not $SkipBuild -and $zigStatus.available -and $zigHelp.ok) {
    $defaultBuild = Invoke-LoggedBuild -StdoutPath $DefaultStdoutPath -StderrPath $DefaultStderrPath -UseRecoveryCaches $false -RecoveryCacheDir $RecoveryCacheDir -RecoveryGlobalCacheDir $RecoveryGlobalCacheDir -BuildArgs $BuildArgs

    $shouldRetryFreshCache = (-not $SkipFreshCacheRetry) -and (-not $defaultBuild.ok) -and ($defaultBuild.classification -ne "direct-diagnostics")
    if ($shouldRetryFreshCache) {
        $recoveryBuild = Invoke-LoggedBuild -StdoutPath $RecoveryStdoutPath -StderrPath $RecoveryStderrPath -UseRecoveryCaches $true -RecoveryCacheDir $RecoveryCacheDir -RecoveryGlobalCacheDir $RecoveryGlobalCacheDir -BuildArgs $BuildArgs
    }
}

$nextSteps = @()
if (-not $zigStatus.available) {
    $nextSteps = @(
        "Install Zig or open a shell where zig is on PATH before starting the Windows build recovery routine."
    )
} elseif (-not $zigHelp.ok) {
    $nextSteps = @(
        "Fix the Zig toolchain invocation first because zig build --help did not succeed in the current shell.",
        "Do not treat the later build as a source failure until zig build --help works cleanly."
    )
} elseif ($SkipBuild) {
    $nextSteps = @(
        "Use the process snapshot plus zig build --help result as a preflight check, then rerun without -SkipBuild when you want fresh logs."
    )
} elseif ($defaultBuild) {
    $nextSteps = Get-RecommendedNextSteps -Classification $defaultBuild.classification -RecoverySucceeded ([bool]($recoveryBuild -and $recoveryBuild.ok)) -RepoRoot $RepoRoot -RecoveryCacheDir $RecoveryCacheDir -RecoveryGlobalCacheDir $RecoveryGlobalCacheDir
}

$summary = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root = $RepoRoot
    build_args = @($BuildArgs)
    zig = $zigStatus
    zig_build_help = $zigHelp
    process_snapshot = @($processSnapshot)
    default_build = $defaultBuild
    recovery_build = $recoveryBuild
    next_steps = @($nextSteps)
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed build self-recovery"
Write-Host ("Repo root: {0}" -f $RepoRoot)
if ($zigStatus.available) {
    Write-Host ("Zig: {0}" -f $zigStatus.version)
} else {
    Write-Host ("Zig: unavailable ({0})" -f $zigStatus.error)
}
Write-Host ("zig build --help: {0}" -f $(if ($zigHelp.ok) { "PASS" } else { "FAIL" }))
Write-Host ""

if ($processSnapshot.Count -gt 0) {
    Write-Host "Candidate build-related processes:"
    foreach ($processRecord in $processSnapshot) {
        $startTime = if ($processRecord.start_time_utc) { $processRecord.start_time_utc } else { "unknown" }
        $path = if ($processRecord.path) { $processRecord.path } else { "path unavailable" }
        Write-Host ("- {0} pid={1} started={2} path={3}" -f $processRecord.name, $processRecord.pid, $startTime, $path)
    }
} else {
    Write-Host "Candidate build-related processes: none found"
}
Write-Host ""

if ($SkipBuild) {
    Write-Host "Build execution was skipped."
} elseif ($defaultBuild) {
    Write-Host ("Default build: {0}" -f $(if ($defaultBuild.ok) { "PASS" } else { "FAIL" }))
    Write-Host ("  Classification: {0}" -f $defaultBuild.classification)
    Write-Host ("  Summary: {0}" -f $defaultBuild.summary)
    Write-Host ("  Stdout: {0}" -f $defaultBuild.stdout_path)
    Write-Host ("  Stderr: {0}" -f $defaultBuild.stderr_path)
    if ($recoveryBuild) {
        Write-Host ("Fresh-cache retry: {0}" -f $(if ($recoveryBuild.ok) { "PASS" } else { "FAIL" }))
        Write-Host ("  Classification: {0}" -f $recoveryBuild.classification)
        Write-Host ("  Summary: {0}" -f $recoveryBuild.summary)
        Write-Host ("  Cache dir: {0}" -f $recoveryBuild.recovery_cache_dir)
        Write-Host ("  Global cache dir: {0}" -f $recoveryBuild.recovery_global_cache_dir)
        Write-Host ("  Stdout: {0}" -f $recoveryBuild.stdout_path)
        Write-Host ("  Stderr: {0}" -f $recoveryBuild.stderr_path)
    }
} else {
    Write-Host "Build execution did not run because Zig preflight failed."
}
Write-Host ""
Write-Host "Recommended next steps:"
foreach ($step in $nextSteps) {
    Write-Host ("- {0}" -f $step)
}

if ($defaultBuild -and -not $defaultBuild.ok) {
    exit 1
}
if ($zigHelp -and -not $zigHelp.ok) {
    exit 1
}
if (-not $zigStatus.available) {
    exit 1
}

exit 0