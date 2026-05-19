[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8180,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$PollMilliseconds = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @{ FileName = "python"; Arguments = @() }
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @{ FileName = "py"; Arguments = @("-3") }
    }
    throw "Python was not found in PATH. Install Python or start the layout smoke server separately."
}

$root = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $root "..\..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$repo = $RepoRoot
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

function Find-ColorBoundsInRegion($Path, [scriptblock]$Predicate, [int]$MinX, [int]$MinY, [int]$MaxX, [int]$MaxY) {
  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($Path)
  try {
    $minFoundX = $bmp.Width
    $minFoundY = $bmp.Height
    $maxFoundX = -1
    $maxFoundY = -1
    $endX = [Math]::Min($MaxX, $bmp.Width - 1)
    $endY = [Math]::Min($MaxY, $bmp.Height - 1)
    for ($y = [Math]::Max(0, $MinY); $y -le $endY; $y++) {
      for ($x = [Math]::Max(0, $MinX); $x -le $endX; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if (& $Predicate $c) {
          if ($x -lt $minFoundX) { $minFoundX = $x }
          if ($y -lt $minFoundY) { $minFoundY = $y }
          if ($x -gt $maxFoundX) { $maxFoundX = $x }
          if ($y -gt $maxFoundY) { $maxFoundY = $y }
        }
      }
    }
    if ($maxFoundX -lt 0 -or $maxFoundY -lt 0) {
      throw "target color not found in region for $Path"
    }
    return [ordered]@{
      left = $minFoundX
      top = $minFoundY
      right = $maxFoundX
      bottom = $maxFoundY
      width = $maxFoundX - $minFoundX + 1
      height = $maxFoundY - $minFoundY + 1
    }
  }
  finally {
    $bmp.Dispose()
  }
}

$pageUrl = "http://$Host`:$Port/legacy-table.html"
$outPng = Join-Path $root "legacy-table.png"
$browserOut = Join-Path $root "legacy-table.browser.stdout.txt"
$browserErr = Join-Path $root "legacy-table.browser.stderr.txt"
$serverOut = Join-Path $root "legacy-table.server.stdout.txt"
$serverErr = Join-Path $root "legacy-table.server.stderr.txt"
$profileRoot = Join-Path $root "profile-legacy-table"
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$inputClickPoint = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null
$python = Resolve-PythonCommand
$server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr

try {
  if (-not (Wait-HttpReady $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds)) { throw "layout smoke server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","540","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng -Attempts $WindowReadyAttempts -SleepMs $PollMilliseconds)) { throw "legacy table screenshot did not become ready" }

    $logoBounds = Find-ColorBoundsInRegion $outPng { param($c) ($c.R -ge 60 -and $c.R -le 110) -and ($c.G -ge 120 -and $c.G -le 160) -and ($c.B -ge 220 -and $c.B -le 255) } 220 80 760 240
    $shellBounds = Find-ColorBoundsInRegion $outPng { param($c) ($c.R -ge 195 -and $c.R -le 215) -and ($c.G -ge 195 -and $c.G -le 215) -and ($c.B -ge 195 -and $c.B -le 215) } 180 220 780 340
    $sideBounds = Find-ColorBoundsInRegion $outPng { param($c) ($c.R -ge 20 -and $c.R -le 60) -and ($c.G -ge 140 -and $c.G -le 180) -and ($c.B -ge 70 -and $c.B -le 120) } 650 220 900 340
    $hwnd = [IntPtr]::Zero

    for ($i = 0; $i -lt 60; $i++) {
      Start-Sleep -Milliseconds 250
      $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
      if ($proc -and $proc.MainWindowHandle -ne 0) {
        $hwnd = [IntPtr]$proc.MainWindowHandle
        break
      }
    }
    if ($hwnd -eq [IntPtr]::Zero) {
      throw "legacy table probe window handle not found"
    }

    Show-SmokeWindow $hwnd
    Start-Sleep -Milliseconds 250

    $inputClickX = [int]($shellBounds.left + 28)
    $inputClickY = [int]($shellBounds.top + [Math]::Floor($shellBounds.height / 2))
    $inputClickPoint = Invoke-SmokeClientClick $hwnd $inputClickX $inputClickY

    $titleAfterFocus = Wait-ForTitleLike $hwnd "FOCUSED*"
    if (-not $titleAfterFocus) {
      throw "legacy table probe did not observe click focus on the search input"
    }

    Send-SmokeAsciiText "Q"
    $titleAfterType = Wait-ForTitleLike $hwnd "TYPED:Q*"
    if (-not $titleAfterType) {
      throw "legacy table probe did not observe typed input after click focus"
    }

    Send-SmokeEnter
    $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMITTED:Q:*"
    if (-not $titleAfterSubmit) {
      throw "legacy table probe did not observe Enter submit navigation"
    }
    if ($titleAfterSubmit -notlike "SUBMITTED:Q:KEYDOWN,KEYPRESS,SUBMIT") {
      throw "legacy table probe did not preserve Enter event order through submit"
    }

    $result = [ordered]@{
      logo = $logoBounds
      shell = $shellBounds
      side = $sideBounds
      input_click = $inputClickPoint
      title_after_focus = $titleAfterFocus
      title_after_type = $titleAfterType
      title_after_submit = $titleAfterSubmit
      logo_centered = ($logoBounds.left -ge 320) -and ($logoBounds.left -le 380)
      shell_centered = ($shellBounds.left -ge 240) -and ($shellBounds.left -le 300) -and ($shellBounds.width -ge 430)
      side_right = $sideBounds.left -ge ($shellBounds.right - 4)
      click_focus_worked = $null -ne $titleAfterFocus
      type_worked = $null -ne $titleAfterType
      enter_submit_order_worked = $null -ne $titleAfterSubmit -and $titleAfterSubmit -like "*KEYDOWN,KEYPRESS,SUBMIT*"
    }
    $result.legacy_table_worked = $result.logo_centered -and $result.shell_centered -and $result.side_right -and $result.click_focus_worked -and $result.type_worked -and $result.enter_submit_order_worked
    if (-not $result.legacy_table_worked) {
      throw "legacy table probe did not observe the full Google-style layout and input-submit path"
    }
    $result.page_url = $pageUrl
    $result.repo_root = $RepoRoot
    $result.browser_exe = $BrowserExe
    $result | ConvertTo-Json -Depth 6
  }
  finally {
    Stop-VerifiedProcess $browser.Id
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}
finally {
  Stop-VerifiedProcess $server.Id
  for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}
