param(
    [string]$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path,
    [string]$Zig017GlobalCacheDir = (Join-Path $env:LOCALAPPDATA "zig-lightpanda-017"),
    [switch]$CleanBuildCaches,
    [switch]$CleanDependencyCaches,
    [switch]$CleanSliceOutputs,
    [switch]$CleanSmokeArtifacts,
    [switch]$CleanTempLogs,
    [switch]$CleanZig017Caches,
    [switch]$CleanZig017DebugSymbols,
    [switch]$CleanDefault,
    [int]$ReportTop = 40
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$script:RepoRootFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$script:Zig017GlobalCacheFull = if ($Zig017GlobalCacheDir) {
    [System.IO.Path]::GetFullPath($Zig017GlobalCacheDir).TrimEnd('\', '/')
} else {
    $null
}

function Test-IsPathUnder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Candidate,
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [switch]$AllowRoot
    )

    $full = [System.IO.Path]::GetFullPath($Candidate).TrimEnd('\', '/')
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    if ($AllowRoot -and $full.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $rootWithSep = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    return $full.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-SafeArtifactPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    if (Test-IsPathUnder -Candidate $full -Root $script:RepoRootFull) {
        return
    }

    if ($script:Zig017GlobalCacheFull -and (Test-IsPathUnder -Candidate $full -Root $script:Zig017GlobalCacheFull -AllowRoot)) {
        return
    }

    throw "Refusing to manage artifact outside allowed roots: $full"
}

function Get-RepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    if (-not (Test-IsPathUnder -Candidate $full -Root $script:RepoRootFull -AllowRoot)) {
        return $null
    }
    $relative = $full.Substring($script:RepoRootFull.Length).TrimStart('\', '/')
    return $relative.Replace('\', '/')
}

function Test-GitTrackedContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $relative = Get-RepoRelativePath -Path $Path
    if (-not $relative) {
        return $false
    }

    if ((Test-Path -LiteralPath $Path -PathType Leaf)) {
        $null = & git -C $script:RepoRootFull ls-files --error-unmatch -- $relative 2>$null
        return $LASTEXITCODE -eq 0
    }

    $prefix = $relative.TrimEnd('/') + "/"
    $tracked = @(& git -C $script:RepoRootFull ls-files -- $prefix)
    return $tracked.Count -gt 0
}

function Get-PathSizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [int64]0
    }

    $sum = [int64]0
    foreach ($file in (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue)) {
        $sum += [int64]$file.Length
    }
    return $sum
}

function Get-FileSizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [int64]0
    }

    return [int64](Get-Item -LiteralPath $Path -Force).Length
}

function Format-Size {
    param(
        [Parameter(Mandatory = $true)]
        [int64]$Bytes
    )

    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "{0} B" -f $Bytes
}

function Sum-ArtifactBytes {
    param(
        [AllowEmptyCollection()]
        [object[]]$Items
    )

    [int64]$bytes = 0
    foreach ($item in $Items) {
        $bytes += [int64]$item.SizeBytes
    }
    return $bytes
}

function New-ArtifactRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [bool]$DefaultClean,
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        [Parameter(Mandatory = $true)]
        [ValidateSet("directory", "file")]
        [string]$Kind
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    Assert-SafeArtifactPath -Path $full

    $exists = Test-Path -LiteralPath $full
    $gitTracked = if ($exists) {
        Test-GitTrackedContent -Path $full
    } else {
        $false
    }
    $bytes = if (-not $exists) {
        [int64]0
    } elseif ($Kind -eq "file") {
        Get-FileSizeBytes -Path $full
    } else {
        Get-PathSizeBytes -Path $full
    }

    [pscustomobject]@{
        Path = $full
        Name = if (Test-IsPathUnder -Candidate $full -Root $script:RepoRootFull) {
            $full.Substring($script:RepoRootFull.Length).TrimStart('\', '/')
        } else {
            Split-Path -Path $full -Leaf
        }
        Kind = $Kind
        Category = $Category
        DefaultClean = $DefaultClean
        GitTracked = $gitTracked
        Exists = $exists
        SizeBytes = $bytes
        Size = Format-Size -Bytes $bytes
        Reason = $Reason
    }
}

