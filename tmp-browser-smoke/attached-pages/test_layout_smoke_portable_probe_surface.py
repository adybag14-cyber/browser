import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_explicit_headed_launch(testcase: unittest.TestCase, source: str, label: str) -> None:
    pattern = re.compile(
        r'Start-Process\s+-FilePath\s+\$browserExe\s+-ArgumentList\s+.*?"browse".*?"--browser_mode".*?"headed"',
        re.DOTALL,
    )
    testcase.assertRegex(source, pattern, f"{label} should launch browse with explicit headed mode")


FIXTURE_FILES = {
    "tmp-browser-smoke/layout-smoke/chrome-selector-forgiving-probe.ps1": r"""
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8180,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\layout-smoke"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common

$pageUrl = "http://$Host`:$Port/selector-forgiving.html"
$outPng = Join-Path $root "selector-forgiving.png"
$browserOut = Join-Path $root "selector-forgiving.browser.stdout.txt"
$browserErr = Join-Path $root "selector-forgiving.browser.stderr.txt"
$serverOut = Join-Path $root "selector-forgiving.server.stdout.txt"
$serverErr = Join-Path $root "selector-forgiving.server.stderr.txt"
$profileRoot = Join-Path $root "profile-selector-forgiving"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "layout smoke server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds)) {
    throw "layout smoke server did not become ready"
  }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","520","--window_height","320","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "selector forgiving screenshot did not become ready" }
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90 }
    $blueFound = $true
    try {
      $null = Find-ColorBounds $outPng { param($c) $c.B -ge 180 -and $c.R -le 90 -and $c.G -le 150 }
    } catch {
      $blueFound = $false
    }

    $result = [ordered]@{
      red = $red
      red_visible = $red.width -ge 160
      duplicate_hidden = -not $blueFound
    }
    $result.selector_forgiving_worked = $result.red_visible -and $result.duplicate_hidden
    if (-not $result.selector_forgiving_worked) {
      throw "selector forgiving probe did not preserve the valid branch while hiding the duplicate"
    }
    $result | ConvertTo-Json -Depth 6
  }
  finally {
    $null = Stop-LightpandaOwnedProbeProcess $browser
  }
}
finally {
  $null = Stop-LightpandaOwnedProbeProcess $server
}
""",
    "tmp-browser-smoke/layout-smoke/chrome-screenshot-delayed-content-probe.ps1": r"""
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8180,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\layout-smoke"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common

$pageUrl = "http://$Host`:$Port/delayed-screenshot.html"
$outPng = Join-Path $root "delayed-screenshot.png"
$browserOut = Join-Path $root "delayed-screenshot.browser.stdout.txt"
$browserErr = Join-Path $root "delayed-screenshot.browser.stderr.txt"
$serverOut = Join-Path $root "delayed-screenshot.server.stdout.txt"
$serverErr = Join-Path $root "delayed-screenshot.server.stderr.txt"
$profileRoot = Join-Path $root "profile-delayed-screenshot"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "layout smoke server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds)) {
    throw "layout smoke server did not become ready"
  }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $started = Get-Date
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "delayed screenshot did not become ready" }
    $elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90 }
    $result = [ordered]@{
      red = $red
      elapsed_ms = $elapsedMs
      delayed_content_visible = ($red.width -ge 160) -and ($red.height -ge 24)
      capture_waited = ($elapsedMs -ge 500)
    }
    $result.delayed_screenshot_worked = $result.delayed_content_visible -and $result.capture_waited
    if (-not $result.delayed_screenshot_worked) {
      throw "delayed screenshot probe captured before delayed content was painted"
    }
    $result | ConvertTo-Json -Depth 6
  }
  finally {
    $null = Stop-LightpandaOwnedProbeProcess $browser
  }
}
finally {
  $null = Stop-LightpandaOwnedProbeProcess $server
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-layout-portable-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class LayoutSmokePortableProbeSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.selector_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-selector-forgiving-probe.ps1"
        )
        cls.delayed_probe = read_text(
            cls.repo_root / "tmp-browser-smoke/layout-smoke/chrome-screenshot-delayed-content-probe.ps1"
        )

    def test_selector_probe_uses_portable_runtime_resolution(self) -> None:
        for snippet in (
            "Resolve-LightpandaRepoRoot",
            "Resolve-LightpandaBrowserExe",
            "Resolve-LightpandaPythonCommand",
            "Wait-LightpandaHttpReady",
            "Stop-LightpandaOwnedProbeProcess",
        ):
            self.assertIn(snippet, self.selector_probe)
        self.assertNotIn(r"C:\Users\adyba\src\lightpanda-browser", self.selector_probe)
        self.assertNotIn('Start-Process -FilePath "python"', self.selector_probe)
        assert_explicit_headed_launch(self, self.selector_probe, "selector forgiving probe")

    def test_selector_probe_keeps_selector_specific_assertions(self) -> None:
        self.assertIn("duplicate_hidden", self.selector_probe)
        self.assertIn("selector_forgiving_worked", self.selector_probe)
        self.assertIn("valid branch while hiding the duplicate", self.selector_probe)

    def test_delayed_probe_uses_portable_runtime_resolution(self) -> None:
        for snippet in (
            "Resolve-LightpandaRepoRoot",
            "Resolve-LightpandaBrowserExe",
            "Resolve-LightpandaPythonCommand",
            "Wait-LightpandaHttpReady",
            "Stop-LightpandaOwnedProbeProcess",
        ):
            self.assertIn(snippet, self.delayed_probe)
        self.assertNotIn(r"C:\Users\adyba\src\lightpanda-browser", self.delayed_probe)
        self.assertNotIn('Start-Process -FilePath "python"', self.delayed_probe)
        assert_explicit_headed_launch(self, self.delayed_probe, "delayed screenshot probe")

    def test_delayed_probe_keeps_capture_wait_assertions(self) -> None:
        self.assertIn("elapsed_ms", self.delayed_probe)
        self.assertIn("delayed_content_visible", self.delayed_probe)
        self.assertIn("capture_waited", self.delayed_probe)
        self.assertIn("delayed_screenshot_worked", self.delayed_probe)


if __name__ == "__main__":
    unittest.main()
