# Reduced Google Homepage Probe

This folder holds the smallest real-surface headed probe for the reduced Google
homepage fixture.

Use it after the localhost probes in
`tmp-browser-smoke/google-investigation-next/` are green and before the full
live `https://www.google.com/` pass.

## Start with the validation surface check

Use the dedicated checker first so missing guides, helper scripts, or the raw
reduced-homepage probe fail before you trust this smaller issue `#3` gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_validation_surface.ps1
```

That checker verifies the main issue `#3` guide, the dedicated reduced-
homepage note, the reduced-homepage flow helper, the wrapper runner, the raw
probe, and the headed fixture files that this checkpoint depends on.

## Start with the printed flow

Use the dedicated helper after the surface check when you want the current
handoff from the quick/title gate into the reduced homepage pass printed with
the active host, port, and input value:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_validation_flow.ps1
```

That helper keeps the reduced-homepage surface check, the quick handoff, the
wrapper runner, and the raw headed probe aligned on one small command surface.

## Primary probe

- `chrome-google-home-enter-probe.ps1`
  Starts a local static server from the repo root, launches the headed browser
  against `src/browser/tests/page/google_home_title_probe.html`, waits for the
  reduced homepage fixture to report focus, types `QZ`, and then verifies that
  Enter reaches `SUBMIT:QZ` on the real headed surface.

## What it proves

- the reduced homepage fixture becomes focused in a real headed window
- typed text is visible to the page title stream
- Enter submit lands after the typed text is present
- the issue #3 validation path has a bounded real-surface follow-up after the
  reduced localhost probes

## Expected title markers

- `FOCUSED`
- `TYPED:QZ`
- `SUBMIT:QZ`

## Dedicated one-command runner

When you want only the reduced homepage gate in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
```

That runner now starts with the dedicated reduced-homepage surface checker
before it launches the raw probe, so missing helper drift fails fast before the
real-surface pass begins.

## Broader one-command runner

Use the Windows helper below when you want the reduced localhost probes, the
bounded title pass, the bounded homepage probe, the bounded submit-timing
check, the shared Enter-order wrapper, and the watcher in one ordered pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 \
  -Phase all \
  -IncludeTitleProbe \
  -IncludeSharedEnterOrder \
  -IncludeWatch
```

That one-shot path keeps the title probe, reduced homepage pass,
`submit-timing`, shared label-click baseline, shared submit gates, stricter
keypress-before-submit wrapper, and watch phase aligned on the same runner.

## Focused runner steps

Use the shared runner when you want to stay on the current issue `#3` validation
surface instead of calling the probe files one by one:

1. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase title`
   Confirms the bounded title fixture reaches the expected focus and typed-text
   markers.
2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1`
   Runs the fast title-plus-watch first pass through its dedicated helper.
3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1`
   Exercises this reduced homepage Enter-submit path on the real headed
   surface through the dedicated surface-checked wrapper.
4. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing`
   Verifies the bounded Google-shaped keydown, keypress, and submit ordering.
5. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order`
   Rechecks the shared label-click baseline, shared submit gates, and the
   stricter localhost keypress-before-submit wrapper before the manual or live
   Google pass.

## Saved localhost follow-up

When you want to compare the reduced Google path with attached or saved HTML
pages in the same headed session, pass those pages through the manual handoff:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 \
  -Phase all \
  -IncludeTitleProbe \
  -IncludeSharedEnterOrder \
  -IncludeWatch \
  -ManualInputPath C:\work\saved-pages
```

If `-ManualInitialPage` is omitted, the staged localhost helper now generates
an `index.html` landing page inside the staged folder and opens that page first,
so a multi-page follow-up can move between the saved HTML targets without
guessing which file was staged first.

## Recommended order

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1` or `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1`.
3. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_validation_flow.ps1`.
4. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1`.
5. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing`.
6. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order` when the change touched broader submit or focus behavior.
7. Use the manual localhost handoff when you need to compare the reduced Google path with attached or saved HTML pages in one staged session.
8. Move on to the smallest live Google manual pass only after the bounded reduced homepage, submit-timing, and shared Enter-order gates are green.
