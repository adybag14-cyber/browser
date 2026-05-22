# Issue #3 Enter-Submit Runtime Bridge

Use this note when issue `#3` is already narrowed to the Win32-to-page Enter-submit boundary and you need the fastest honest route back into the current branch helper surface.

This is the runbook-first companion to `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.
Use the runtime revalidation note for the code-level patch shape in `src/browser/Page.zig` and `src/display/win32_backend.zig`, and use this bridge note when you first need to decide which replay rung to run next.

## Read first

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Helper surface on this branch

Start with the dedicated fail-fast checker and then print the replay helper itself:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

Those two scripts keep the reduced Google title probe, the shared Enter-order ladder, the focused file targets, and the live Google fallback on one smaller surface.

## Replay ladder

Use the helper route in this order when the branch state still matches the narrowed runtime boundary:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed https://www.google.com/
```

Keep the shared form-controls ladder first so you know whether the failure appears before the reduced Google-shaped route widens.
Only jump to the reduced fixture and then the real homepage after the smaller runs agree on the same keydown-versus-keypress ordering.

## Expected signals

Healthy reduced-probe behavior looks like this:

- printable keydown and keypress keep text in the focused query input
- Enter keydown alone does not force an early submit transition
- the later Enter keypress phase is what unlocks submit
- stale queued Win32 suppression entries do not swallow real later `text_input`

If the reduced probe still diverges, inspect these trace files before widening again:

- `tmp-browser-smoke/google-investigation-next/runtime-input-backend-*.log`
- `tmp-browser-smoke/google-investigation-next/wndproc-input-*.log`

Compare the title transition around `KEYDOWN:` versus `SUBMIT:` before reopening the real homepage.

## Practical rule

Treat this bridge note as the quickest way back into the current helper surface.
Treat `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` as the source of truth for the actual `Page.zig` and `win32_backend.zig` patch shape once a writable checkout is available.
