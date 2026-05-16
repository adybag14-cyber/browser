# Issue 3 Mid-Phase Validation Flow

Use this note when issue `#3` is already past the earlier title and quick
headed checks and the next question is whether the saved homepage fixture still
works, whether the reduced-home page still waits until keypress before submit,
or whether the broader later submit-path ladder should be reopened.

This is the narrow bridge between:

- the earlier title and quick issue `#3` gates
- the later submit-path, submit-timing, and shared Enter-order wrappers

## Read-first command surface

Use the printed helper when you want the full mid-phase ladder in one place:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_midphase_validation_flow.ps1
```

## Direct commands

1. Re-open the bounded saved-homepage fixture gate.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-homepage-fixture
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_homepage_fixture_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
```

Use this when the reduced homepage title and quick passes are already green and
the next question is whether the saved Google homepage fixture still focuses,
types, and submits on the real headed surface.

2. Re-open the reduced-home keypress-before-submit bridge.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-home-keypress-submit
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_keypress_submit_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_keypress_submit_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_keypress_submit_validation.ps1
```

Use this when the homepage fixture is already green and you want the smallest
real-surface proof that submit waits until the keypress stage before widening
to later submit-path helpers.

3. Re-open the broader later submit-path ladder.

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-submit-path
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1
```

Use this after the smaller bridge is green or when you need the saved homepage
fixture, submit-timing, and shared Enter-order steps printed together again.

## Routing rule

- If the saved homepage fixture itself is the next uncertainty, start with the
  homepage-fixture gate.
- If the homepage fixture is already green and the next uncertainty is submit
  order, start with the reduced-home keypress bridge.
- If both of those are already green and you want the wider later-stage ladder
  back on screen, reopen `google-submit-path`.
