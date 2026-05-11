Set-StrictMode -Version Latest

function Resolve-LightpandaRepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

function Convert-ToDisplayPath([string]$Path, [string]$RepoRoot) {
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullRoot = [System.IO.Path]::GetFullPath($RepoRoot)
  if ($fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($fullRoot.Length).TrimStart("\\", "/")
  }
  return $fullPath
}

function Format-PowerShellLiteral([string]$Value) {
  return "'" + $Value.Replace("'", "''") + "'"
}

function Add-UniqueString {
  param(
    [Parameter(Mandatory = $true)]
    [System.Collections.Generic.List[string]]$List,
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return
  }

  if (-not $List.Contains($Value)) {
    $List.Add($Value) | Out-Null
  }
}

function Get-AttachedHtmlSearchRoots([string]$RepoRoot) {
  $roots = New-Object System.Collections.Generic.List[string]
  $roots.Add((Join-Path $RepoRoot "user_files"))
  $roots.Add((Join-Path $RepoRoot "agent_files"))

  $repoParent = Split-Path $RepoRoot -Parent
  if (-not [string]::IsNullOrWhiteSpace($repoParent) -and $repoParent -ne $RepoRoot) {
    $roots.Add((Join-Path $repoParent "user_files"))
    $roots.Add((Join-Path $repoParent "agent_files"))
  }

  $currentRoot = (Get-Location).Path
  if (-not [string]::IsNullOrWhiteSpace($currentRoot)) {
    $roots.Add((Join-Path $currentRoot "user_files"))
    $roots.Add((Join-Path $currentRoot "agent_files"))
  }

  return @(
    $roots |
      Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
      Select-Object -Unique
  )
}

function Get-AttachedHtmlCandidates([string]$RepoRoot) {
  $roots = Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot
  $items = @()
  foreach ($root in $roots) {
    $items += Get-ChildItem -LiteralPath $root -Recurse -File |
      Where-Object { $_.Extension -in @(".html", ".htm") } |
      Sort-Object FullName
  }

  return @($items | Group-Object FullName | ForEach-Object { $_.Group[0] })
}

function Get-GoogleStyleFixtureSummary($Fixture) {
  $score = 0
  $pathText = $Fixture.FullName.ToLowerInvariant()
  $reasons = [System.Collections.Generic.List[string]]::new()

  $hasGoogleSearchPathHint = $false
  $hasSearchPathHint = $false
  $hasGenericGooglePathHint = $false
  $hasMarketingPenalty = $false
  $hasGoogleSearchTitle = $false
  $hasGenericGoogleTitle = $false
  $hasQueryInput = $false
  $hasSearchAria = $false
  $hasSearchForm = $false

  if ($pathText -match 'google[-_ ]?(home|search|input|query|submit|probe)') {
    $hasGoogleSearchPathHint = $true
    $score += 6
    $reasons.Add("google-search path") | Out-Null
  } elseif ($pathText -match 'search[-_ ]?(home|input|query|submit|probe|results)') {
    $hasSearchPathHint = $true
    $score += 4
    $reasons.Add("search path") | Out-Null
  } elseif ($pathText -match '\bgoogle\b') {
    $hasGenericGooglePathHint = $true
    $score += 2
    $reasons.Add("google path") | Out-Null
  }

  if ($pathText -match '(safety|privacy|policy|account|support)') {
    $hasMarketingPenalty = $true
    $score -= 4
    $reasons.Add("marketing path penalty") | Out-Null
  }

  try {
    $raw = Get-Content -LiteralPath $Fixture.FullName -Raw -ErrorAction Stop
    $rawLower = $raw.ToLowerInvariant()

    if ($rawLower -match "<title[^>]*>[^<]*google[^<]*(search|home)") {
      $hasGoogleSearchTitle = $true
      $score += 6
      $reasons.Add("google search/home title") | Out-Null
    } elseif ($rawLower -match "<title[^>]*>[^<]*google[^<]*</title>") {
      $hasGenericGoogleTitle = $true
      $score += 2
      $reasons.Add("google title") | Out-Null
    }

    if ($rawLower -match "name\s*=\s*['`"]q['`"]") {
      $hasQueryInput = $true
      $score += 8
      $reasons.Add("query input") | Out-Null
    }
    if ($rawLower -match "aria-label\s*=\s*['`"][^'`"]*search[^'`"]*['`"]") {
      $hasSearchAria = $true
      $score += 2
      $reasons.Add("search aria") | Out-Null
    }
    if ($rawLower -match "<form[^>]+action\s*=\s*['`"][^'`"]*/search" -or
        $rawLower -match "\b(btnk|apjfqb|glfyf|gsfi)\b") {
      $hasSearchForm = $true
      $score += 6
      $reasons.Add("search form markers") | Out-Null
    }

    if ($rawLower -match '(google safety|safety centre|privacy policy|cookie policy)') {
      if (-not $hasMarketingPenalty) {
        $reasons.Add("marketing content penalty") | Out-Null
      }
      $hasMarketingPenalty = $true
      $score -= 6
    }
  } catch {
    return [pscustomobject]@{
      score = $score
      reasons = @($reasons)
      has_query_input = $hasQueryInput
      has_search_form = $hasSearchForm
      has_google_search_title = $hasGoogleSearchTitle
      has_search_aria = $hasSearchAria
      has_marketing_penalty = $hasMarketingPenalty
    }
  }

  return [pscustomobject]@{
    score = $score
    reasons = @($reasons)
    has_query_input = $hasQueryInput
    has_search_form = $hasSearchForm
    has_google_search_title = $hasGoogleSearchTitle
    has_search_aria = $hasSearchAria
    has_marketing_penalty = $hasMarketingPenalty
  }
}

