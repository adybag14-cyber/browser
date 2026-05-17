# Issue #3 Form-Controls Enter-Order Quickstart

Use this quickstart when the current headed Windows work is specifically about
Google-style Enter timing: typed text must become visible, Enter keydown must
reach the page, and submit must wait until the later keypress-backed phase.

This is the smallest shared localhost path for the remaining issue `#3` input
regression before you widen back into attached HTML replay or a live
`https://www.google.com/` retest.

## Fast order

1. Fail fast on missing helpers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_form_controls_validation_surface.ps1
```

2. Print the shared ladder when you want the full bounded order in one place:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_form_controls_validation_flow.ps1
```

3. Run the smallest Google-shaped gates in order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1 -Probe google-title
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1 -Probe reduced-google-home
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation.ps1 -Probe google-enter-order
```

4. Reopen the dedicated shared Enter-order flow when you want the narrower
issue `#3` form-controls handoff printed before execution:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
```

5. Run the dedicated shared Enter-order gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
```

6. Use the trace helper when the remaining failure needs to be classified as
focus, typed-text, keydown, keypress, or submit timing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1
```

7. Move on to live Google only after these localhost gates stay green together.

## What each step proves

- `google-title`: the reduced Google-style page reaches the expected title,
  focus, typed-text, and Enter-submit markers on the real headed surface.
- `reduced-google-home`: the reduced homepage submit path still works before the
  stricter shared timing gate.
- `google-enter-order`: the bounded shared localhost gate confirms submit does
  not win too early.
- `run_google_form_controls_enter_order_validation.ps1`: the dedicated shared
  issue `#3` gate records the stricter keypress-before-submit expectation on the
  headed surface.

## Next widening steps

After the shared form-controls gates are green:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1
```

Use attached-page or saved-page replay only after the bounded form-controls path
is already green for the same change.
