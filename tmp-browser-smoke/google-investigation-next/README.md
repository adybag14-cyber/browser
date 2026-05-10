# Google Input Investigation Probes

This folder holds the reduced localhost probes for issue-driven headed Google
search-box work.

Use these as the first bounded gate before the title probe, reduced homepage
probe, bounded submit-timing pass, shared Enter-order wrapper, or the live
`https://www.google.com/` trace path.

## Probe Order

1. `google-style-localhost-probe.ps1`
   Verifies the basic Google-style named-form path still focuses, types `Q`,
   and submits `Q` after focus churn.
2. `google-style-correction-localhost-probe.ps1`
   Verifies multi-character entry, backspace correction, and Enter submit
   survive the same focus churn path.
3. `google-enter-order-localhost-probe.ps1`
   Verifies Enter submission happens only after the keypress-phase mutation is
   visible, which helps distinguish early keydown submit regressions.
4. `google-style-delayed-ready-localhost-probe.ps1`
   Verifies the headed path can wait through a delayed readiness gate before
   typing and submitting.
5. `chrome-google-home-enter-trace-probe.ps1`
   Launches the reduced localhost Google homepage probe, clicks the live query
   box on the real headed Win32 surface, types a query, presses `Enter`, and
   captures the same Google-specific runtime trace logs used for the live-site
   investigation path.
6. `chrome-google-home-input-probe.ps1`
   Launches the real headed browser on `https://www.google.com/`, types a live
   query, presses `Enter`, and captures the Google-specific runtime trace logs
   that the headed input path already emits.

## Shared Helper

- `google_home_server.py` serves the matching pages from
  `src/browser/tests/page/` and provides a `/ping` readiness endpoint for the
  Windows scripts.

## Matching Pages

- `headed_google_style_input_probe.html`
- `headed_google_style_input_correction_probe.html`
- `headed_google_style_input_delayed_ready_probe.html`
- `headed_google_enter_order_probe.html`
- `google_home_title_probe.html`

## Live Trace Capture Outputs

The reduced and live Google trace probes collect or tail these files when the
runtime creates them:

- `browse-render.log`
- `runtime-renderer.log`
- `session-wait.log`
- `runtime-input-backend-<pid>.log`
- `wndproc-input-<pid>.log`

Both probes intentionally treat typed-text, event-order, or submit failure as
investigation data. They exit nonzero only when setup fails or when the reduced
fixture still reproduces the problem they are meant to capture.

## Validation Handoff

After the reduced localhost probes are green, keep the next steps on the shared
runner surface:

1. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1`
   Confirms the bounded title fixture reaches the expected focus and typed-text
   markers through the dedicated wrapper surface.
2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick`
   Runs the fast title-plus-watch first pass.
3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home`
   Exercises the reduced homepage Enter-submit path on the real headed surface.
4. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1`
   Prints the bounded submit-timing wrapper flow before you execute that
   Google-shaped keydown,keypress,submit slice.
5. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing`
   Verifies the bounded Google-shaped keydown, keypress, and submit ordering.
6. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order`
   Rechecks the shared label-click baseline, shared submit gates, and the
   stricter localhost keypress-before-submit wrapper before the manual or live
   Google pass.

Use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1`
when you want the bounded title stack printed as its own read-first handoff
before the wider quick, home, shared, or live Google phases.

Use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1`
when you want the bounded Google-shaped timing stack printed as its own
read-first handoff before the shared Enter-order or live Google phases.

## Follow-Up Path

After the bounded localhost probes are green, run
`tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1` for the
bounded real-surface reduced homepage pass, or use the shared runner commands
above when you want the title, submit-timing, and shared Enter-order steps on
one reusable surface.

Use
`tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1`
when you need the reduced homepage on the real headed surface plus the runtime
trace bundle, then finish with
`tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1`
for the live Google homepage if the reduced page still is not enough.

For the one-shot ordered path, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 \
  -Phase all \
  -IncludeTitleProbe \
  -IncludeSharedEnterOrder \
  -IncludeWatch
```