function Get-GoogleStyleFixtureScore($Fixture) {
  return (Get-GoogleStyleFixtureSummary $Fixture).score
}

function Test-GoogleStyleFixture($Fixture) {
  $summary = Get-GoogleStyleFixtureSummary $Fixture
  return ($summary.has_query_input -or $summary.has_search_form -or $summary.has_google_search_title) -and $summary.score -gt 5
}

function Resolve-FixtureSelection {
  param(
    [string]$RepoRoot,
    [string]$InputPath,
    [switch]$GoogleStyle,
    [int]$MaxCount = 3
  )

  $fixtures = @()
  if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    if (-not (Test-Path -LiteralPath $InputPath)) {
      throw "Input path not found: $InputPath"
    }

    $item = Get-Item -LiteralPath $InputPath
    if ($item.PSIsContainer) {
      $fixtures = Get-ChildItem -LiteralPath $item.FullName -Recurse -File |
        Where-Object { $_.Extension -in @(".html", ".htm") } |
        Sort-Object FullName
    } else {
      $fixtures = @($item)
    }
  } else {
    $fixtures = Get-AttachedHtmlCandidates -RepoRoot $RepoRoot
  }

  $fixtures = @($fixtures)
  if (-not $fixtures.Count) {
    return @()
  }

  if ($GoogleStyle) {
    $googleStyleFixtures = @($fixtures | Where-Object { Test-GoogleStyleFixture $_ })
    if ($googleStyleFixtures.Count -gt 0) {
      $fixtures = $googleStyleFixtures
    }

    $fixtures = @(
      $fixtures |
        Sort-Object @(
          @{ Expression = { Get-GoogleStyleFixtureScore $_ }; Descending = $true },
          @{ Expression = { $_.FullName } }
        )
    )
  }

  if ($MaxCount -gt 0 -and $fixtures.Count -gt $MaxCount) {
    $fixtures = $fixtures[0..($MaxCount - 1)]
  }

  return @($fixtures | ForEach-Object { $_.FullName })
}

function Get-DefaultAttachedHtmlInputPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [switch]$GoogleStyle
  )

  $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
  if ($searchRoots.Count -eq 0) {
    throw "attached HTML directories not found under the repo root, its parent workspace, or the current working directory"
  }

  $htmlFiles = @(Resolve-FixtureSelection -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle -MaxCount 0)
  if ($htmlFiles.Count -eq 0) {
    throw "no attached HTML files were found anywhere under $($searchRoots -join '; ')"
  }

  return $htmlFiles
}

function Normalize-AttachedHtmlSelector {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $normalized = ($Path -replace "\\", "/").Trim()
  while ($normalized.StartsWith("./")) {
    $normalized = $normalized.Substring(2)
  }
  return $normalized.TrimStart('/')
}

