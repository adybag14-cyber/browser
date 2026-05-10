# Google Input Investigation Probes

This folder holds the reduced localhost probes for issue-driven headed Google
search-box work.

Use these before the reduced homepage watcher or the live
`https://www.google.com/` pass.

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

## Follow-Up Path

After the reduced localhost probes are green, run
`tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1` for the
bounded real-surface reduced homepage pass. Use
`tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1`
when you need the reduced homepage on the real headed surface plus the runtime
trace bundle, then finish with
`tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1`
for the live Google homepage if the reduced page still is not enough.