function Remove-Artifact {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Artifact
    )

    if (-not $Artifact.Exists) {
        return
    }

    if (-not (Test-Path -LiteralPath $Artifact.Path)) {
        return
    }

    Assert-SafeArtifactPath -Path $Artifact.Path
    if (Test-GitTrackedContent -Path $Artifact.Path) {
        Write-Host ("Skipping Git-tracked artifact path {0}" -f $Artifact.Path)
        return
    }

    if ($Artifact.Kind -eq "directory") {
        Remove-Item -LiteralPath $Artifact.Path -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item -LiteralPath $Artifact.Path -Force -ErrorAction SilentlyContinue
    }
}

$script:artifactByPath = @{}

function Add-Artifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [bool]$DefaultClean,
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        [Parameter(Mandatory = $true)]
        [ValidateSet("directory", "file")]
        [string]$Kind
    )

    $record = New-ArtifactRecord -Path $Path -Category $Category -DefaultClean $DefaultClean -Reason $Reason -Kind $Kind
    $key = $record.Path.ToLowerInvariant()
    if (-not $script:artifactByPath.ContainsKey($key)) {
        $script:artifactByPath[$key] = $record
    }
}

function Add-MatchingArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Filter,
        [Parameter(Mandatory = $true)]
        [ValidateSet("directory", "file")]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [bool]$DefaultClean,
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        [switch]$Recurse
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return
    }

    $params = @{
        LiteralPath = $Root
        Force = $true
        ErrorAction = "SilentlyContinue"
    }
    if ($Filter) {
        $params.Filter = $Filter
    }
    if ($Recurse) {
        $params.Recurse = $true
    }
    if ($Kind -eq "directory") {
        $params.Directory = $true
    } else {
        $params.File = $true
    }

    foreach ($item in (Get-ChildItem @params)) {
        Add-Artifact -Path $item.FullName -Category $Category -DefaultClean $DefaultClean -Reason $Reason -Kind $Kind
    }
}

function Get-Zig017DebugSymbolArtifacts {
    $roots = @(
        (Join-Path $RepoRoot ".zig-cache-zig017"),
        $Zig017GlobalCacheDir
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $records = foreach ($root in $roots) {
        foreach ($item in (Get-ChildItem -LiteralPath $root -Filter "*.pdb" -Recurse -Force -File -ErrorAction SilentlyContinue)) {
            New-ArtifactRecord -Path $item.FullName `
                -Category "Zig 0.17 debug symbol" `
                -DefaultClean $true `
                -Reason "MSVC debug symbol emitted into Zig cache. Builds use -Dstrip=true by default on this branch, so old PDBs can be pruned without deleting warm dependency caches." `
                -Kind "file"
        }
    }

    return @($records)
}

$smokeRoot = Join-Path $RepoRoot "tmp-browser-smoke"

Add-Artifact -Path (Join-Path $RepoRoot ".zig-cache") -Category "Build cache" -DefaultClean $true -Reason "Transient Zig local cache. Safe to delete; next build will be cold." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot ".zig-cache-next") -Category "Build cache" -DefaultClean $true -Reason "Alternate transient Zig cache from local slice builds. Safe to delete." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot ".zig-cache-zig017") -Category "Zig 0.17 cache" -DefaultClean $false -Reason "Pinned Zig 0.17 local cache used for warm Windows builds. Keep unless forcing a cold rebuild." -Kind "directory"
Add-Artifact -Path $Zig017GlobalCacheDir -Category "Zig 0.17 cache" -DefaultClean $false -Reason "Pinned Zig 0.17 global cache shared by warm Windows builds. Keep unless forcing a cold rebuild." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot "zig-out") -Category "Primary output" -DefaultClean $false -Reason "Current compiled outputs. Usually keep unless you want a full artifact reset." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot "zig-out-slice") -Category "Slice output" -DefaultClean $true -Reason "Local slice output directory. Regenerated by slice builds." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot "lightpanda-slice.exe") -Category "Slice output" -DefaultClean $true -Reason "Manual local slice binary. Safe to delete if not in use." -Kind "file"
Add-Artifact -Path (Join-Path $RepoRoot "lightpanda-slice.pdb") -Category "Slice output" -DefaultClean $true -Reason "Debug symbols for manual local slice binary." -Kind "file"
Add-Artifact -Path (Join-Path $RepoRoot "lightpanda-slice.lib") -Category "Slice output" -DefaultClean $true -Reason "Import library for manual local slice binary." -Kind "file"
Add-Artifact -Path (Join-Path $smokeRoot "bare-metal-release") -Category "Slice output" -DefaultClean $true -Reason "Packaged bare-metal launch bundle and its smoke artifacts." -Kind "directory"
Add-Artifact -Path (Join-Path $smokeRoot "bare-metal-release.zip") -Category "Slice output" -DefaultClean $true -Reason "Packaged bare-metal release archive." -Kind "file"
Add-Artifact -Path (Join-Path $RepoRoot ".lp-cache") -Category "Dependency cache" -DefaultClean $false -Reason "Bootstrap cache for downloaded tools/dependencies. Deleting is safe but costly to regenerate." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot ".lp-cache-win") -Category "Dependency cache" -DefaultClean $false -Reason "Windows V8/depot_tools cache. Large and expensive to rebuild." -Kind "directory"
Add-Artifact -Path (Join-Path $RepoRoot "build_out.txt") -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc build capture." -Kind "file"
Add-Artifact -Path (Join-Path $RepoRoot "nav_compile.txt") -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc compile capture." -Kind "file"
Add-Artifact -Path (Join-Path $RepoRoot "root.obj") -Category "Temp build output" -DefaultClean $true -Reason "Ad-hoc compiler object output." -Kind "file"