function Resolve-AttachedPreferredInitialPage {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ResolvedInputPath,
    [Parameter(Mandatory = $true)]
    [string]$PreferredInitialPage
  )

  if (Test-Path -LiteralPath $PreferredInitialPage -PathType Leaf) {
    return (Resolve-Path -LiteralPath $PreferredInitialPage).Path
  }

  $normalizedSelector = Normalize-AttachedHtmlSelector -Path $PreferredInitialPage
  $matches = @(
    $ResolvedInputPath | Where-Object {
      $resolvedPath = $_
      $normalizedResolvedPath = Normalize-AttachedHtmlSelector -Path $resolvedPath
      $leaf = [System.IO.Path]::GetFileName($resolvedPath)

      [string]::Equals($resolvedPath, $PreferredInitialPage, [System.StringComparison]::OrdinalIgnoreCase) -or
      [string]::Equals($leaf, $PreferredInitialPage, [System.StringComparison]::OrdinalIgnoreCase) -or
      [string]::Equals($normalizedResolvedPath, $normalizedSelector, [System.StringComparison]::OrdinalIgnoreCase) -or
      $normalizedResolvedPath.EndsWith("/" + $normalizedSelector, [System.StringComparison]::OrdinalIgnoreCase)
    } | Select-Object -Unique
  )

  if ($matches.Count -eq 1) {
    return $matches[0]
  }
  if ($matches.Count -gt 1) {
    throw "preferred initial page '$PreferredInitialPage' matched multiple attached HTML files. Pass a more specific path. Matches: $($matches -join '; ')"
  }

  throw "preferred initial page '$PreferredInitialPage' was not found in the attached HTML inputs. Pass a full path or a unique attached HTML file name."
}

function Select-GoogleStyleInitialPage {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ResolvedInputPath
  )

  $bestFixture = $null
  $bestScore = [int]::MinValue

  foreach ($path in $ResolvedInputPath) {
    $fixture = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if (-not $fixture) {
      continue
    }

    $summary = Get-GoogleStyleFixtureSummary $fixture
    if (-not (Test-GoogleStyleFixture $fixture)) {
      continue
    }
    $score = $summary.score

    if ($bestFixture -eq $null -or $score -gt $bestScore -or ($score -eq $bestScore -and $fixture.FullName -lt $bestFixture.FullName)) {
      $bestFixture = $fixture
      $bestScore = $score
    }
  }

  if ($bestFixture) {
    return $bestFixture.FullName
  }

  return $null
}

function Convert-ToFixtureArgumentLines {
  param(
    [string[]]$FixturePaths,
    [string]$Indent = "  "
  )

  if (-not $FixturePaths -or -not $FixturePaths.Count) {
    return @()
  }

  $lines = @()
  for ($i = 0; $i -lt $FixturePaths.Count; $i++) {
    $suffix = if ($i -lt ($FixturePaths.Count - 1)) { "," } else { "" }
    $lines += ($Indent + (Format-PowerShellLiteral $FixturePaths[$i]) + $suffix)
  }
  return $lines
}

function Show-FixtureSelectionSummary {
  param(
    [string[]]$FixturePaths,
    [string]$RepoRoot,
    [switch]$GoogleStyle
  )

  if (-not $FixturePaths -or -not $FixturePaths.Count) {
    Write-Output "No attached or saved HTML fixtures were found."
    return
  }

  Write-Output "Selected fixtures:"
  foreach ($fixture in $FixturePaths) {
    $displayPath = Convert-ToDisplayPath -Path $fixture -RepoRoot $RepoRoot
    if ($GoogleStyle) {
      $item = Get-Item -LiteralPath $fixture -ErrorAction SilentlyContinue
      if ($item) {
        $summary = Get-GoogleStyleFixtureSummary $item
        $reasonText = if ($summary.reasons.Count -gt 0) { $summary.reasons -join ", " } else { "no matched hints" }
        Write-Output ("- {0} (score {1}: {2})" -f $displayPath, $summary.score, $reasonText)
        continue
      }
    }

    Write-Output ("- " + $displayPath)
  }
}

function Test-IgnoredLocalAssetReference([string]$Reference) {
  if ([string]::IsNullOrWhiteSpace($Reference)) {
    return $true
  }

  $trimmed = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed)) {
    return $true
  }

  if ($trimmed.StartsWith("#") -or $trimmed.StartsWith("/")) {
    return $true
  }

  if ($trimmed -match '^(?i)([a-z][a-z0-9+.-]*:|//)') {
    return $true
  }

  return $false
}

