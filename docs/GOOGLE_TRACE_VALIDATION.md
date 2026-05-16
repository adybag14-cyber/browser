# Google Trace Validation

Use this note when issue `#3` has already cleared the bounded localhost,
reduced homepage, homepage-fixture, submit-timing, and shared Enter-order
gates, and the next question is whether the later reduced-home trace capture or
real Google homepage trace path still exposes a headed input divergence.

This note is intentionally narrower than
`docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md` and
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md`.
It focuses on the later-stage trace handoff that sits after the bounded
submit-path ladder but before another round of engine work on the real Google
homepage path.

## Suite router entry

When you need to re-anchor this later-stage slice inside the shared Windows
validation map before you run anything, start with:

```powershell
.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-live-trace
```

That shared entry prints the live-trace suite purpose, its neighboring
recommended suites, and the dedicated trace flow helper before you narrow into
the later capture commands.

## Start with the validation surface check

Use the dedicated checker first so missing notes, flow helpers, wrapper
commands, or raw trace probes fail fast before you trust a reduced-home or live
Google capture:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_trace_validation_surface.ps1
```

That checker verifies this dedicated note, the broader issue `#3` notes that
route into the trace slice, the Windows runbook, the shared suite router, the
trace flow helper, the dedicated trace runner, the shared wrapper runner, and
the reduced-home plus live trace probes.

## Start with the printed flow

After the surface check is green, print the current command order before you
run the later-stage trace handoff:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1
```

That helper keeps the suite-router reminder, the dedicated surface check, the
reduced-home trace probe, the shared wrapper trace phase, and the raw live
probe on one small command surface before you widen again.

## Read the produced trace artifacts

After any reduced-home or live Google trace run, print the current artifact
surface with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_artifact_guide.ps1
```

That helper keeps the reduced-home browser and server logs, the live-home
browser logs, and the Google-focused runtime trace files on one repeatable
inspection surface before you decide whether to re-run bounded localhost
checkpoints or touch the headed input path.

## One-command trace runner

When you want the dedicated trace surface check and the shared trace phase on
one reusable command surface, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_trace_validation.ps1
```

Use this wrapper when the earlier bounded checkpoints are already green and you
want the later reduced-home plus live Google trace handoff without restating
the shared `-Phase trace` arguments by hand.

## Shared wrapper runner

When you want the reusable live Google trace path on the same command surface
as the earlier issue `#3` phases, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase trace
```

Use the shared wrapper when the earlier bounded checkpoints are already green
and the next question is whether the reduced-home trace or live Google trace
still shows a divergence in focus, typed text, submit ordering, or post-submit
navigation.

## Reduced-home trace first

When you want the real headed surface plus Google-style runtime logs without
jumping straight to the live homepage, start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-enter-trace-probe.ps1
```

## Raw live probe fallback

When you need the exact underlying live Google trace probe without the shared
wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-input-probe.ps1
```

Prefer the dedicated trace runner or shared wrapper unless you specifically need
the raw direct probe outputs from `tmp-browser-smoke\google-investigation-next`.

## What success looks like

Treat the trace handoff as healthy only when all of these remain true:

- the reduced-home trace probe still captures the expected focus, typing, and
  Enter-submit markers on the real headed surface
- the dedicated trace runner still keeps the surface check and shared wrapper on
  one small command surface
- the shared wrapper trace phase still reaches the live Google capture path
  without missing helper or runner wiring
- the raw live probe still remains available for deeper narrowing when the
  shared wrapper points at a real homepage divergence
- the trace artifacts still agree with the closest bounded submit-path,
  submit-timing, and shared Enter-order checkpoints when you compare them

If this slice fails, repair it before treating a reduced-home or live Google
trace as evidence for more engine work.

## When to widen again

After this later trace slice is green:

- print `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_artifact_guide.ps1` so the reduced-home, live-home, and runtime logs stay grouped before comparison
- compare the trace artifacts with the closest bounded submit-path,
  submit-timing, and shared Enter-order phases before editing the headed input
  path
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1` when you need to re-walk the bounded keypress-before-submit slice before another live capture
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` when the next question is whether attached or saved Google-like HTML diverges before the live homepage does

## Working rule

Do not jump straight from a red live homepage capture to core engine edits when
the branch already provides this trace handoff.

Keep the later trace slice green first, then compare it with the nearest
bounded checkpoints before widening back out to more headed input or consent
investigation work.
