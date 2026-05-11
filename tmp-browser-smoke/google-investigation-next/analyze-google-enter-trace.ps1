[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$ProbeJsonPath,
  [string]$InputText = "lightpanda",
  [string]$Host = "127.0.0.1",
  [int]$Port = 8164,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250,
  [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

function Get-StateField($State, [string]$Name) {
  if ($null -eq $State) {
    return $null
  }

  $property = $State.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Convert-ToDateTimeOffset([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }
  return [DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Test-ObservedBefore([string]$Left, [string]$Right) {
  $leftTime = Convert-ToDateTimeOffset $Left
  $rightTime = Convert-ToDateTimeOffset $Right
  if ($null -eq $leftTime -or $null -eq $rightTime) {
    return $null
  }
  return $leftTime -le $rightTime
}

function Add-MarkerSummary([System.Collections.Generic.List[object]]$Target, [string]$Phase, $State, [string]$ObservedAtUtc) {
  if ($null -eq $State) {
    return
  }

  $Target.Add([pscustomobject]@{
    phase = $Phase
    observed_at_utc = $ObservedAtUtc
    marker = Get-StateField $State "marker"
    active_element = Get-StateField $State "active_element"
    query_element = Get-StateField $State "query_element"
    query_value = Get-StateField $State "query_value"
    selection = Get-StateField $State "selection"
    last_event = Get-StateField $State "last_event"
  }) | Out-Null
}

function Get-Classification($Probe, [string]$ExpectedInput) {
  if (-not $Probe.ready) {
    return "server_not_ready"
  }
  if (-not $Probe.screenshot_ready) {
    return "window_not_ready"
  }
  if (-not $Probe.focused_worked) {
    return "focus_not_observed"
  }
  if (-not $Probe.typed_worked) {
    return "typed_text_not_observed"
  }
  if ($null -eq $Probe.title_after_keydown_state) {
    return "enter_keydown_missing"
  }
  if ($null -eq $Probe.title_after_keypress_state -and $Probe.submitted_worked) {
    return "submit_before_keypress_or_keypress_missing"
  }
  if ($null -eq $Probe.title_after_keypress_state) {
    return "keypress_missing"
  }
  if (-not $Probe.submitted_worked) {
    return "submit_missing_after_keypress"
  }

  $submitValue = Get-StateField $Probe.title_after_submit_state "query_value"
  if (-not [string]::IsNullOrWhiteSpace($ExpectedInput) -and $submitValue -and $submitValue -ne $ExpectedInput) {
    return "submit_value_mismatch"
  }

  return "enter_sequence_complete"
}

function Get-Recommendation([string]$Classification) {
  switch ($Classification) {
    "server_not_ready" { return "Start with probe setup and localhost server readiness before reopening browser input logic." }
    "window_not_ready" { return "Check headed launch, screenshot creation, and window discovery before input-path debugging." }
    "focus_not_observed" { return "Re-run with trace artifacts and inspect focus delivery before Enter handling." }
    "typed_text_not_observed" { return "Inspect native text delivery and suppression traces before submit sequencing." }
    "enter_keydown_missing" { return "Check whether native Enter is reaching the page at all before revisiting deferred-submit logic." }
    "submit_before_keypress_or_keypress_missing" { return "Compare keydown and submit ordering first; this is the closest match to the deferred Enter-submit bug." }
    "keypress_missing" { return "Inspect keypress synthesis and event ordering between keydown and submit." }
    "submit_missing_after_keypress" { return "Focus on form-submit dispatch after keypress; input text already made it into the field." }
    "submit_value_mismatch" { return "Check whether Enter-side handling is mutating or dropping the query value before submit." }
    default { return "The reduced Google Enter path looks complete; compare against live google.com behavior next." }
  }
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$probeRoot = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$probeScript = Join-Path $probeRoot "chrome-google-home-enter-trace-probe.ps1"

$probeJson = $null
if ($ProbeJsonPath) {
  if (-not (Test-Path -LiteralPath $ProbeJsonPath)) {
    throw "Probe JSON file not found: $ProbeJsonPath"
  }
  $probeJson = Get-Content -LiteralPath $ProbeJsonPath -Raw
} else {
  if (-not (Test-Path -LiteralPath $probeScript)) {
    throw "Google Enter trace probe not found: $probeScript"
  }

  $probeArgs = @{
    RepoRoot = $repo
    Host = $Host
    Port = $Port
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $WindowReadyAttempts
    TitleWaitAttempts = $TitleWaitAttempts
    PollMilliseconds = $PollMilliseconds
  }
  if ($BrowserExe) {
    $probeArgs.BrowserExe = $BrowserExe
  }

  $probeJson = & $probeScript @probeArgs
}

if ([string]::IsNullOrWhiteSpace($probeJson)) {
  throw "Google Enter trace probe did not return JSON output."
}

$probe = $probeJson | ConvertFrom-Json
$markerTimeline = New-Object 'System.Collections.Generic.List[object]'
Add-MarkerSummary $markerTimeline "focus" $probe.title_after_focus_state $probe.focus_observed_at_utc
Add-MarkerSummary $markerTimeline "type" $probe.title_after_type_state $probe.typed_observed_at_utc
Add-MarkerSummary $markerTimeline "keydown" $probe.title_after_keydown_state $probe.keydown_observed_at_utc
Add-MarkerSummary $markerTimeline "keypress" $probe.title_after_keypress_state $probe.keypress_observed_at_utc
Add-MarkerSummary $markerTimeline "doc_keypress" $probe.title_after_doc_keypress_state $probe.doc_keypress_observed_at_utc
Add-MarkerSummary $markerTimeline "submit" $probe.title_after_submit_state $probe.submit_observed_at_utc

$analysisInputText = if ($probe.input_text) { [string]$probe.input_text } else { $InputText }
$typedValue = Get-StateField $probe.title_after_type_state "query_value"
$keydownValue = Get-StateField $probe.title_after_keydown_state "query_value"
$keypressValue = Get-StateField $probe.title_after_keypress_state "query_value"
$submitValue = Get-StateField $probe.title_after_submit_state "query_value"
$classification = Get-Classification $probe $analysisInputText

$analysis = [pscustomobject]@{
  probe_url = $probe.probe_url
  input_text = $analysisInputText
  failure_stage = $probe.failure_stage
  classification = $classification
  recommendation = Get-Recommendation $classification
  focused_worked = $probe.focused_worked
  typed_worked = $probe.typed_worked
  submitted_worked = $probe.submitted_worked
  server_saw_submit = $probe.server_saw_submit
  keydown_observed = $null -ne $probe.title_after_keydown_state
  keypress_observed = $null -ne $probe.title_after_keypress_state
  doc_keypress_observed = $null -ne $probe.title_after_doc_keypress_state
  keydown_before_keypress = Test-ObservedBefore $probe.keydown_observed_at_utc $probe.keypress_observed_at_utc
  keypress_before_submit = Test-ObservedBefore $probe.keypress_observed_at_utc $probe.submit_observed_at_utc
  keydown_before_submit = Test-ObservedBefore $probe.keydown_observed_at_utc $probe.submit_observed_at_utc
  submit_before_keypress = Test-ObservedBefore $probe.submit_observed_at_utc $probe.keypress_observed_at_utc
  typed_value = $typedValue
  keydown_value = $keydownValue
  keypress_value = $keypressValue
  submit_value = $submitValue
  typed_value_matches_input = if ($typedValue) { $typedValue -eq $analysisInputText } else { $null }
  keydown_value_matches_input = if ($keydownValue) { $keydownValue -eq $analysisInputText } else { $null }
  keypress_value_matches_input = if ($keypressValue) { $keypressValue -eq $analysisInputText } else { $null }
  submit_value_matches_input = if ($submitValue) { $submitValue -eq $analysisInputText } else { $null }
  marker_timeline = $markerTimeline
  marker_sequence = @($markerTimeline | ForEach-Object { $_.marker })
  query_value_sequence = @($markerTimeline | ForEach-Object { $_.query_value })
  trace_artifacts = $probe.trace_artifacts
  browser_stdout = $probe.browser_stdout
  browser_stderr = $probe.browser_stderr
  server_stdout = $probe.server_stdout
  server_stderr = $probe.server_stderr
  raw_probe = $probe
}

$json = $analysis | ConvertTo-Json -Depth 8
if ($OutputPath) {
  $json | Set-Content -LiteralPath $OutputPath -Encoding Ascii
}

$json
