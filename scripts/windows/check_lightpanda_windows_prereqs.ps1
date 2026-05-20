Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$Name,
        [bool]$Ok,
        [string]$Details
    )
    $mark = if ($Ok) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1} - {2}" -f $mark, $Name, $Details)
}

function Get-CommandVersion {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    try {
        $output = & $Command @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        if ($null -eq $output) {
            return $null
        }
        return ($output | Select-Object -First 1).ToString().Trim()
    } catch {
        return $null
    }
}

$allOk = $true

# 1) Developer mode (enables non-admin symlink creation on many setups)
$devModeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$devModeValue = $null
try {
    $devModeValue = (Get-ItemProperty -Path $devModeKey -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop).AllowDevelopmentWithoutDevLicense
} catch {
    $devModeValue = 0
}
$devModeEnabled = ($devModeValue -eq 1)
Write-Status "DeveloperMode" $devModeEnabled ("AllowDevelopmentWithoutDevLicense={0}" -f $devModeValue)

# 2) Symlink capability test
$symlinkOk = $false
$tmpRoot = Join-Path $env:TEMP ("lightpanda_symlink_test_{0}" -f [Guid]::NewGuid().ToString("N"))
try {
    New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
    $target = Join-Path $tmpRoot "target.txt"
    $link = Join-Path $tmpRoot "link.txt"
    Set-Content -Path $target -Value "ok" -Encoding UTF8
    New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null
    $symlinkOk = $true
} catch {
    $symlinkOk = $false
} finally {
    Remove-Item -Path $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Status "SymlinkCreate" $symlinkOk "Create symbolic links in current shell"
if (-not $symlinkOk) { $allOk = $false }

# 3) Zig
$zigVersion = Get-CommandVersion -Command "zig" -Arguments @("version")
$zigOk = ($null -ne $zigVersion -and $zigVersion.Length -gt 0)
$zigDetails = if ($zigOk) { "zig {0}" -f $zigVersion } else { "zig not found in PATH" }
Write-Status "Zig" $zigOk $zigDetails
if (-not $zigOk) { $allOk = $false }

# 4) Python availability for localhost smoke probes and attached-pages replay
$pythonVersion = Get-CommandVersion -Command "python" -Arguments @("--version")
$pyLauncherVersion = if ($null -eq $pythonVersion) { Get-CommandVersion -Command "py" -Arguments @("-3", "--version") } else { $null }
$python3Version = if ($null -eq $pythonVersion -and $null -eq $pyLauncherVersion) { Get-CommandVersion -Command "python3" -Arguments @("--version") } else { $null }
$pythonOk = ($null -ne $pythonVersion -and $pythonVersion.Length -gt 0)
$pythonDetails = if ($pythonOk) {
    "{0} (matches the python-based localhost smoke and attached-pages scripts)" -f $pythonVersion
} elseif ($null -ne $pyLauncherVersion -and $pyLauncherVersion.Length -gt 0) {
    "{0} available through 'py -3', but repo smoke scripts invoke 'python'; add a PATH alias or launcher shim" -f $pyLauncherVersion
} elseif ($null -ne $python3Version -and $python3Version.Length -gt 0) {
    "{0} available through 'python3', but repo smoke scripts invoke 'python'; add a PATH alias or launcher shim" -f $python3Version
} else {
    "python not found in PATH; localhost smoke probes and attached-pages replay will fail to host their local pages"
}
Write-Status "Python" $pythonOk $pythonDetails
if (-not $pythonOk) { $allOk = $false }

# 5) WSL availability (recommended fallback workflow)
$wslOk = $false
try {
    $null = wsl.exe --status 2>$null
    $wslOk = $true
} catch {
    $wslOk = $false
}
$wslDetails = if ($wslOk) { "wsl.exe available" } else { "wsl.exe not available" }
Write-Status "WSL" $wslOk $wslDetails

if ($allOk) {
    Write-Host ""
    Write-Host "Windows prerequisites look good for local Lightpanda development and localhost headed validation."
    exit 0
}

Write-Host ""
Write-Host "One or more required prerequisites failed."
Write-Host "See docs/WINDOWS_FULL_USE.md for remediation, especially before running localhost smoke or attached-pages replay."
exit 1