# Reduced Google Homepage Probe

This folder holds the smallest real-surface headed probe for the reduced Google
homepage fixture.

Use it after the localhost probes in
`tmp-browser-smoke/google-investigation-next/` are green and before the full
live `https://www.google.com/` pass.

## Primary Probe

- `chrome-google-home-enter-probe.ps1`
  Starts a local static server from the repo root, launches the headed browser
  against `src/browser/tests/page/google_home_title_probe.html`, waits for the
  reduced homepage fixture to report focus, types `QZ`, and then verifies that
  Enter reaches `SUBMIT:QZ` on the real headed surface.

## What It Proves

- the reduced homepage fixture becomes focused in a real headed window
- typed text is visible to the page title stream
- Enter submit lands after the typed text is present
- the issue #3 validation path has a bounded real-surface follow-up after the
  reduced localhost probes

## Expected Title Markers

- `FOCUSED`
- `TYPED:QZ`
- `SUBMIT:QZ`

## Recommended Order

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run `chrome-google-home-enter-probe.ps1`.
3. Use `scripts/windows/watch_headed_probe.ps1` only when you need a longer
   interactive watcher on the same fixture.
4. Move on to the smallest live Google manual pass only after the bounded
   reduced homepage probe is green.
