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

function Resolve-RepoRoot {
    param(
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            return $null
        }
        $cursor = $parent
    }
}

function Get-MinimumZigVersion {
    param(
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        return $null
    }

    $zonPath = Join-Path $RepoRoot "build.zig.zon"
    if (-not (Test-Path $zonPath)) {
        return $null
    }

    $match = Select-String -Path $zonPath -Pattern '\.minimum_zig_version\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($null -eq $match -or $match.Matches.Count -eq 0) {
        return $null
    }

    return $match.Matches[0].Groups[1].Value
}

function Get-SemVerCore {
    param(
        [string]$VersionText
    )

    if ([string]::IsNullOrWhiteSpace($VersionText)) {
        return $null
    }

    $match = [regex]::Match($VersionText, '(\d+\.\d+\.\d+)')
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value
}

function Test-VersionAtLeast {
    param(
        [string]$VersionText,
        [string]$MinimumText
    )

    $versionCore = Get-SemVerCore -VersionText $VersionText
    $minimumCore = Get-SemVerCore -VersionText $MinimumText
    if ([string]::IsNullOrWhiteSpace($versionCore) -or [string]::IsNullOrWhiteSpace($minimumCore)) {
        return $false
    }

    try {
        return ([version]$versionCore -ge [version]$minimumCore)
    } catch {
        return $false
    }
}

function Get-MissingDependencyMarkers {
    param(
        [string]$DependencyPath,
        [string[]]$Markers
    )

    $missing = @()
    foreach ($marker in $Markers) {
        if (-not (Test-Path (Join-Path $DependencyPath $marker))) {
            $missing += $marker
        }
    }

    return $missing
}

$allOk = $true
$repoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
$minimumZigVersion = Get-MinimumZigVersion -RepoRoot $repoRoot

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

# 3) Zig presence
$zigVersion = Get-CommandVersion -Command "zig" -Arguments @("version")
$zigOk = ($null -ne $zigVersion -and $zigVersion.Length -gt 0)
$zigDetails = if ($zigOk) {
    if ($minimumZigVersion) {
        "zig {0} (build.zig.zon minimum {1})" -f $zigVersion, $minimumZigVersion
    } else {
        "zig {0}" -f $zigVersion
    }
} else {
    "zig not found in PATH"
}
Write-Status "Zig" $zigOk $zigDetails
if (-not $zigOk) { $allOk = $false }

# 4) Branch-aligned Zig compatibility
$zigBranchOk = $zigOk
if (-not $zigOk) {
    $zigBranchDetails = "cannot compare against build.zig.zon without zig in PATH"
} elseif (-not $minimumZigVersion) {
    $zigBranchDetails = "build.zig.zon minimum_zig_version could not be resolved from this checkout"
} elseif ($zigVersion -like "0.17.0-dev.299*") {
    $zigBranchOk = $false
    $zigBranchDetails = "build.zig.zon declares minimum_zig_version={0}; the attached 0.17.0-dev.299 fallback has recently failed in untouched branch files before headed validation, so prefer a 0.15.2 toolchain or the repo's normal CI-aligned build path" -f $minimumZigVersion
} elseif (-not (Test-VersionAtLeast -VersionText $zigVersion -MinimumText $minimumZigVersion)) {
    $zigBranchOk = $false
    $zigBranchDetails = "zig {0} is older than the branch minimum {1}" -f $zigVersion, $minimumZigVersion
} else {
    $zigVersionCore = Get-SemVerCore -VersionText $zigVersion
    if ($zigVersionCore -eq $minimumZigVersion) {
        $zigBranchDetails = "zig {0} matches the branch minimum declared in build.zig.zon" -f $zigVersion
    } else {
        $zigBranchDetails = "zig {0} satisfies the branch minimum {1}; if headed validation drifts, fall back to a 0.15.2 toolchain before blaming the browser code" -f $zigVersion, $minimumZigVersion
    }
}
Write-Status "ZigBranchCompatibility" $zigBranchOk $zigBranchDetails
if (-not $zigBranchOk) { $allOk = $false }

# 5) Sibling dependency layout required by build.zig.zon path dependencies
$pathDependencyRoot = if ($repoRoot) { Split-Path $repoRoot -Parent } else { $null }
$pathDependencies = @(
    @{
        Name = "zig-v8-fork"
        Path = if ($pathDependencyRoot) { Join-Path $pathDependencyRoot "zig-v8-fork" } else { $null }
        Markers = @("build.zig", "build.zig.zon", "src\v8.zig")
    },
    @{
        Name = "boringssl-zig"
        Path = if ($pathDependencyRoot) { Join-Path $pathDependencyRoot "boringssl-zig" } else { $null }
        Markers = @("build.zig", "README.md", "generated")
    }
)

foreach ($dependency in $pathDependencies) {
    $depName = $dependency.Name
    $depPath = $dependency.Path
    $depOk = $false

    if ([string]::IsNullOrWhiteSpace($depPath)) {
        $depDetails = "repo root could not be resolved from this checkout"
    } elseif (-not (Test-Path $depPath -PathType Container)) {
        $depDetails = "missing sibling checkout at {0}; build.zig.zon expects ../{1}" -f $depPath, $depName
    } else {
        $missingMarkers = Get-MissingDependencyMarkers -DependencyPath $depPath -Markers $dependency.Markers
        if ($missingMarkers.Count -eq 0) {
            $depOk = $true
            $depDetails = "found sibling checkout at {0}" -f $depPath
        } else {
            $depDetails = "incomplete sibling checkout at {0}; missing {1}" -f $depPath, ($missingMarkers -join ", ")
        }
    }

    Write-Status ("SiblingDep {0}" -f $depName) $depOk $depDetails
    if (-not $depOk) { $allOk = $false }
}

# 6) Python availability for localhost smoke probes and attached-pages replay
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

# 7) WSL availability (recommended fallback workflow)
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
    Write-Host "Windows prerequisites and branch-local build dependencies look good for local Lightpanda development and localhost headed validation."
    exit 0
}

Write-Host ""
Write-Host "One or more required prerequisites failed."
Write-Host "See docs/WINDOWS_FULL_USE.md before retrying a headed build or localhost validation run; use the repo's sibling dependency layout and a 0.15.2-compatible Zig toolchain first."
exit 1
