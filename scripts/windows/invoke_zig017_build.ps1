param(
    [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path,
    [string]$ZigExe = "C:\Users\adyba\Downloads\zig-x86_64-windows-0.17.0-dev.305+bdfbf432d\zig.exe",
    [string]$CacheDir = ".zig-cache-zig017",
    [string]$GlobalCacheDir = (Join-Path $env:LOCALAPPDATA "zig-lightpanda-017"),
    [string]$PrebuiltV8Path = "",
    [ValidateSet("Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall")]
    [string]$Optimize = "Debug",
    [bool]$Strip = $true,
    [switch]$NoLog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$ZigExe = (Resolve-Path -LiteralPath $ZigExe).Path

if (-not $PrebuiltV8Path) {
    $PrebuiltV8Path = Join-Path $RepoRoot ".lp-cache-win\v8-14.0.365.4\out\windows\release\obj\zig\c_v8.lib"
}
$PrebuiltV8Path = (Resolve-Path -LiteralPath $PrebuiltV8Path).Path

$CacheDirFull = if ([System.IO.Path]::IsPathRooted($CacheDir)) {
    [System.IO.Path]::GetFullPath($CacheDir)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $CacheDir))
}
$GlobalCacheDirFull = [System.IO.Path]::GetFullPath($GlobalCacheDir)

New-Item -ItemType Directory -Force -Path $CacheDirFull | Out-Null
New-Item -ItemType Directory -Force -Path $GlobalCacheDirFull | Out-Null

$version = (& $ZigExe version).Trim()
Write-Host ("Zig: {0}" -f $version)
Write-Host ("Local cache: {0}" -f $CacheDirFull)
Write-Host ("Global cache: {0}" -f $GlobalCacheDirFull)
Write-Host ("Prebuilt V8: {0}" -f $PrebuiltV8Path)
Write-Host ("Optimize: {0}; strip debug info: {1}" -f $Optimize, $Strip)

$stripValue = if ($Strip) { "true" } else { "false" }

$args = @(
    "build",
    "-Dtarget=x86_64-windows-msvc",
    "-Doptimize=$Optimize",
    "-Dstrip=$stripValue",
    "-Dprebuilt_v8_path=$PrebuiltV8Path",
    "--cache-dir",
    $CacheDirFull,
    "--global-cache-dir",
    $GlobalCacheDirFull,
    "--summary",
    "all"
)

Push-Location $RepoRoot
try {
    if ($NoLog) {
        & $ZigExe @args
    } else {
        $stdout = Join-Path $RepoRoot "tmp-zig017-build.stdout.txt"
        $stderr = Join-Path $RepoRoot "tmp-zig017-build.stderr.txt"
        Write-Host ("Writing logs: {0}, {1}" -f $stdout, $stderr)
        & $ZigExe @args 1> $stdout 2> $stderr
    }

    if ($LASTEXITCODE -ne 0) {
        throw "zig build failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Host "Zig 0.17 build completed."
