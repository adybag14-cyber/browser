# Google Reduced-Home Keypress Validation

Use this note when issue `#3` has already cleared the earliest reduced title and
saved-homepage fixture gates, and the next question is whether the smallest
real-surface Enter path still records keydown before submit on the reduced
Google-style homepage checkpoint.

This guide is intentionally narrower than
`docs/GOOGLE_SUBMIT_PATH_VALIDATION.md`.
It focuses on the one reduced-home checkpoint that now sits between the bounded
saved-homepage fixture wrapper and the broader reduced Enter-trace, submit-
timing, and shared Enter-order ladders.

## Start with the validation surface check

Run the dedicated checker first so missing notes, helper scripts, or the raw
headed probe fail before you trust this smaller gate:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_reduced_home_keypress_validation_surface.ps1
```

That checker verifies this note, the broader submit-path note, the dedicated
flow helper, the wrapper runner, the raw reduced-home keypress probe, and the
shared headed input dependencies the probe still uses.

## Start with the printed flow

After the surface check is green, print the smaller command ladder before you
run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_reduced_home_keypress_validation_flow.ps1
```

That helper keeps the surface check, the dedicated wrapper, the raw reduced-home
keypress probe, and the broader submit-path escalation route aligned on one
small command surface.

## Fastest bounded runner

When you want the narrowest reusable real-surface checkpoint in one command,
run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_reduced_home_keypress_validation.ps1
```

Use the dedicated runner when the saved homepage fixture is already green and
you want one smaller headed checkpoint before reopening the reduced Enter-trace
analysis, submit-timing wrapper, or the shared Enter-order stack.

## Raw probe fallback

When you need the exact underlying probe surface without the wrapper layer, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1
```

Prefer the wrapper unless you specifically need the direct script entrypoint.
The wrapper keeps the common host, timeout, and shared text arguments aligned
with the broader issue `#3` submit-path helpers.

## What success looks like

Treat this reduced-home keypress gate as green only when all of these stay true:

- click focus still lands on the reduced homepage checkpoint
- typed text still appears before Enter ordering becomes relevant
- the reduced-home probe still records `keydown_observed = true`
- the reduced-home probe still records `submit_observed = true`
- the final headed title still advances to the `SUBMIT:<text>` marker only after
  the held Enter keydown state was observed

If one of those markers drops, keep the next replay on this reduced-home gate
before trusting the later reduced Enter-trace, submit-timing, or shared
Enter-order slices.

## Exact evidence to keep

When you need to prove that issue `#3` is still specifically a reduced-home
keypress-before-submit problem, keep the JSON output from the raw probe or quote
these fields in your notes before widening again:

- `focus_worked = true`
- `type_worked = true`
- `keydown_observed = true`
- `submit_observed = true`
- `focus_title` shows the focused input state
- `typed_title` shows `TYPED:<text>`
- `final_title` shows `SUBMIT:<text>` after the held Enter keydown marker was
  observed

Those markers separate three different failure families:

- focus never stabilized on the reduced homepage checkpoint
- typed text dropped before Enter ordering became relevant
- Enter ordering still broke before the later submit-path wrappers even had a
  chance to run

## When to widen again

After this reduced-home keypress gate is green:

- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1` when you want the broader later-stage ladder printed again
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1` when you want the saved-homepage fixture, reduced Enter-trace, submit-timing, and shared Enter-order slices back on one command surface
- use `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1` when the later stages still disagree and you want the quickest explanation of which bounded checkpoint to reopen next

## Working rule

Do not jump from the saved homepage fixture straight to the broader later-stage
submit-path wrappers when the branch now provides this smaller real-surface
checkpoint.

Keep the reduced-home keypress gate green first, then widen back out to the
reduced Enter-trace analysis, submit-timing slice, the shared Enter-order
ladder, attached HTML, or the live headed homepage only as needed.
