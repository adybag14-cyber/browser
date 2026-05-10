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

## One-Command Runner

Use the Windows helper below when you want the reduced localhost probes, the
bounded homepage probe, and the nearby shared input checks in one ordered pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase all -IncludeSharedInput
```

Add `-IncludeWatch` when you also want the longer interactive watcher on the
same reduced homepage fixture before the smallest live Google manual check.
With `-IncludeSharedInput`, the ordered follow-up now includes the deferred
Enter form-controls pass, the baseline form-controls Enter-submit pass, and the
nearby inline-flow submit probe.

## Saved Localhost Follow-Up

When you want to compare the reduced Google path with attached or saved HTML
pages in the same headed session, pass those pages through the manual handoff:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 `
  -Phase all `
  -IncludeSharedInput `
  -ManualInputPath C:\work\saved-pages
```

If `-ManualInitialPage` is omitted, the staged localhost helper now generates
an `index.html` landing page inside the staged folder and opens that page first,
so a multi-page follow-up can move between the saved HTML targets without
guessing which file was staged first.

## Recommended Order

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run `chrome-google-home-enter-probe.ps1`.
3. Run `deferred-enter-submit-probe.ps1`, `enter-submit-probe.ps1`, and the nearby inline-flow probe when the change touched broader submit or focus behavior.
4. Use `scripts/windows/watch_headed_probe.ps1` only when you need a longer interactive watcher on the same fixture.
5. Use the manual localhost handoff when you need to compare the reduced Google path with attached or saved HTML pages in one staged session.
6. Move on to the smallest live Google manual pass only after the bounded reduced homepage probe is green.