Add-MatchingArtifacts -Root $RepoRoot -Filter ".zig-cache-*" -Kind "directory" -Category "Build cache" -DefaultClean $true -Reason "Ad-hoc Zig cache directory from local experiments. Prefer .zig-cache-zig017 for this branch."
Add-MatchingArtifacts -Root $RepoRoot -Filter ".zig-global-cache-*" -Kind "directory" -Category "Build cache" -DefaultClean $true -Reason "Ad-hoc in-repo Zig global cache directory from local experiments."
Add-MatchingArtifacts -Root $RepoRoot -Filter "zig-out-*" -Kind "directory" -Category "Build output" -DefaultClean $true -Reason "Ad-hoc Zig output directory from local experiments."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.stdout.txt" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc stdout capture."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.stderr.txt" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc stderr capture."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.log" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc runtime log."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.json" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc probe JSON."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.html" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc fetched HTML capture."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-*.patch" -Kind "file" -Category "Temp log" -DefaultClean $true -Reason "Ad-hoc patch capture."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-profile-*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Ad-hoc headed browser profile directory."
Add-MatchingArtifacts -Root $RepoRoot -Filter "tmp-chatgpt-live-profile-*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Ad-hoc headed browser profile directory."

Add-MatchingArtifacts -Root $smokeRoot -Filter "google-investigation*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Old Google smoke investigation directory. Regenerate with scripts/windows/run_google_headed_smoke.ps1."
Add-MatchingArtifacts -Root $smokeRoot -Filter "chrome-live-compare-*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Ad-hoc Chrome parity profile directory from Google smoke comparisons."
Add-MatchingArtifacts -Root $smokeRoot -Filter "chrome-cdp-direct-*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Ad-hoc direct-CDP Chrome parity profile directory from Google smoke comparisons."
Add-Artifact -Path (Join-Path $smokeRoot "google-zig017") -Category "Smoke artifact" -DefaultClean $true -Reason "Bounded Zig 0.17 Google headed smoke output directory." -Kind "directory"
Add-MatchingArtifacts -Root $smokeRoot -Filter "profile-*" -Kind "directory" -Category "Smoke artifact" -DefaultClean $true -Reason "Smoke profile directory; safe to delete between runs." -Recurse
Add-MatchingArtifacts -Root $smokeRoot -Filter "*.png" -Kind "file" -Category "Smoke artifact" -DefaultClean $true -Reason "Smoke screenshot output."
Add-MatchingArtifacts -Root $smokeRoot -Filter "*.bmp" -Kind "file" -Category "Smoke artifact" -DefaultClean $true -Reason "Smoke screenshot output."

$artifacts = @($script:artifactByPath.Values)
$zig017DebugSymbolArtifacts = @(Get-Zig017DebugSymbolArtifacts)

Write-Host "Lightpanda build artifact report"
Write-Host ""

