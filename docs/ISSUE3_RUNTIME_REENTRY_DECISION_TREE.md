# Issue #3 Runtime Re-entry Decision Tree

Use this note when issue `#3` is active again and the next run needs to choose the right first replay path without re-deriving the same headed-mode boundaries.

This decision tree sits between the runtime-first note and the attached-page replay notes. It is for choosing the next route, not for replacing the narrower guides.

Read these first when they are relevant:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Choose the smallest honest next step for the remaining Google headed-input failure on Windows:

- use the runtime-first route when the evidence still points at the Enter-submit and text-input suppression boundary between `Page.zig` and `win32_backend.zig`
- use the attached-page replay route when the browser needs another localhost-first proof pass across the saved compatibility pages before reopening the live Google homepage
- avoid spending a full run rediscovering which path should have gone first

## Known live runtime slice

The current smallest runtime slice is still the two-file boundary captured in `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

The practical behavior target is still the same:

- focused Google-like text input keeps typed text reliably
- stale text-input suppression state does not eat later real text
- Enter submit waits for the keypress-time DOM phase instead of firing too early on native keydown

## Start here

1. If the next run has a writable checkout of `fork/headed-mode-foundation` and a safe way to edit existing files, start with the runtime-first note.
2. If the next run does not have a safe publication path for existing-file updates, do not force `Page.zig` or `win32_backend.zig` edits from a brittle full-body rewrite path.
3. If the next run needs fresh headed proof before touching the runtime files again, start with the attached-page replay route.
4. If the next run only has time for one small progress slice, prefer the route that produces new evidence instead of repeating a previously blocked publish attempt unchanged.

## Choose the runtime-first route when

Use `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` first when most of these are true:

- the reduced Google fixture is already the active replay surface
- the remaining failure still looks like typed text or Enter submit is being lost at the native input boundary
- the last attached-page replay already confirmed the broader localhost route is still wired correctly
- the next environment can run focused Zig tests or a known-good Windows headed replay after editing
- a writable checkout or other trustworthy existing-file publication path is available

Use this runtime-first validation ladder:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only jump back to the live Google homepage after the reduced probe shows the right ordering between keydown, text input, and submit.

## Choose the attached-page replay route when

Use `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md` or `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` first when most of these are true:

- the next run needs to prove the broader headed interaction path on localhost before reopening the real Google homepage
- the current question is still whether issue `#3` is isolated to Google or is part of a wider compatibility regression
- the run does not yet trust the saved attached-page bundle state or wants a fresh fail-fast check on the helper chain
- the runtime edit path is still blocked by missing writable checkout or brittle existing-file publication
- the next useful output is a clearer replay signal, not a speculative code patch

Use this attached-page-first ladder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait
```

Use the attached three-page compatibility bundle when the replay should stay pinned to the known saved pages first.

## Decision rules

Follow these rules in order:

1. Publication path check.
   If existing-file publication is still unsafe, do not spend the run preparing another direct `Page.zig` and `win32_backend.zig` patch that cannot be landed.
2. Evidence freshness check.
   If the last useful signal came from the reduced Google probe, prefer the runtime-first route. If the last useful signal came from older attached-page notes and not from a fresh replay, prefer the attached-page route.
3. Smallest-surface check.
   If the reduced Google probe already isolates the failure, prefer the runtime-first route because it is the smaller surface.
4. Wider-compatibility check.
   If the next question is whether the saved compatibility pages still behave correctly under headed mode, prefer the attached-page route before revisiting the live homepage.
5. No-repeat rule.
   Do not repeat a blocked direct publish attempt or a stale attached-page filename guess without new evidence.

## Practical pairings

Use these pairings to avoid route drift:

- runtime-first route:
  - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
  - `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
  - `src/browser/tests/page/google_home_title_probe.html`
- attached-page replay route:
  - `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
  - `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`
  - `tmp-browser-smoke/attached-pages/README.md`
- wider Windows replay context:
  - `docs/WINDOWS_FULL_USE.md`
  - `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Tracker note

Issue `#3` remains the behavior anchor for the Google headed-input failure, but if that issue thread is still comment-capped, use issue `#2` as the practical progress tracker while keeping this note focused on issue `#3` behavior.

## Practical rule

When the next run begins, make the route choice explicit before opening more files:

- choose runtime-first if the environment can safely land the two-file fix and validate it
- choose attached-page-first if the environment still needs broader localhost proof or still cannot safely publish the runtime files
- switch routes only when a fresh validation result or publication constraint actually changes
