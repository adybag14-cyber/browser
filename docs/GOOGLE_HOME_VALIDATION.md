# Reduced Google Homepage Validation

Use this note when issue `#3` has already been narrowed to the reduced headed
homepage checkpoint and you want one read-first guide for that smaller real-
surface gate before widening back out to the saved-homepage, submit-timing, or
shared Enter-order ladders.

This note is intentionally narrower than
`docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md` and
`docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md`.
It focuses on the single reduced homepage headed Windows proof that the Google-
style fixture still reaches focus, visible text, and Enter submit on the real
headed surface.

## Start with the validation surface check

Use the dedicated checker first so missing guides, wrapper scripts, or the raw
headed probe fail before you trust this narrower gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_validation_surface.ps1
```

That checker verifies the main issue `#3` guide, this reduced-homepage note,
the dedicated flow helper, the wrapper runner, the raw reduced-homepage probe,
and the headed fixture files that this smaller gate depends on.

## Start with the printed flow

Use the dedicated helper after the surface check when you want the command
order printed with the active host, port, and input value:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_validation_flow.ps1
```

That helper keeps the reduced-homepage surface check, the narrower quick
handoff, the wrapper runner, and the raw headed probe aligned on one small
command surface.

## Fastest bounded runner

When you want the reduced homepage gate in one command, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1
```

Use the dedicated runner when the earlier localhost and quick/title gates are
already green and the next question is whether the reduced Google homepage
fixture still reaches focus, typed text, and Enter submit on the real headed
Win32 surface.

## Raw probe fallback

When you need the exact underlying probe surface without the wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-enter-probe.ps1
```

Prefer the wrapper unless you specifically need the raw script entrypoint.
The wrapper keeps the common host, timeout, and input arguments aligned with the
broader issue `#3` helpers.

## What success looks like

Treat the reduced homepage gate as green only when all of these remain true:

- the real headed homepage fixture still reaches `FOCUSED`
- typed text still reaches the title stream as `TYPED:QZ` or the chosen input value
- Enter still lands on the real headed surface as `SUBMIT:QZ` or the matching input value
- the same focus, text, and submit expectations still agree with the earlier localhost and quick/title gates when you widen back out

If this gate fails, fix it before widening to the saved homepage fixture,
submit-timing, shared Enter-order, attached HTML, or live Google follow-up.

## When to widen again

After this dedicated gate is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1` when you want the bounded saved-homepage checkpoint printed next
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1` when the next question is keydown, keypress, and submit ordering
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1` when you need the stricter shared Enter-order ladder before manual or live replay
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1` only after the reduced homepage, saved-homepage, and shared ladders are green again and the current run already has Google-like HTML snapshots

## Working rule

Do not use this gate as a substitute for the earlier localhost or quick/title
checks when those phases are still suspect.

Use it as the smallest real-surface homepage proof inside issue `#3`: keep the
dedicated reduced-homepage gate green, then widen back out to the saved
homepage fixture, submit-timing note, shared Enter-order ladder, attached-page
follow-up, or live homepage only as needed.