$existingArtifacts = @($artifacts | Where-Object { $_.Exists })
$defaultCleanArtifacts = @($existingArtifacts | Where-Object { $_.DefaultClean -and -not $_.GitTracked })
$totalBytes = Sum-ArtifactBytes -Items $existingArtifacts
$defaultCleanBytes = (Sum-ArtifactBytes -Items $defaultCleanArtifacts) + (Sum-ArtifactBytes -Items $zig017DebugSymbolArtifacts)
Write-Host ("Tracked existing artifacts: {0}; tracked size: {1}; default-clean reclaimable: {2}." -f `
    $existingArtifacts.Count,
    (Format-Size -Bytes ([int64]$totalBytes)),
    (Format-Size -Bytes ([int64]$defaultCleanBytes)))
Write-Host ""

if ($zig017DebugSymbolArtifacts.Count -gt 0) {
    Write-Host ("Zig 0.17 cache debug symbols: {0} file(s), {1} reclaimable with -CleanDefault or -CleanZig017DebugSymbols." -f `
        $zig017DebugSymbolArtifacts.Count,
        (Format-Size -Bytes ([int64](Sum-ArtifactBytes -Items $zig017DebugSymbolArtifacts))))
    Write-Host ""
}

$existingArtifacts |
    Group-Object Category |
    ForEach-Object {
        $categoryBytes = Sum-ArtifactBytes -Items @($_.Group)
        [pscustomobject]@{
            Category = $_.Name
            Count = $_.Count
            Size = Format-Size -Bytes ([int64]$categoryBytes)
            DefaultClean = (@($_.Group | Where-Object { $_.DefaultClean -and -not $_.GitTracked })).Count
            GitTracked = (@($_.Group | Where-Object { $_.GitTracked })).Count
        }
    } |
    Sort-Object Category |
    Format-Table -AutoSize | Out-String -Width 160 |
    Write-Host

$reportSource = if ($ReportTop -gt 0) { $existingArtifacts } else { $artifacts }
$sortedArtifacts = @($reportSource | Sort-Object @{ Expression = "SizeBytes"; Descending = $true }, Name)
$shownArtifacts = if ($ReportTop -gt 0) {
    @($sortedArtifacts | Select-Object -First $ReportTop)
} else {
    $sortedArtifacts
}

$shownArtifacts |
    Select-Object Name,Category,Exists,DefaultClean,GitTracked,Size,Reason |
    Format-Table -AutoSize | Out-String -Width 220 |
    Write-Host

if ($ReportTop -gt 0 -and $sortedArtifacts.Count -gt $shownArtifacts.Count) {
    Write-Host ("Report capped at top {0} artifacts by size; {1} smaller tracked artifact(s) omitted from display. Use -ReportTop 0 to print every row." -f $ReportTop, ($sortedArtifacts.Count - $shownArtifacts.Count))
    Write-Host ""
}

$toRemove = @()
if ($CleanDefault) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.DefaultClean }
    $toRemove += $zig017DebugSymbolArtifacts
}
if ($CleanBuildCaches) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.Category -eq "Build cache" }
}
if ($CleanSliceOutputs) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.Category -eq "Slice output" }
}
if ($CleanDependencyCaches) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.Category -eq "Dependency cache" }
}
if ($CleanSmokeArtifacts) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.Category -eq "Smoke artifact" }
}
if ($CleanTempLogs) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and ($_.Category -eq "Temp log" -or $_.Category -eq "Temp build output") }
}
if ($CleanZig017Caches) {
    $toRemove += $artifacts | Where-Object { $_.Exists -and -not $_.GitTracked -and $_.Category -eq "Zig 0.17 cache" }
}
if ($CleanZig017DebugSymbols) {
    $toRemove += $zig017DebugSymbolArtifacts
}

$toRemove = @($toRemove |
    Sort-Object Path -Unique |
    Sort-Object @{ Expression = { $_.Path.Length }; Descending = $true })

if ($toRemove.Count -eq 0) {
    Write-Host "No cleanup requested. Use -CleanDefault, -CleanBuildCaches, -CleanSmokeArtifacts, -CleanTempLogs, -CleanSliceOutputs, -CleanZig017Caches, -CleanZig017DebugSymbols, and/or -CleanDependencyCaches."
    exit 0
}

$totalBytes = ($toRemove | Measure-Object -Property SizeBytes -Sum).Sum
Write-Host ""
Write-Host ("Deleting {0} artifact(s), reclaiming about {1}." -f $toRemove.Count, (Format-Size -Bytes ([int64]$totalBytes)))

foreach ($artifact in $toRemove) {
    Write-Host ("Removing {0}" -f $artifact.Path)
    Remove-Artifact -Artifact $artifact
}

Write-Host ""
Write-Host "Cleanup complete."
