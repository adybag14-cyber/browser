# Form-Controls Deferred Enter Validation

Use this when issue `#3` work needs the shared deferred-submit checkpoint
without running the wider Google homepage ladder first.

## Goal

Prove that the headed Win32 form-controls surface:

- shows typed text before Enter submit
- exposes the deferred pending-submit title marker on Enter keydown
- completes submit only after the deferred handoff

## Primary Commands

- `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\deferred-enter-submit-probe.ps1`
- `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\chrome-deferred-enter-submit-probe.ps1`
- `powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter`

## When To Run It

- after changes that touch shared Enter-submit timing
- before widening back out to the Google shared Enter-order ladder
- when the reduced Google homepage is still failing and the next question is
  whether the shared deferred-submit path already regressed locally

## Expected Markers

- typed title: `Deferred Enter Typed <input>`
- pending title: `Deferred Enter Pending <input>`
- submitted title: `Submitted <input>`

If the pending title never appears, the deferred-submit handoff likely broke
before the dedicated Google-style probes even start.
