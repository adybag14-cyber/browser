[CmdletBinding()]
param(
    [switch]$Json,
    [string]$InputText = "Q",
    [string]$Host = "127.0.0.1",
    [int]$LabelPort = 8153,
    [int]$DefaultEnterPort = 8154,
    [int]$DeferredEnterPort = 8155,
    [int]$ReducedGoogleHomePort = 8156,
    [int]$GoogleEnterOrderPort = 8157,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-FlowStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Goal,
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    return [ordered]@{
        name = $Name
        goal = $Goal
        command = $Command
    }
}

$runner = '.\\scripts\\windows\\run_form_controls_validation.ps1'
$commonArguments = @(
    "-Host $Host",
    "-InputText $InputText",
    "-LabelPort $LabelPort",
    "-DefaultEnterPort $DefaultEnterPort",
    "-DeferredEnterPort $DeferredEnterPort",
    "-ReducedGoogleHomePort $ReducedGoogleHomePort",
    "-GoogleEnterOrderPort $GoogleEnterOrderPort",
    "-ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds",
    "-WindowReadyAttempts $WindowReadyAttempts",
    "-TitleWaitAttempts $TitleWaitAttempts",
    "-PollMilliseconds $PollMilliseconds"
)
$commonSuffix = $commonArguments -join ' '

$flow = [ordered]@{
    title = "Shared form-controls headed validation flow"
    focus = "Run the smallest shared label, Enter-submit, reduced Google-home, and keypress-before-submit localhost gates in the right order before broader inline-flow or live Google follow-up."
    input_text = $InputText
    host = $Host
    steps = @(
        (New-FlowStep -Name "label" -Goal "Confirm the shared label-click baseline before any Enter-submit investigation." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe label $commonSuffix"),
        (New-FlowStep -Name "default-enter" -Goal "Check that the immediate shared Enter-submit path still works on the headed surface." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe default-enter $commonSuffix"),
        (New-FlowStep -Name "deferred-enter" -Goal "Check the pending-submit localhost gate that waits through the deferred Enter path." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe deferred-enter $commonSuffix"),
        (New-FlowStep -Name "reduced-google-home" -Goal "Run the reduced Google-home shared submit gate before the stricter Enter-order pass." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe reduced-google-home $commonSuffix"),
        (New-FlowStep -Name "google-enter-order" -Goal "Run the stricter shared keydown, keypress, and submit-order localhost gate." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe google-enter-order $commonSuffix"),
        (New-FlowStep -Name "all" -Goal "Run the whole shared form-controls baseline in one pass when you want the complete localhost gate before broader issue #3 validation." -Command "powershell -ExecutionPolicy Bypass -File $runner -Probe all $commonSuffix")
    )
    next_steps = @(
        "After these shared localhost gates are green, move on to .\\scripts\\windows\\run_google_submit_timing_validation.ps1 or .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1.",
        "Use the shared flow before inline-flow or live Google manual work when the problem still looks like headed input delivery rather than shell navigation."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host $flow.title
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Next steps:"
foreach ($note in $flow.next_steps) {
    Write-Host ("- {0}" -f $note)
}
