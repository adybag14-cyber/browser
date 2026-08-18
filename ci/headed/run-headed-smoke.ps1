param(
    [Parameter(Mandatory=$true)][string]$Executable,
    [string]$Artifacts = (Join-Path $PSScriptRoot 'artifacts'),
    [ValidateSet('Frame','Memory','All')][string]$Mode = 'All',
    [int]$MemoryBudgetMb = 0,
    [double]$MemoryGrowthBudgetMb = 0,
    [int]$MemoryWarmupMs = 2000,
    [int]$InputX = 294,
    [int]$InputY = 449,
    [int]$ButtonX = 421,
    [int]$ButtonY = 507,
    [int]$MemorySampleCount = 20,
    [int]$MemorySampleIntervalMs = 500,
    [string]$MemoryUrl = 'http://127.0.0.1:18773/trivial.html'
)

$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path $Executable).Path
New-Item -ItemType Directory -Force -Path $Artifacts | Out-Null
$Artifacts = (Resolve-Path $Artifacts).Path
$state = Join-Path $Artifacts 'state'
New-Item -ItemType Directory -Force -Path $state | Out-Null
$ready = Join-Path $state 'server-ready.txt'
$verified = Join-Path $state 'verified.txt'
$styled = Join-Path $state 'styled.txt'
Remove-Item $ready,$verified,$styled -Force -ErrorAction SilentlyContinue

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class LPWin32 {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder name, int max);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
}
'@

function Get-LightpandaWindow([int]$ProcessId, [int]$TimeoutSeconds = 30) {
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $script:found = [IntPtr]::Zero
        [LPWin32]::EnumWindows({
            param([IntPtr]$hwnd, [IntPtr]$lparam)
            $owner = [uint32]0
            [void][LPWin32]::GetWindowThreadProcessId($hwnd, [ref]$owner)
            if ($owner -ne $ProcessId) { return $true }
            $sb = New-Object Text.StringBuilder 256
            [void][LPWin32]::GetClassName($hwnd, $sb, $sb.Capacity)
            if ($sb.ToString() -eq 'LightpandaHeadedWindowClass') {
                $script:found = $hwnd
                return $false
            }
            return $true
        }, [IntPtr]::Zero) | Out-Null
        if ($script:found -ne [IntPtr]::Zero) { return $script:found }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Timed out waiting for LightpandaHeadedWindowClass for PID $ProcessId"
}

function Send-Click([IntPtr]$Hwnd, [int]$X, [int]$Y) {
    $lp = [IntPtr](($Y -shl 16) -bor ($X -band 0xffff))
    [void][LPWin32]::PostMessage($Hwnd, 0x0201, [IntPtr]1, $lp) # WM_LBUTTONDOWN / MK_LBUTTON
    Start-Sleep -Milliseconds 80
    [void][LPWin32]::PostMessage($Hwnd, 0x0202, [IntPtr]0, $lp) # WM_LBUTTONUP
    Start-Sleep -Milliseconds 120
}

function Send-Text([IntPtr]$Hwnd, [string]$Text) {
    foreach ($ch in $Text.ToCharArray()) {
        [void][LPWin32]::PostMessage($Hwnd, 0x0102, [IntPtr][int][char]$ch, [IntPtr]0) # WM_CHAR
        Start-Sleep -Milliseconds 35
    }
}

function Request-PngEvidence([IntPtr]$Hwnd, [string]$Directory, [string]$TargetName) {
    $started = [DateTime]::UtcNow.AddMilliseconds(-100)
    [void][LPWin32]::PostMessage($Hwnd, 0x0100, [IntPtr]0x2C, [IntPtr]0) # WM_KEYDOWN / VK_SNAPSHOT
    [void][LPWin32]::PostMessage($Hwnd, 0x0101, [IntPtr]0x2C, [IntPtr]0) # WM_KEYUP / VK_SNAPSHOT
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        $latest = Get-ChildItem -Path $Directory -Filter 'lightpanda-screenshot-*.png' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTimeUtc -ge $started } |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        if ($latest -and $latest.Length -ge 1024) {
            $target = Join-Path $Directory $TargetName
            Copy-Item $latest.FullName $target -Force
            return Get-Item $target
        }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Timed out waiting for PrintScreen PNG evidence: $TargetName"
}

function Stop-Browser($Process, [IntPtr]$Hwnd) {
    if ($Process -and -not $Process.HasExited) {
        if ($Hwnd -ne [IntPtr]::Zero -and [LPWin32]::IsWindow($Hwnd)) {
            [void][LPWin32]::PostMessage($Hwnd, 0x0010, [IntPtr]0, [IntPtr]0) # WM_CLOSE
            if ($Process.WaitForExit(5000)) { return }
        }
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        [void]$Process.WaitForExit(5000)
    }
}

function Wait-File([string]$Path, [int]$TimeoutSeconds = 20, [int64]$MinimumBytes = 1) {
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        if (Test-Path $Path) {
            $item = Get-Item $Path
            if ($item.Length -ge $MinimumBytes) { return $item }
        }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Timed out waiting for $Path"
}

$python = (Get-Command python).Source
$serverOut = Join-Path $Artifacts 'server.stdout.log'
$serverErr = Join-Path $Artifacts 'server.stderr.log'
$server = Start-Process -FilePath $python -ArgumentList @(
    (Join-Path $PSScriptRoot 'headed_ci_server.py'),
    '--ready-file', $ready,
    '--verified-file', $verified,
    '--styled-file', $styled
) -PassThru -WindowStyle Hidden -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr

