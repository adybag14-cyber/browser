# Google Quick And Reduced-Home Validation

Use this note when issue `#3` is already narrowed to the smaller real-surface
Google path and you want the shortest read-first route from the fast title pass
into the reduced homepage Enter-submit proof.

This sits between the broader `docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md` guide
and the later saved-homepage, submit-timing, shared Enter-order, attached-page,
or live-trace ladders.

## When to use it

Use this sequence when all of the following are true:

- the bounded localhost Google-style probes are already green
- you want the fast title-plus-watch pass next
- you want the reduced homepage pass after that without jumping straight into
  the later submit-path or shared Enter-order stacks

Skip straight to `docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md` when the quick
and reduced-home gates are already green and the next question is specifically
keypress-before-submit ordering on the shared headed path.

## Ordered path

1. Fail fast on the quick-validation surface.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_quick_validation_surface.ps1
```

2. Print the quick flow when you want the title-plus-watch steps spelled out.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1
```

3. Run the quick wrapper.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1
```

4. Fail fast on the reduced-home surface before widening to the real homepage
   pass.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_validation_surface.ps1
```

5. Print the reduced-home flow so the quick handoff and the headed homepage
   pass stay in one ordered ladder.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_validation_flow.ps1
```

6. Run the reduced-home wrapper.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
```

## Direct probes

Use the wrappers above by default. Drop to the raw probes only when you need the
exact lower-level script output without the helper layer.

Quick title probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1
```

Reduced-home probe:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-enter-probe.ps1
```

## What green looks like

Quick validation should still prove the smaller title-plus-watch path before you
trust the reduced homepage pass.

Look for these signals:

- the quick surface checker reports the guide, helper, wrapper, watch helper,
  and reduced title probe dependencies are present
- the quick flow helper still prints the title-first then watch handoff
- the quick wrapper still reaches the reduced headed title markers without
  needing the broader homepage pass first

Reduced-home validation should still prove the real-surface Google homepage
checkpoint after the quick ladder is green.

Look for these signals:

- the reduced-home surface checker reports the guide, helper, wrapper, and raw
  probe dependencies are present
- the reduced-home flow helper still prints quick-flow, quick-wrapper,
  reduced-homepage, and raw-probe in that order
- the reduced-home wrapper still reaches the headed homepage title markers for
  focus, typed text, and Enter submit

## What to run next

If the quick and reduced-home gates are green, move on in this order:

1. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1`
2. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1`
3. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1`
4. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1`
5. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1`
6. `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1`

If the quick ladder is green but the reduced-home pass fails, stay on the
reduced-home helper and raw probe before widening to the homepage fixture,
submit-timing, shared Enter-order, or live Google trace steps.
