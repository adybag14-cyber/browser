[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$commands = @(
    [pscustomobject]@{
        Step = "1. Re-open the bounded saved-homepage fixture gate"
        Command = ".\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-homepage-fixture"
        Why = "Use this when the reduced homepage title and quick passes are already green and the next question is whether the saved Google homepage fixture still focuses, types, and submits on the real headed surface."
    }
    [pscustomobject]@{
        Step = "2. Fail fast on the homepage-fixture surface"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_homepage_fixture_validation_surface.ps1"
        Why = "Catch renamed helpers or missing probe files before you spend time on the saved-homepage replay."
    }
    [pscustomobject]@{
        Step = "3. Print the homepage-fixture flow"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1"
        Why = "Keep the bounded homepage-fixture commands visible before you run the replay."
    }
    [pscustomobject]@{
        Step = "4. Run the homepage-fixture replay"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1"
        Why = "Re-check the saved Google homepage fixture on the real headed surface before widening to later submit-path helpers."
    }
    [pscustomobject]@{
        Step = "5. Re-open the reduced-home keypress-before-submit bridge"
        Command = ".\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-home-keypress-submit"
        Why = "Use this when the homepage fixture is already green and you want the smallest real-surface proof that submit waits until the keypress stage."
    }
    [pscustomobject]@{
        Step = "6. Fail fast on the reduced-home keypress bridge"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_keypress_submit_validation_surface.ps1"
        Why = "Catch missing bridge helpers before you trust the reduced-home keypress path."
    }
    [pscustomobject]@{
        Step = "7. Print the reduced-home keypress flow"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_keypress_submit_validation_flow.ps1"
        Why = "Keep the bridge from the homepage fixture into the later submit-path wrappers on one printed surface."
    }
    [pscustomobject]@{
        Step = "8. Run the reduced-home keypress bridge"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_keypress_submit_validation.ps1"
        Why = "Prove the reduced-homepage path reaches keypress-before-submit before you widen into the broader submit-path ladder."
    }
    [pscustomobject]@{
        Step = "9. Re-open the broader later submit-path ladder"
        Command = ".\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-submit-path"
        Why = "Use this after the smaller bridge is green or when you need the saved homepage fixture, submit-timing, and shared Enter-order steps printed together again."
    }
    [pscustomobject]@{
        Step = "10. Print the later submit-path flow"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1"
        Why = "Keep the later-stage issue #3 ladder visible before you choose between the one-command runner and the narrower submit-timing or shared Enter-order slices."
    }
    [pscustomobject]@{
        Step = "11. Run the later submit-path ladder"
        Command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1"
        Why = "Advance from the earlier title gates through the saved homepage fixture, submit-timing, and shared Enter-order steps in one bounded pass."
    }
)

Write-Host "Issue #3 mid-phase validation flow"
Write-Host ""
Write-Host "Use this helper when the issue #3 replay is already past the earlier title and quick gates and needs the narrower homepage-fixture plus reduced-home keypress-before-submit bridge before the broader submit-path ladder."
Write-Host ""

foreach ($entry in $commands) {
    Write-Host $entry.Step
    Write-Host ("  {0}" -f $entry.Command)
    Write-Host ("  {0}" -f $entry.Why)
    Write-Host ""
}