try {
    [void](Wait-File $ready 20 1)

    if ($Mode -in @('Frame','All')) {
        Remove-Item $verified,$styled -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'frame-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'frame.stdout.log'
        $stderr = Join-Path $Artifacts 'frame.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/parent.html','--width','1000','--height','760','--profile-dir',$profile,'--enable-external-stylesheets')
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            [void](Wait-File $styled 30 1)
            # The native browser must paint incrementally even while subframes or
            # workers keep Session.Runner in a loading state. Do not gate this
            # smoke on --screenshot-png, whose one-shot contract deliberately
            # waits for load completion; PrintScreen captures the actual headed
            # surface and therefore proves the in-progress document is visible.
            Start-Sleep -Milliseconds 1800
            [void](Request-PngEvidence $hwnd $Artifacts 'frame-before.png')

            Send-Click $hwnd $InputX $InputY
            Send-Text $hwnd 'brown fox'
            Start-Sleep -Milliseconds 300
            [void](Request-PngEvidence $hwnd $Artifacts 'frame-typed.png')
            Send-Click $hwnd $ButtonX $ButtonY
            Start-Sleep -Milliseconds 300
            [void](Request-PngEvidence $hwnd $Artifacts 'frame-clicked.png')
            [void](Wait-File $verified 15 1)
            Start-Sleep -Milliseconds 800
            [void](Request-PngEvidence $hwnd $Artifacts 'frame-after.png')
            'FRAME_INTERACTION_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'frame-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }
    }

    if ($Mode -in @('Memory','All')) {
        $profile = Join-Path $state 'memory-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'memory.stdout.log'
        $stderr = Join-Path $Artifacts 'memory.stderr.log'
        $args = @('browse',$MemoryUrl,'--width','1000','--height','760','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        $samples = New-Object System.Collections.Generic.List[object]
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            if ($MemoryWarmupMs -gt 0) { Start-Sleep -Milliseconds $MemoryWarmupMs }
            for ($i=0; $i -lt $MemorySampleCount; $i++) {
                Start-Sleep -Milliseconds $MemorySampleIntervalMs
                $p = Get-Process -Id $browser.Id -ErrorAction Stop
                $samples.Add([pscustomobject]@{
                    sample = $i
                    working_set_mb = [math]::Round($p.WorkingSet64 / 1MB, 2)
                    private_mb = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
                    virtual_mb = [math]::Round($p.VirtualMemorySize64 / 1MB, 2)
                    handles = $p.HandleCount
                    threads = $p.Threads.Count
                })
            }
        }
        finally {
            Stop-Browser $browser $hwnd
        }
        $csv = Join-Path $Artifacts 'memory.csv'
        $samples | Export-Csv -NoTypeInformation -Encoding utf8 $csv
        $peakWs = ($samples | Measure-Object working_set_mb -Maximum).Maximum
        $peakPrivate = ($samples | Measure-Object private_mb -Maximum).Maximum
        $window = [Math]::Min(10, $samples.Count)
        if ($window -gt 0) {
            $firstWs = (($samples | Select-Object -First $window) | Measure-Object working_set_mb -Average).Average
            $lastWs = (($samples | Select-Object -Last $window) | Measure-Object working_set_mb -Average).Average
            $firstPrivate = (($samples | Select-Object -First $window) | Measure-Object private_mb -Average).Average
            $lastPrivate = (($samples | Select-Object -Last $window) | Measure-Object private_mb -Average).Average
        } else {
            $firstWs = 0; $lastWs = 0; $firstPrivate = 0; $lastPrivate = 0
        }
        $growthWs = [math]::Round($lastWs - $firstWs, 2)
        $growthPrivate = [math]::Round($lastPrivate - $firstPrivate, 2)
        $sampledSeconds = [math]::Round(($MemorySampleCount * $MemorySampleIntervalMs) / 1000.0, 2)
        $summary = [pscustomobject]@{
            memory_url = $MemoryUrl
            peak_working_set_mb = $peakWs
            peak_private_mb = $peakPrivate
            working_set_growth_mb = $growthWs
            private_growth_mb = $growthPrivate
            sampled_seconds = $sampledSeconds
            warmup_ms = $MemoryWarmupMs
            memory_budget_mb = $MemoryBudgetMb
            memory_growth_budget_mb = $MemoryGrowthBudgetMb
        }
        $summary | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $Artifacts 'memory-summary.json')
        Write-Host "Peak working set: $peakWs MiB; peak private: $peakPrivate MiB; RSS growth: $growthWs MiB; private growth: $growthPrivate MiB"
        if ($MemoryBudgetMb -gt 0 -and $peakWs -gt $MemoryBudgetMb) {
            throw "Headed RSS budget exceeded: $peakWs MiB > $MemoryBudgetMb MiB"
        }
        if ($MemoryGrowthBudgetMb -gt 0 -and $growthWs -gt $MemoryGrowthBudgetMb) {
            throw "Headed RSS growth budget exceeded: $growthWs MiB > $MemoryGrowthBudgetMb MiB over $sampledSeconds seconds"
        }
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        [void]$server.WaitForExit(5000)
    }
}
