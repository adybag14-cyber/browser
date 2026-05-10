# Form Controls Probes

This folder holds the smallest headed Win32 smoke probes for label activation,
text entry, and Enter-submit behavior.

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

## Why The Deferred Probe Matters

The deferred Enter path is the smaller localhost version of the remaining
Google-style submit-timing bug from issue #3. It checks that typed text becomes
visible first, that Enter reaches the pending state, and only then that the
form actually submits.

## Recommended Order For Google-Input Work

1. Run the reduced localhost probes in `tmp-browser-smoke/google-investigation-next/`.
2. Run the reduced headed homepage probe in `tmp-browser-smoke/google-home/`.
3. Run `deferred-enter-submit-probe.ps1` and `enter-submit-probe.ps1`.
4. Run the nearby inline-flow submit probe when the change also touched broader layout or focus behavior.
5. Move on to the smallest live Google manual pass only after the bounded probes stay green.

## One-Command Runner

Use the helper below when you want the reduced Google localhost probes, the
bounded homepage pass, and these form-controls checks in one ordered sequence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase all -IncludeSharedInput
```
