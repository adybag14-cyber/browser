# Shared Enter-Order Validation for Google Input

Use this note when issue `#3` has already been narrowed to Enter ordering and
you want the smallest reusable headed Windows path before moving back to the
broader Google homepage flow.

This note is intentionally narrower than `docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md`.
It focuses on the shared Enter-order ladder that sits between the reduced
localhost Google probes and the later manual or live-Google follow-up.

Use `docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md` when you only need
the last shared form-controls end-state proof without printing the wider ladder.

## Start with the validation surface check

Use the dedicated checker first so missing docs, wrapper scripts, or probes fail
before you trust this narrower issue `#3` ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1
```

That checker verifies the shared Enter-order note, the dedicated form-controls
note, the dedicated form-controls surface checker, the shared and dedicated
runners, and the reduced localhost probes that this ladder depends on.

## Start with the printed flow

Use the dedicated flow helper after the surface check when you want the current
command order printed with the active ports and shared text value:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1
```

That helper prints the intended order for:
- the fail-fast shared Enter-order surface check
- the recommended shared Enter-order runner
- the shared-only baseline
- the reduced localhost Google title probe
- the reduced Google homepage keypress probe
- the localhost Enter-order wrapper
- the dedicated shared form-controls surface check
- the dedicated shared form-controls Enter-order gate

## Fastest bounded runner

When you want the whole shared Enter-order stack in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1
```

Use the one-command runner when the earlier reduced Google title or homepage
probes are already green and the next question is whether submit still waits for
keypress across the shared form-controls and inline-flow path.

## Narrowing order

Run the smaller steps in this order when you need to isolate the first failing
gate:

1. Shared baseline only

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared
```

2. Reduced localhost Google title probe

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1
```

3. Reduced homepage keypress-before-submit probe

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1
```

4. Localhost Enter-order wrapper

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1
```

5. Dedicated shared form-controls surface check

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1
```

6. Dedicated shared form-controls Enter-order gate

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
```

Use `docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md` when you want this
last gate broken out as its own read-first step before you widen again.

## What success looks like

Treat the stack as green only when all of these are true:
- the reduced title probe still reaches a `KEYDOWN:<text>|13|13` marker before the final `SUBMIT:<text>` marker
- the reduced homepage keypress probe still shows the Enter keydown edge before the matching submit state
- the localhost Enter-order wrapper still mutates at keypress before submit completes
- the dedicated shared form-controls gate still records submit after keypress on the real headed surface

If one layer fails, fix that layer before widening back out to the saved-page or
live Google pass.

## When to widen again

After the shared Enter-order ladder is green:
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1` when you want the broader localhost-first issue `#3` path again
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` before the attached-page follow-up when the current run already has saved HTML snapshots
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1` only when the bounded phases agree but the real homepage still diverges

## Working rule

Do not treat a live Google pass as the first proof for Enter-order work.
Keep the shared Enter-order ladder green first, then move out to the saved-page,
attached-page, or live-homepage follow-up.
