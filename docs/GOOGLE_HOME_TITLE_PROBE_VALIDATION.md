# Google Home Title-Probe Validation

Use this note when issue `#3` has already been narrowed to the reduced Google
homepage fixture and you want the smallest headed Windows probe that still
checks click focus, typed text visibility, and Enter-submit ordering on the
Google-shaped title surface before widening back out again.

This note sits between the broader shared Enter-order ladder and the direct
runtime patch note in `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.
It is intentionally narrower than
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md` and
`docs/WINDOWS_FULL_USE.md`.

## Start with the validation surface check

Run the dedicated checker first so missing notes, probe helpers, or the reduced
homepage fixture fail before you trust this narrower gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_title_probe_validation_surface.ps1
```

That check verifies the read-first notes, the shared validation routes, the
runtime revalidation note, the reduced homepage probe, the common headed probe
watcher, the shared Win32 input helpers, and the reduced Google homepage
fixture itself.

## Reconfirm the broader discovery routes

When you are re-entering from the broader issue `#3` workflow instead of
opening this note first, print the shared discovery surfaces before running the
reduced probe:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1
```

Those commands keep the wider shared Enter-order ladder visible so the reduced
title probe stays anchored to the same route future issue `#3` runs already use.

## Read the trace guide first

Use the quick diagnosis helper after the surface check when you want the title
markers translated before or after a rerun:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_title_probe_trace_guide.ps1
```

That helper explains the reduced probe's `helper_outcome`,
`helper_ready_marker`, `helper_typed_marker`, `helper_enter_marker`,
`helper_last_marker`, and trace-tail fields so you can tell quickly whether the
break stayed before the query input was bound, before click focus landed,
before text became visible, during Enter keydown, or before submit completed.

## Fastest bounded runner

When you want the narrowest reusable Google-shaped headed check in one command,
run the reduced probe directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

Use that direct probe when the broader shared form-controls gates are already
green and the next question is whether the reduced Google homepage title probe
still reaches focus, visible text, and Enter-submit on the headed Win32 surface.

## What success looks like

Treat this reduced gate as green only when all of these remain true:

- `helper_outcome = completed`
- `helper_ready_marker` reaches `BOUND`, `FOCUSIN`, or `FOCUSED`
- `helper_typed_marker` starts with `TYPED:`
- `helper_typed_query_value` matches the input text you sent
- `helper_enter_marker` starts with `SUBMIT:`
- `helper_enter_query_value` still matches the same text
- `helper_trace_tail_markers` keeps the typed and submit phases in order

If those do not agree, keep the trace guide nearby before you widen into the
shared Enter-order ladder again.

## Exact evidence to keep

When you need to prove that issue `#3` is still specifically on the reduced
homepage probe boundary, keep or quote these fields from the probe JSON:

- `helper_outcome`
- `helper_failure_stage`
- `helper_ready_marker`
- `helper_typed_marker`
- `helper_typed_query_value`
- `helper_enter_marker`
- `helper_enter_query_value`
- `helper_trace_tail_markers`
- `backend_trace_tails`
- `wndproc_trace_tails`

Those markers separate three different failure families:

- the query input never bound or click focus never landed
- focus landed but typed text did not become visible
- typed text became visible but Enter never reached submit cleanly

## When to widen again

After this reduced title probe is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when you want the wider shared Enter-order ladder printed again
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1` when you want the last shared keypress-before-submit gate back on one command surface
- reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` when the reduced homepage proof points back at the `Page.zig` and `win32_backend.zig` runtime slice

## Working rule

Do not use this reduced title probe as a substitute for the broader shared
Enter-order ladder when the shared form-controls or reduced-home probes are
still suspect.

Use it as the smallest Google-shaped homepage checkpoint inside issue `#3`:
keep this probe green, then widen back out to the shared Enter-order ladder,
the dedicated form-controls gate, or the runtime patch note only as needed.
