# Google Homepage Fixture Probe

This folder holds the bounded headed Win32 probe for the saved Google homepage
fixture used by the issue `#3` validation stack.

Use it when the smaller localhost probes are already green and the next question
is whether the real headed surface still reaches focus, visible typed text, and
Enter submit on the saved homepage snapshot before you widen into later
submit-timing or live Google follow-up.

## Primary Probe

- `chrome-google-home-input-submit-probe.ps1`
  Serves `src/browser/tests/page/google_home_title_probe.html`, waits for the
  `BOUND|...` title marker, types `n`, and then requires the title to advance
  through a typed state and into `SUBMIT:n|...` after Enter on the real headed
  surface.

## Prefer The Wrapper First

When you want the same fixture check on a stable command surface, start with the
wrapper pair under `scripts/windows/` before dropping down to the raw probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1
```

Use the direct probe in this folder when you want the smallest fixture-only
rerun or when you need to inspect just the saved homepage checkpoint without
replaying the broader issue `#3` stack.

## Recommended Order For Issue #3

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_title_probe.ps1` or `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1` for the narrower real-surface title gate.
3. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1` when the reduced homepage path itself is still the question.
4. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1` or `chrome-google-home-input-submit-probe.ps1` when the saved homepage fixture should prove focus, text visibility, and Enter submit separately.
5. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1` or `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1` when the saved fixture is green and the next question is later submit ordering.
6. Move on to attached-page or live-site follow-up only after the bounded fixture pass stays green.

## Acceptance Edge

Treat this fixture slice as green only when all of these stay true on the real
headed surface:

- the page reaches the `BOUND|...` title marker
- typed text becomes visible in the title markers after input
- Enter advances the marker to `SUBMIT:n|...`

If this probe fails, fix the bounded fixture path before widening back out to
attached HTML, submit-timing, or live Google replay.