function Get-LocalReferenceCandidates([string]$Content) {
  $candidates = [System.Collections.Generic.List[string]]::new()
  $patterns = @(
    '\b(?:src|href|poster)\s*=\s*["'']([^"'']+)["'']',
    '\bsrcset\s*=\s*["'']([^"'']+)["'']'
  )

  foreach ($pattern in $patterns) {
    foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
      $value = $match.Groups[1].Value
      if ($pattern -like '*srcset*') {
        foreach ($entry in ($value -split ',')) {
          $srcsetCandidate = ($entry.Trim() -split '\s+')[0]
          if (-not [string]::IsNullOrWhiteSpace($srcsetCandidate)) {
            Add-UniqueString -List $candidates -Value $srcsetCandidate
          }
        }
      } else {
        Add-UniqueString -List $candidates -Value $value
      }
    }
  }

  return @($candidates)
}

function Resolve-LocalFixtureReferencePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FixturePath,
    [Parameter(Mandatory = $true)]
    [string]$Reference
  )

  if (Test-IgnoredLocalAssetReference $Reference) {
    return $null
  }

  $decoded = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
  $relativeReference = (($decoded -split '#', 2)[0] -split '\?', 2)[0]
  if ([string]::IsNullOrWhiteSpace($relativeReference)) {
    return $null
  }

  $fixtureDir = Split-Path -Parent $FixturePath
  $fullFixtureDir = [System.IO.Path]::GetFullPath($fixtureDir).TrimEnd('\', '/')
  $combined = Join-Path $fixtureDir ($relativeReference -replace '/', [System.IO.Path]::DirectorySeparatorChar)
  $resolved = [System.IO.Path]::GetFullPath($combined)
  $directoryPrefix = $fullFixtureDir + [System.IO.Path]::DirectorySeparatorChar
  if (-not $resolved.StartsWith($directoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  $displayPath = ($relativeReference -replace '\\', '/').TrimStart('./')
  return [pscustomobject]@{
    full_path = $resolved
    display_path = $displayPath
  }
}

function Get-MissingLocalFixtureAssets([string]$FixturePath) {
  $content = Get-Content -LiteralPath $FixturePath -Raw
  $missing = [System.Collections.Generic.List[string]]::new()

  foreach ($reference in (Get-LocalReferenceCandidates -Content $content)) {
    $resolved = Resolve-LocalFixtureReferencePath -FixturePath $FixturePath -Reference $reference
    if (-not $resolved) {
      continue
    }

    if (-not (Test-Path -LiteralPath $resolved.full_path)) {
      Add-UniqueString -List $missing -Value $resolved.display_path
    }
  }

  return @($missing)
}

function Get-MissingLocalFixtureAssetAudit {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$FixturePaths
  )

  return @(
    $FixturePaths | ForEach-Object {
      $missing = @(Get-MissingLocalFixtureAssets -FixturePath $_)
      [pscustomobject]@{
        path = $_
        missing_assets = $missing
        missing_asset_count = $missing.Count
      }
    }
  )
}

function Show-MissingLocalFixtureAssetWarnings {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$AssetAudit,
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
  )

  $fixturesWithMissingAssets = @($AssetAudit | Where-Object { $_.missing_asset_count -gt 0 })
  if ($fixturesWithMissingAssets.Count -eq 0) {
    return
  }

  Write-Warning "Some attached HTML files reference sibling local assets that are missing from the current workspace. The localhost-headed follow-up may render or behave differently until those files are restored."
  foreach ($fixture in $fixturesWithMissingAssets) {
    Write-Host ("Missing assets: {0}" -f (Convert-ToDisplayPath -Path $fixture.path -RepoRoot $RepoRoot))
    Write-Host ("  Count: {0}" -f $fixture.missing_asset_count)
    foreach ($asset in ($fixture.missing_assets | Select-Object -First 5)) {
      Write-Host ("  - {0}" -f $asset)
    }
    if ($fixture.missing_asset_count -gt 5) {
      Write-Host ("  - ... {0} more" -f ($fixture.missing_asset_count - 5))
    }
  }
  Write-Host ""
}

function Wait-ValidationPause([switch]$Wait) {
  if ($Wait) {
    [void](Read-Host "Validation command finished. Press Enter to continue")
  }
}
