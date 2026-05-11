# Form Controls Probes

This folder holds the smallest headed Win32 smoke probes for label activation,
text entry, and Enter-submit behavior.

Use `scripts/windows/show_form_controls_validation_flow.ps1` when you want the
read-first handoff for the shared form-controls stack before running the
recommended runner or dropping down to the single-probe scripts.

## Primary Probes

- `label-click-probe.ps1`
  Verifies that clicking the label toggles the paired checkbox on the real
  headed surface.
- `enter-submit-probe.ps1`
  Verifies the basic text-input Enter-submit path against
  `http://127.0.0.1:8154/submit.html`.
- `deferred-enter-submit-probe.ps1`
  Verifies the reduced pending-submit path against
  `http://127.0.0.1:8155/deferred-submit.html` and requires the intermediate
  `Deferred Enter Pending Q` title marker before later submit.
- `chrome-google-home-title-probe.ps1`
  Verifies the bounded reduced Google-style title, focus, typing, and
  keypress-backed submit path against
  `src/browser/tests/page/google_home_title_probe.html` before the fuller
  reduced-home submit and shared Enter-order gates.
- `google-enter-order-probe.ps1`
  Verifies the stricter Google-style Enter path against
  `http://127.0.0.1:8157/google-enter-order.html`, including click focus,
  typed text visibility, and server-side proof that submit happened only after
  the Enter keypress phase reached the page.

## Why The Deferred Probe Matters

The deferred Enter path is the smaller localhost version of the remaining
Google-style submit-timing bug from issue #3. It checks that typed text becomes
visible first, that Enter reaches the pending state, and only then that the
form actually submits.

Pair it with `chrome-google-home-title-probe.ps1` and
`google-enter-order-probe.ps1` when the change specifically reaches
Google-style input timing, because the title probe keeps the smaller bounded
focus-and-submit gate visible and the stricter Enter-order probe proves the
shared headed path did not submit early at keydown.

## Recommended Order For Google-Input Work

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run the bounded reduced Google title pass with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_title_probe.ps1`.
3. Run the reduced headed homepage probe in `tmp-browser-smoke/google-home/`.
4. Print the ordered shared form-controls handoff with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_form_controls_validation_flow.ps1`.
5. Print the dedicated Google-style shared Enter-order handoff with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1` when the next question is specifically whether submit waited until keypress.
6. Print the dedicated trace helper with `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1` when you want the smallest gate's focus, typed-text, keypress, and submit markers translated before or after a rerun.
7. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation_recommended.ps1`, or narrow with `run_google_home_title_probe.ps1`, `deferred-enter-submit-probe.ps1`, `google-enter-order-probe.ps1`, and `enter-submit-probe.ps1` when you already know which shared gate needs attention.
8. Run `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1` when you want only the dedicated Google-style keypress-before-submit gate without rerunning the broader form-controls ladder.
9. Run the nearby inline-flow submit probe when the change also touched broader layout or focus behavior.
10. Move on to the smallest live Google manual pass only after the bounded probes stay green.

## Read-First And One-Command Helpers

Use the helpers below when you want the reduced Google localhost probes, the
bounded title pass, the reduced homepage pass, and these form-controls checks
in one ordered sequence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_form_controls_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_form_controls_validation_recommended.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_title_probe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
```

Use the dedicated Google form-controls wrapper pair when the shared Enter-order
gate is the current question and you want a stable command surface for issue #3
comments, reruns, and manual follow-up notes.
