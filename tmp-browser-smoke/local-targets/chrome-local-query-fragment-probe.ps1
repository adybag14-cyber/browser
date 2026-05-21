[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-local-query-fragment"
$root = Join-Path $config.RepoRoot "tmp-browser-smoke\local-targets"
$cases = @(
  [ordered]@{
    name = "query"
    target = "tmp-browser-smoke\local-targets\query-fragment-local-target.html?case=1"
    expected_title = "Local Query Target query case=1"
  },
  [ordered]@{
    name = "fragment"
    target = "tmp-browser-smoke\local-targets\query-fragment-local-target.html#focus-probe"
    expected_title = "Local Query Target fragment focus-probe"
  }
)

$results = @()
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $config.BrowserExe)) {
    throw "headed browser binary not found: $($config.BrowserExe)"
  }

  Reset-TabProbeProfile $config.ProfileRoot
  Set-TabProbeProfileEnvironment $config.ProfileRoot

  foreach ($case in $cases) {
    $browserOut = Join-Path $root ("chrome-local-query-fragment.{0}.browser.stdout.txt" -f $case.name)
    $browserErr = Join-Path $root ("chrome-local-query-fragment.{0}.browser.stderr.txt" -f $case.name)
    Remove-Item $browserOut,$browserErr -Force -ErrorAction SilentlyContinue

    $browser = $null
    $title = $null
    $caseFailure = $null

    try {
      $browser = Start-Process -FilePath $config.BrowserExe -ArgumentList @($case.target) -WorkingDirectory $config.RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
      $hwnd = Wait-TabWindowHandle $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
      if ($hwnd -eq [IntPtr]::Zero) {
        throw "local $($case.name) target window handle not found"
      }

      Show-SmokeWindow $hwnd
      $title = Wait-TabTitle $browser.Id $case.expected_title -Attempts 40 -PollMilliseconds $PollMilliseconds
      if (-not $title) {
        throw "local $($case.name) target did not reach expected title"
      }
    } catch {
      $caseFailure = $_.Exception.Message
      throw
    } finally {
      $browserMeta = Stop-OwnedProbeProcess $browser
      Start-Sleep -Milliseconds 200
      $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
      $results += [ordered]@{
        name = $case.name
        target = $case.target
        expected_title = $case.expected_title
        actual_title = $title
        error = $caseFailure
        browser_pid = if ($browser) { $browser.Id } else { 0 }
        browser_meta = $browserMeta
        browser_gone = $browserGone
      }
    }
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  [ordered]@{
    repo_root = $config.RepoRoot
    browser_exe = $config.BrowserExe
    profile_root = $config.ProfileRoot
    cases = $results
    error = $failure
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
