[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [ValidateSet("Table", "Json", "Markdown")]
  [string]$Format = "Table"
)

$ErrorActionPreference = "Stop"

$smokeRoot = Join-Path $RepoRoot "tmp-browser-smoke"
$hardcodedRepoPath = 'C:\Users\adyba\src\lightpanda-browser'
$gateSuites = @(
  @{
    Name = "shell-navigation"
    Phase = "release-gate"
    Directories = @("tabs", "browser-pages", "settings", "wrapped-link", "popup")
    Notes = "Shell chrome, navigation, browser pages, and popup flows."
  },
  @{
    Name = "rendering-layout"
    Phase = "release-gate"
    Directories = @("layout-smoke", "inline-flow", "font-render", "image-smoke")
    Notes = "Visible surface, layout, text, and image correctness."
  },
  @{
    Name = "forms-file-handling"
    Phase = "release-gate"
    Directories = @("form-controls", "file-upload", "downloads", "attachment-downloads")
    Notes = "Text entry, submit, upload, and download flows."
  },
  @{
    Name = "storage-session"
    Phase = "release-gate"
    Directories = @("cookie-persistence", "localstorage-persistence", "indexeddb-persistence", "sessionstorage-scope")
    Notes = "Persistent profile, restart, and cross-tab storage behavior."
  },
  @{
    Name = "network-runtime"
    Phase = "release-gate"
    Directories = @("fetch-abort", "fetch-credentials", "websocket-smoke", "stylesheet-smoke")
    Notes = "Network/runtime compatibility for shared browser-managed requests."
  },
  @{
    Name = "graphics"
    Phase = "release-gate"
    Directories = @("canvas-smoke")
    Notes = "Canvas and early WebGL coverage."
  },
  @{
    Name = "phase0-bringup"
    Phase = "daily-smoke"
    Directories = @("form-controls", "wrapped-link", "browser-pages", "layout-smoke")
    Notes = "Small starter sweep for headed validation during routine development."
  }
)

function Get-RepoRelativePath([string]$Path) {
  $resolvedRoot = (Resolve-Path $RepoRoot).Path
  $resolvedPath = (Resolve-Path $Path).Path
  if ($resolvedPath.StartsWith($resolvedRoot)) {
    return $resolvedPath.Substring($resolvedRoot.Length + 1)
  }
  return $resolvedPath
}

function Get-ProbeSummary([string]$DirectoryName) {
  $directoryPath = Join-Path $smokeRoot $DirectoryName
  if (-not (Test-Path $directoryPath)) {
    return [pscustomobject]@{
      Directory = $DirectoryName
      Exists = $false
      ProbeCount = 0
      HardcodedRepoPathCount = 0
      RepresentativeProbes = @()
    }
  }

  $probeFiles = @(Get-ChildItem -Path $directoryPath -Filter "*probe.ps1" -File | Sort-Object Name)
  $hardcodedCount = 0
  foreach ($probeFile in $probeFiles) {
    if (Select-String -Path $probeFile.FullName -Pattern [regex]::Escape($hardcodedRepoPath) -Quiet) {
      $hardcodedCount++
    }
  }

  return [pscustomobject]@{
    Directory = $DirectoryName
    Exists = $true
    ProbeCount = $probeFiles.Count
    HardcodedRepoPathCount = $hardcodedCount
    RepresentativeProbes = @($probeFiles | Select-Object -First 3 | ForEach-Object { Get-RepoRelativePath $_.FullName })
  }
}

$suiteResults = foreach ($suite in $gateSuites) {
  $directorySummaries = @($suite.Directories | ForEach-Object { Get-ProbeSummary $_ })
  $missingDirectories = @($directorySummaries | Where-Object { -not $_.Exists } | ForEach-Object { $_.Directory })
  $probeCount = ($directorySummaries | Measure-Object -Property ProbeCount -Sum).Sum
  $hardcodedCount = ($directorySummaries | Measure-Object -Property HardcodedRepoPathCount -Sum).Sum
  $status = if ($missingDirectories.Count -gt 0) {
    "missing-directories"
  } elseif ($hardcodedCount -gt 0) {
    "path-bound"
  } else {
    "portable"
  }

  [pscustomobject]@{
    suite_name = $suite.Name
    phase = $suite.Phase
    status = $status
    directory_count = $directorySummaries.Count
    probe_count = $probeCount
    hardcoded_repo_path_probe_count = $hardcodedCount
    directories = @($directorySummaries | ForEach-Object { $_.Directory })
    missing_directories = $missingDirectories
    representative_probes = @($directorySummaries | ForEach-Object { $_.RepresentativeProbes } | Select-Object -First 6)
    notes = $suite.Notes
  }
}

switch ($Format) {
  "Json" {
    $suiteResults | ConvertTo-Json -Depth 6
  }
  "Markdown" {
    $lines = @(
      "# Headed Probe Inventory",
      "",
      "| Suite | Phase | Status | Directories | Probes | Hardcoded path probes |",
      "| --- | --- | --- | ---: | ---: | ---: |"
    )
    foreach ($suite in $suiteResults) {
      $lines += "| {0} | {1} | {2} | {3} | {4} | {5} |" -f `
        $suite.suite_name, `
        $suite.phase, `
        $suite.status, `
        $suite.directory_count, `
        $suite.probe_count, `
        $suite.hardcoded_repo_path_probe_count
      if ($suite.representative_probes.Count -gt 0) {
        $lines += ""
        $lines += "- `{0}` representative probes: {1}" -f $suite.suite_name, ($suite.representative_probes -join ", ")
      }
      if ($suite.missing_directories.Count -gt 0) {
        $lines += "- missing directories: {0}" -f ($suite.missing_directories -join ", ")
      }
    }
    $lines -join [Environment]::NewLine
  }
  default {
    $suiteResults | Format-Table suite_name, phase, status, directory_count, probe_count, hardcoded_repo_path_probe_count -AutoSize
  }
}
