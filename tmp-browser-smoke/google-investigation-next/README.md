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

## Shared Helper

- `google_style_probe_server.py` serves the matching pages from
  `src/browser/tests/page/` and provides a `/ping` readiness endpoint for the
  Windows scripts.

## Matching Pages

- `headed_google_style_input_probe.html`
- `headed_google_style_input_correction_probe.html`
- `headed_google_style_input_delayed_ready_probe.html`
- `headed_google_enter_order_probe.html`

## Follow-Up Path

After these probes are green, use `scripts/windows/watch_headed_probe.ps1`
against `src/browser/tests/page/google_home_title_probe.html` for the reduced
homepage title stream, then finish with the smallest real headed Google manual
pass that exercises the same interaction path.
