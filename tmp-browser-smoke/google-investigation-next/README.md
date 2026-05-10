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
5. `chrome-google-home-input-probe.ps1`
   Launches the real headed browser on `https://www.google.com/`, types a live
   query, presses `Enter`, and captures the Google-specific runtime trace logs
   that the headed input path already emits.

## Shared Helper

- `google_style_probe_server.py` serves the matching pages from
  `src/browser/tests/page/` and provides a `/ping` readiness endpoint for the
  Windows scripts.

## Matching Pages

- `headed_google_style_input_probe.html`
- `headed_google_style_input_correction_probe.html`
- `headed_google_style_input_delayed_ready_probe.html`
- `headed_google_enter_order_probe.html`

## Live Trace Capture Outputs

The live Google probe collects or tails these files when the runtime creates
them:

- `browse-render.log`
- `runtime-renderer.log`
- `session-wait.log`
- `runtime-input-backend-<pid>.log`
- `wndproc-input-<pid>.log`

It intentionally treats typed-text or submit failure as investigation data.
The script exits nonzero only when setup fails, such as when the headed browser
binary is missing or the Win32 window never appears.

## Follow-Up Path

After the reduced localhost probes are green, run
`tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1` for the
bounded real-surface reduced homepage pass. Use
`tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1`
when the real Google homepage still diverges and you need trace evidence from
that exact headed input path. Use `scripts/windows/watch_headed_probe.ps1`
against `src/browser/tests/page/google_home_title_probe.html` only when you need
a longer interactive title stream on that same fixture, then finish with the
smallest real headed Google manual pass that exercises the same interaction
path.
