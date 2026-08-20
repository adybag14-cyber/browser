param(
    [Parameter(Mandatory=$true)][string]$Executable,
    [string]$Artifacts = (Join-Path $PSScriptRoot 'artifacts'),
    [ValidateSet('Frame','Memory','All')][string]$Mode = 'All',
    [int]$MemoryBudgetMb = 0,
    [double]$MemoryGrowthBudgetMb = 0,
    [int]$MemoryWarmupMs = 2000,
    [int]$InputX = 294,
    [int]$InputY = 449,
    [int]$ButtonX = 174,
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
$bootstrapOk = Join-Path $state 'bootstrap-ok.txt'
$bootstrapFallback = Join-Path $state 'bootstrap-fallback-visible.txt'
$bootstrapCookieMissing = Join-Path $state 'bootstrap-cookie-missing.txt'
$keyboardValue = Join-Path $state 'keyboard-value.txt'
$caretValue = Join-Path $state 'caret-value.txt'
$navigationState = Join-Path $state 'navigation-state.txt'
$googleLayoutGeometry = Join-Path $state 'google-layout-geometry.json'
$googleLayoutFail = Join-Path $state 'google-layout-fail.json'
$wikipediaPortalGeometry = Join-Path $state 'wikipedia-portal-geometry.json'
$wikipediaSearchGeometry = Join-Path $state 'wikipedia-search-geometry.json'
Remove-Item $ready,$verified,$styled,$bootstrapOk,$bootstrapFallback,$bootstrapCookieMissing,$keyboardValue,$caretValue,$navigationState,$googleLayoutGeometry,$googleLayoutFail,$wikipediaPortalGeometry,$wikipediaSearchGeometry -Force -ErrorAction SilentlyContinue

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
  [DllImport("user32.dll")] public static extern uint MapVirtualKeyW(uint code, uint mapType);
  [DllImport("user32.dll")] public static extern uint GetGuiResources(IntPtr process, uint flags);
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

function Send-PhysicalKeyDown([IntPtr]$Hwnd, [uint32]$Vk) {
    $scan = [LPWin32]::MapVirtualKeyW($Vk, 0)
    $down = [IntPtr]([int64](1 -bor ([int64]$scan -shl 16)))
    [void][LPWin32]::PostMessage($Hwnd, 0x0100, [IntPtr][int64]$Vk, $down) # WM_KEYDOWN; TranslateMessage creates WM_CHAR
    Start-Sleep -Milliseconds 80
}

function Send-PhysicalKeyUp([IntPtr]$Hwnd, [uint32]$Vk) {
    $scan = [LPWin32]::MapVirtualKeyW($Vk, 0)
    $up = [IntPtr]([int64](1 -bor ([int64]$scan -shl 16) -bor 0xC0000000L))
    [void][LPWin32]::PostMessage($Hwnd, 0x0101, [IntPtr][int64]$Vk, $up) # WM_KEYUP
    Start-Sleep -Milliseconds 80
}

function Send-PhysicalKey([IntPtr]$Hwnd, [uint32]$Vk) {
    Send-PhysicalKeyDown $Hwnd $Vk
    Send-PhysicalKeyUp $Hwnd $Vk
}

function Send-PhysicalShiftKey([IntPtr]$Hwnd, [uint32]$Vk) {
    Send-PhysicalKeyDown $Hwnd 0x10 # VK_SHIFT
    Send-PhysicalKey $Hwnd $Vk
    Send-PhysicalKeyUp $Hwnd 0x10
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
    if (-not $Process) { return }
    if (-not $Process.HasExited) {
        if ($Hwnd -ne [IntPtr]::Zero -and [LPWin32]::IsWindow($Hwnd)) {
            [void][LPWin32]::PostMessage($Hwnd, 0x0010, [IntPtr]0, [IntPtr]0) # WM_CLOSE
            [void]$Process.WaitForExit(5000)
        }
        if (-not $Process.HasExited) {
            Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
            [void]$Process.WaitForExit(5000)
        }
    }
    if ($Process.ExitCode -ne 0) {
        throw "Headed browser exited with code $($Process.ExitCode); DebugAllocator leaks and crashes are fatal"
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

function Wait-NavigationState(
    [string]$Path,
    [string]$Target,
    [string]$Value,
    [string]$Start,
    [string]$End,
    [string]$Direction,
    [int]$TimeoutSeconds = 10
) {
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        if (Test-Path $Path) {
            $lines = @(Get-Content $Path)
            if ($lines.Count -ge 5 -and
                $lines[0] -eq $Target -and
                $lines[1] -eq $Value -and
                $lines[2] -eq $Start -and
                $lines[3] -eq $End -and
                $lines[4] -eq $Direction) {
                return
            }
        }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    $actual = if (Test-Path $Path) { (@(Get-Content $Path) -join '|') } else { '<missing>' }
    throw "Navigation state '$actual'; expected $Target|$Value|$Start|$End|$Direction"
}

$python = (Get-Command python).Source
$serverOut = Join-Path $Artifacts 'server.stdout.log'
$serverErr = Join-Path $Artifacts 'server.stderr.log'
$server = Start-Process -FilePath $python -ArgumentList @(
    (Join-Path $PSScriptRoot 'headed_ci_server.py'),
    '--ready-file', $ready,
    '--verified-file', $verified,
    '--styled-file', $styled,
    '--bootstrap-ok-file', $bootstrapOk,
    '--bootstrap-fallback-file', $bootstrapFallback,
    '--bootstrap-cookie-missing-file', $bootstrapCookieMissing,
    '--keyboard-value-file', $keyboardValue,
    '--caret-value-file', $caretValue,
    '--navigation-state-file', $navigationState,
    '--google-layout-file', $googleLayoutGeometry,
    '--google-layout-fail-file', $googleLayoutFail,
    '--wikipedia-portal-file', $wikipediaPortalGeometry,
    '--wikipedia-search-file', $wikipediaSearchGeometry
) -PassThru -WindowStyle Hidden -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr

try {
    [void](Wait-File $ready 20 1)

    if ($Mode -in @('Frame','All')) {
        Remove-Item $verified,$styled -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'frame-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'frame.stdout.log'
        $stderr = Join-Path $Artifacts 'frame.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/parent.html','--width','1000','--height','760','--profile-dir',$profile)
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

        # Exercise the real Win32 key path: WM_KEYDOWN is translated by the
        # window message pump into WM_CHAR. A printable key must therefore be
        # inserted exactly once, not once by keydown and again by WM_CHAR.
        Remove-Item $keyboardValue -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'keyboard-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'keyboard.stdout.log'
        $stderr = Join-Path $Artifacts 'keyboard.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/native-keyboard.html','--width','1000','--height','760','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            Start-Sleep -Milliseconds 700
            Send-PhysicalKey $hwnd 0x31 # 1 => a1bc
            [void](Wait-File $keyboardValue 10 1)
            Send-PhysicalKey $hwnd 0x08 # Backspace => abc
            Send-PhysicalKey $hwnd 0x2E # Delete => ac
            Send-PhysicalKey $hwnd 0x32 # 2 => a2c
            Start-Sleep -Milliseconds 250
            Send-PhysicalKey $hwnd 0x09 # Tab must move focus, never insert a control character
            Start-Sleep -Milliseconds 250
            $value = Get-Content $keyboardValue -Raw
            if ($value -ne 'a2c') { throw "Native physical-key editing produced '$value'; expected a2c" }
            'NATIVE_KEYBOARD_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'keyboard-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Native Home/End/Arrow keys must move the text caret rather than
        # being stolen by page scrolling. Shift+Arrow must extend/reverse a
        # selection through the real Win32 modifier/key message path.
        foreach ($navCase in @(
            @{ Target='nav-input'; Hash=''; ExpectedAfter='a2c3e'; ExpectedStart='4' },
            @{ Target='nav-area'; Hash='#textarea'; ExpectedAfter='a2c3e'; ExpectedStart='4' }
        )) {
            Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
            $safeTarget = $navCase.Target.Replace('nav-','')
            $profile = Join-Path $state "navigation-$safeTarget-profile"
            Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
            $stdout = Join-Path $Artifacts "navigation-$safeTarget.stdout.log"
            $stderr = Join-Path $Artifacts "navigation-$safeTarget.stderr.log"
            $url = "http://127.0.0.1:18773/native-navigation.html$($navCase.Hash)"
            $args = @('browse',$url,'--width','1000','--height','760','--profile-dir',$profile)
            $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
            $hwnd = [IntPtr]::Zero
            try {
                $hwnd = Get-LightpandaWindow $browser.Id 30
                Wait-NavigationState $navigationState $navCase.Target 'abcde' '5' '5' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x24 # Home => 0
                Wait-NavigationState $navigationState $navCase.Target 'abcde' '0' '0' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x27 # Right => 1
                Wait-NavigationState $navigationState $navCase.Target 'abcde' '1' '1' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalShiftKey $hwnd 0x27 # Shift+Right => select b forward
                Wait-NavigationState $navigationState $navCase.Target 'abcde' '1' '2' 'forward'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x32 # 2 replaces b => a2cde, caret 2
                Wait-NavigationState $navigationState $navCase.Target 'a2cde' '2' '2' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x23 # End => 5
                Wait-NavigationState $navigationState $navCase.Target 'a2cde' '5' '5' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x25 # Left => 4
                Wait-NavigationState $navigationState $navCase.Target 'a2cde' '4' '4' 'none'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalShiftKey $hwnd 0x25 # Shift+Left => select d backward
                Wait-NavigationState $navigationState $navCase.Target 'a2cde' '3' '4' 'backward'
                Remove-Item $navigationState -Force -ErrorAction SilentlyContinue
                Send-PhysicalKey $hwnd 0x33 # 3 replaces d => a2c3e
                Wait-NavigationState $navigationState $navCase.Target $navCase.ExpectedAfter $navCase.ExpectedStart $navCase.ExpectedStart 'none'
            }
            finally {
                Stop-Browser $browser $hwnd
            }
        }
        'NATIVE_NAVIGATION_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'navigation-result.txt')

        # A real headed pointer click must move the insertion caret inside a
        # single-line input according to the text the native backend actually
        # paints, not leave the pre-existing selection at the end.
        Remove-Item $caretValue -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'caret-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'caret.stdout.log'
        $stderr = Join-Path $Artifacts 'caret.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/native-caret.html','--width','1000','--height','760','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            Start-Sleep -Milliseconds 800
            [void](Request-PngEvidence $hwnd $Artifacts 'caret-focused.png')
            # Move focus away without changing page content. The focused and
            # blurred PNGs must differ solely because the native input caret is
            # visible while this field owns the collapsed selection.
            Send-PhysicalKey $hwnd 0x09 # Tab => focus sink button
            Start-Sleep -Milliseconds 300
            [void](Request-PngEvidence $hwnd $Artifacts 'caret-blurred.png')
            # The fixture's purple input box is x=70..430, y=187..225. Click
            # inside the left text padding; its load handler deliberately put
            # the caret at the end first, so this proves pointer relocation.
            Send-Click $hwnd 74 206
            Send-PhysicalKey $hwnd 0x31
            [void](Wait-File $caretValue 10 1)
            Start-Sleep -Milliseconds 250
            [void](Request-PngEvidence $hwnd $Artifacts 'caret-edited.png')
            $caretLines = @(Get-Content $caretValue)
            if ($caretLines.Count -lt 2 -or $caretLines[0] -ne '1abcdef' -or $caretLines[1] -ne '1') {
                throw "Native pointer caret produced '$($caretLines -join '|')'; expected 1abcdef|1"
            }
            'NATIVE_CARET_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'caret-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # A single-line input must never be painted through the generic wrapped
        # text path. Keep the field focused at the end of a long query so this
        # also exercises native horizontal scroll-to-caret. Pixel validation in
        # the workflow rejects any second vertical text band inside the control.
        $profile = Join-Path $state 'long-input-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'long-input.stdout.log'
        $stderr = Join-Path $Artifacts 'long-input.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/native-long-input.html','--width','1000','--height','760','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            Start-Sleep -Milliseconds 800
            [void](Request-PngEvidence $hwnd $Artifacts 'long-input.png')
            'SINGLE_LINE_INPUT_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'long-input-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Google Search can serve a JavaScript capability bootstrap before
        # results. Guard the browser primitives that page relies on without
        # hitting Google's volatile anti-abuse service: Promise/callback work,
        # cookie persistence, and script-driven Location.replace navigation
        # must all complete before the troubleshooting fallback's 2s timer.
        Remove-Item $bootstrapOk,$bootstrapFallback,$bootstrapCookieMissing -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'bootstrap-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'bootstrap.stdout.log'
        $stderr = Join-Path $Artifacts 'bootstrap.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/google-bootstrap.html','--width','1000','--height','760','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            [void](Wait-File $bootstrapOk 15 1)
            if (Test-Path $bootstrapFallback) {
                throw 'Google-style JavaScript bootstrap exposed its troubleshooting fallback before redirecting'
            }
            if (Test-Path $bootstrapCookieMissing) {
                throw 'Google-style JavaScript bootstrap lost the SG_SS-style cookie across Location.replace'
            }
            Start-Sleep -Milliseconds 2300
            if (Test-Path $bootstrapFallback) {
                throw 'Google-style JavaScript bootstrap fallback timer survived navigation'
            }
            [void](Request-PngEvidence $hwnd $Artifacts 'bootstrap-after.png')
            'GOOGLE_BOOTSTRAP_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'bootstrap-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Search-page layout regression: this fixture deliberately uses the
        # same flex-row + auto-margin structure as a desktop search header.
        # Its script reports CSSOM geometry after native presentation has had
        # time to cache real boxes, then CI also inspects the rendered pixels.
        Remove-Item $googleLayoutGeometry,$googleLayoutFail -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'google-layout-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'google-layout.stdout.log'
        $stderr = Join-Path $Artifacts 'google-layout.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/google-layout.html','--width','1280','--height','900','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            $deadline = [DateTime]::UtcNow.AddSeconds(15)
            do {
                if (Test-Path $googleLayoutFail) {
                    $bad = Get-Content $googleLayoutFail -Raw
                    throw "Google-layout CSSOM geometry failed: $bad"
                }
                if (Test-Path $googleLayoutGeometry) { break }
                Start-Sleep -Milliseconds 100
            } while ([DateTime]::UtcNow -lt $deadline)
            [void](Wait-File $googleLayoutGeometry 2 2)
            Copy-Item $googleLayoutGeometry (Join-Path $Artifacts 'google-layout-geometry.json') -Force
            Start-Sleep -Milliseconds 250
            [void](Request-PngEvidence $hwnd $Artifacts 'google-layout.png')
            'GOOGLE_LAYOUT_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'google-layout-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Wikipedia portal regression: root-relative units and absolute
        # percentage positioning must match the actual desktop portal pattern.
        Remove-Item $wikipediaPortalGeometry -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'wikipedia-portal-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'wikipedia-portal.stdout.log'
        $stderr = Join-Path $Artifacts 'wikipedia-portal.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/wikipedia-portal.html','--width','1000','--height','900','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            [void](Wait-File $wikipediaPortalGeometry 15 2)
            Copy-Item $wikipediaPortalGeometry (Join-Path $Artifacts 'wikipedia-portal-geometry.json') -Force
            Start-Sleep -Milliseconds 250
            [void](Request-PngEvidence $hwnd $Artifacts 'wikipedia-portal.png')
            'WIKIPEDIA_PORTAL_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'wikipedia-portal-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Wikipedia search regression: inline-flow CSSOM boxes, compact sprite
        # sizing, rem min-height and CSS custom-property painting are all gated.
        Remove-Item $wikipediaSearchGeometry -Force -ErrorAction SilentlyContinue
        $profile = Join-Path $state 'wikipedia-search-profile'
        Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
        $stdout = Join-Path $Artifacts 'wikipedia-search.stdout.log'
        $stderr = Join-Path $Artifacts 'wikipedia-search.stderr.log'
        $args = @('browse','http://127.0.0.1:18773/wikipedia-search.html','--width','1000','--height','500','--profile-dir',$profile)
        $browser = Start-Process -FilePath $Executable -ArgumentList $args -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $hwnd = [IntPtr]::Zero
        try {
            $hwnd = Get-LightpandaWindow $browser.Id 30
            [void](Wait-File $wikipediaSearchGeometry 15 2)
            Copy-Item $wikipediaSearchGeometry (Join-Path $Artifacts 'wikipedia-search-geometry.json') -Force
            Start-Sleep -Milliseconds 250
            [void](Request-PngEvidence $hwnd $Artifacts 'wikipedia-search.png')
            'WIKIPEDIA_SEARCH_OK' | Set-Content -Encoding utf8 (Join-Path $Artifacts 'wikipedia-search-result.txt')
        }
        finally {
            Stop-Browser $browser $hwnd
        }

        # Best-effort live Wikipedia evidence. The deterministic fixtures above
        # are the gate; this capture makes real-site rendering regressions visible.
        $wikiLiveProfile = Join-Path $state 'wikipedia-live-profile'
        Remove-Item $wikiLiveProfile -Recurse -Force -ErrorAction SilentlyContinue
        $wikiLiveStdout = Join-Path $Artifacts 'wikipedia-live.stdout.log'
        $wikiLiveStderr = Join-Path $Artifacts 'wikipedia-live.stderr.log'
        $wikiLiveArgs = @('browse','https://www.wikipedia.org/','--width','1280','--height','900','--enable-external-stylesheets','--profile-dir',$wikiLiveProfile,'--http-timeout','10000','--watchdog-ms','15000')
        $wikiLive = $null
        $wikiLiveHwnd = [IntPtr]::Zero
        $wikiLiveSamples = New-Object System.Collections.Generic.List[object]
        $wikiLiveStatus = 'not-started'
        $wikiLiveError = ''
        try {
            $wikiLive = Start-Process -FilePath $Executable -ArgumentList $wikiLiveArgs -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $wikiLiveStdout -RedirectStandardError $wikiLiveStderr
            $wikiLiveHwnd = Get-LightpandaWindow $wikiLive.Id 15
            $wikiLiveStatus = 'window-open'
            for ($i=0; $i -lt 12; $i++) {
                Start-Sleep -Milliseconds 500
                if ($wikiLive.HasExited) { break }
                $p = Get-Process -Id $wikiLive.Id -ErrorAction Stop
                $wikiLiveSamples.Add([pscustomobject]@{ elapsed_ms = (($i + 1) * 500); rss_mb = [math]::Round($p.WorkingSet64 / 1MB, 2); private_mb = [math]::Round($p.PrivateMemorySize64 / 1MB, 2); cpu_seconds = [math]::Round($p.CPU, 3) })
            }
            [void](Request-PngEvidence $wikiLiveHwnd $Artifacts 'wikipedia-live.png')
            $wikiLiveStatus = 'captured'
        }
        catch {
            $wikiLiveStatus = 'capture-error'
            $wikiLiveError = $_.Exception.Message
        }
        finally {
            if ($wikiLive -and -not $wikiLive.HasExited) {
                Stop-Process -Id $wikiLive.Id -Force -ErrorAction SilentlyContinue
                [void]$wikiLive.WaitForExit(5000)
            }
        }
        $wikiLivePeakRss = if ($wikiLiveSamples.Count -gt 0) { ($wikiLiveSamples | Measure-Object rss_mb -Maximum).Maximum } else { 0 }
        $wikiLivePeakPrivate = if ($wikiLiveSamples.Count -gt 0) { ($wikiLiveSamples | Measure-Object private_mb -Maximum).Maximum } else { 0 }
        $wikiLiveCpuDelta = if ($wikiLiveSamples.Count -gt 1) { [math]::Round([double]$wikiLiveSamples[$wikiLiveSamples.Count - 1].cpu_seconds - [double]$wikiLiveSamples[0].cpu_seconds, 3) } else { 0 }
        $wikiLiveElapsed = if ($wikiLiveSamples.Count -gt 1) { ([double]$wikiLiveSamples[$wikiLiveSamples.Count - 1].elapsed_ms - [double]$wikiLiveSamples[0].elapsed_ms) / 1000.0 } else { 0 }
        $wikiLiveCorePct = if ($wikiLiveElapsed -gt 0) { [math]::Round(($wikiLiveCpuDelta / $wikiLiveElapsed) * 100.0, 1) } else { 0 }
        [pscustomobject]@{ status = $wikiLiveStatus; error = $wikiLiveError; samples = $wikiLiveSamples.Count; peak_rss_mb = $wikiLivePeakRss; peak_private_mb = $wikiLivePeakPrivate; cpu_delta_seconds = $wikiLiveCpuDelta; elapsed_seconds = $wikiLiveElapsed; one_core_cpu_percent = $wikiLiveCorePct; screenshot = (Test-Path (Join-Path $Artifacts 'wikipedia-live.png')) } |
            ConvertTo-Json -Depth 3 | Set-Content -Encoding utf8 (Join-Path $Artifacts 'wikipedia-live-summary.json')

        # Best-effort live Google evidence. External anti-abuse/network state is
        # intentionally non-gating, but we always try to capture the real native
        # window and record CPU/RSS so a busy navigation loop remains visible.
        $liveProfile = Join-Path $state 'google-live-profile'
        Remove-Item $liveProfile -Recurse -Force -ErrorAction SilentlyContinue
        $liveStdout = Join-Path $Artifacts 'google-live.stdout.log'
        $liveStderr = Join-Path $Artifacts 'google-live.stderr.log'
        $liveArgs = @('browse','https://www.google.com/search?q=brown+fox&hl=en','--width','1280','--height','900','--enable-external-stylesheets','--profile-dir',$liveProfile,'--http-timeout','10000','--watchdog-ms','15000')
        $live = $null
        $liveHwnd = [IntPtr]::Zero
        $liveSamples = New-Object System.Collections.Generic.List[object]
        $liveStatus = 'not-started'
        $liveError = ''
        try {
            $live = Start-Process -FilePath $Executable -ArgumentList $liveArgs -WorkingDirectory $Artifacts -PassThru -RedirectStandardOutput $liveStdout -RedirectStandardError $liveStderr
            $liveHwnd = Get-LightpandaWindow $live.Id 15
            $liveStatus = 'window-open'
            for ($i=0; $i -lt 16; $i++) {
                Start-Sleep -Milliseconds 500
                if ($live.HasExited) { break }
                $p = Get-Process -Id $live.Id -ErrorAction Stop
                $liveSamples.Add([pscustomobject]@{ elapsed_ms = (($i + 1) * 500); rss_mb = [math]::Round($p.WorkingSet64 / 1MB, 2); private_mb = [math]::Round($p.PrivateMemorySize64 / 1MB, 2); cpu_seconds = [math]::Round($p.CPU, 3) })
            }
            [void](Request-PngEvidence $liveHwnd $Artifacts 'google-live.png')
            $liveStatus = 'captured'
        }
        catch {
            $liveStatus = 'capture-error'
            $liveError = $_.Exception.Message
        }
        finally {
            if ($live -and -not $live.HasExited) {
                Stop-Process -Id $live.Id -Force -ErrorAction SilentlyContinue
                [void]$live.WaitForExit(5000)
            }
        }
        $livePeakRss = if ($liveSamples.Count -gt 0) { ($liveSamples | Measure-Object rss_mb -Maximum).Maximum } else { 0 }
        $livePeakPrivate = if ($liveSamples.Count -gt 0) { ($liveSamples | Measure-Object private_mb -Maximum).Maximum } else { 0 }
        $liveCpuDelta = if ($liveSamples.Count -gt 1) { [math]::Round([double]$liveSamples[$liveSamples.Count - 1].cpu_seconds - [double]$liveSamples[0].cpu_seconds, 3) } else { 0 }
        $liveElapsed = if ($liveSamples.Count -gt 1) { ([double]$liveSamples[$liveSamples.Count - 1].elapsed_ms - [double]$liveSamples[0].elapsed_ms) / 1000.0 } else { 0 }
        $liveCorePct = if ($liveElapsed -gt 0) { [math]::Round(($liveCpuDelta / $liveElapsed) * 100.0, 1) } else { 0 }
        [pscustomobject]@{ status = $liveStatus; error = $liveError; samples = $liveSamples.Count; peak_rss_mb = $livePeakRss; peak_private_mb = $livePeakPrivate; cpu_delta_seconds = $liveCpuDelta; elapsed_seconds = $liveElapsed; one_core_cpu_percent = $liveCorePct; screenshot = (Test-Path (Join-Path $Artifacts 'google-live.png')) } |
            ConvertTo-Json -Depth 3 | Set-Content -Encoding utf8 (Join-Path $Artifacts 'google-live-summary.json')
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
                    gdi_objects = [LPWin32]::GetGuiResources($p.Handle, 0)
                    user_objects = [LPWin32]::GetGuiResources($p.Handle, 1)
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
        $peakGdi = ($samples | Measure-Object gdi_objects -Maximum).Maximum
        $window = [Math]::Min(10, $samples.Count)
        if ($window -gt 0) {
            $firstWs = (($samples | Select-Object -First $window) | Measure-Object working_set_mb -Average).Average
            $lastWs = (($samples | Select-Object -Last $window) | Measure-Object working_set_mb -Average).Average
            $firstPrivate = (($samples | Select-Object -First $window) | Measure-Object private_mb -Average).Average
            $lastPrivate = (($samples | Select-Object -Last $window) | Measure-Object private_mb -Average).Average
            $firstGdi = (($samples | Select-Object -First $window) | Measure-Object gdi_objects -Average).Average
            $lastGdi = (($samples | Select-Object -Last $window) | Measure-Object gdi_objects -Average).Average
        } else {
            $firstWs = 0; $lastWs = 0; $firstPrivate = 0; $lastPrivate = 0; $firstGdi = 0; $lastGdi = 0
        }
        $growthWs = [math]::Round($lastWs - $firstWs, 2)
        $growthPrivate = [math]::Round($lastPrivate - $firstPrivate, 2)
        $growthGdi = [math]::Round($lastGdi - $firstGdi, 2)
        $sampledSeconds = [math]::Round(($MemorySampleCount * $MemorySampleIntervalMs) / 1000.0, 2)
        $summary = [pscustomobject]@{
            memory_url = $MemoryUrl
            peak_working_set_mb = $peakWs
            peak_private_mb = $peakPrivate
            peak_gdi_objects = $peakGdi
            working_set_growth_mb = $growthWs
            private_growth_mb = $growthPrivate
            gdi_object_growth = $growthGdi
            sampled_seconds = $sampledSeconds
            warmup_ms = $MemoryWarmupMs
            memory_budget_mb = $MemoryBudgetMb
            memory_growth_budget_mb = $MemoryGrowthBudgetMb
        }
        $summary | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $Artifacts 'memory-summary.json')
        Write-Host "Peak working set: $peakWs MiB; peak private: $peakPrivate MiB; RSS growth: $growthWs MiB; private growth: $growthPrivate MiB; peak GDI: $peakGdi; GDI growth: $growthGdi"
        if ($MemoryBudgetMb -gt 0 -and $peakWs -gt $MemoryBudgetMb) {
            throw "Headed RSS budget exceeded: $peakWs MiB > $MemoryBudgetMb MiB"
        }
        if ($MemoryGrowthBudgetMb -gt 0 -and $growthWs -gt $MemoryGrowthBudgetMb) {
            throw "Headed RSS growth budget exceeded: $growthWs MiB > $MemoryGrowthBudgetMb MiB over $sampledSeconds seconds"
        }
        if ($growthGdi -gt 2) {
            throw "Headed GDI object growth detected: $growthGdi objects over $sampledSeconds seconds"
        }
    }
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        [void]$server.WaitForExit(5000)
    }
}
