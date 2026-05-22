# Issue #3 Enter-Submit Runtime Quickstart

Use this note when issue `#3` is already narrowed to the remaining headed
Google Enter-submit/runtime boundary and you want the shortest honest replay
route from the live branch before widening back out to the real homepage.

Start with the branch-local helper surface:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

If branch state may have drifted since the note or helper was last read, fail
fast on the runtime route first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
```

Keep these nearby:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_ROADMAP.md`
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/form-controls/enter-submit-probe.ps1`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/tests/page/google_home_title_probe.html`

## Goal

Preserve the smallest replay ladder that still tells the truth about the
remaining Google headed failure:

- typed text should stay in the focused Google query input
- Enter keydown alone should not force an early submit
- Enter submit should happen only after the later keypress-time DOM phase
- stale queued suppression state should not drop real later `text_input` bytes

## Default sequence

1. Reopen the current helper surface.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

2. Confirm the live branch still has the expected runtime route files.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
```

3. Re-run the shared Enter-order ladder before touching the reduced Google
fixture.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
```

4. Move to the reduced Google probe only after the shared ladder agrees on the
same ordering.

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
python -m http.server 8123 --bind 127.0.0.1
.\zig-out\bin\lightpanda.exe browse --headed --window_width 1366 --window_height 900 "http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
```

5. Widen back out to live Google last.

```powershell
.\zig-out\bin\lightpanda.exe browse --headed --window_width 1366 --window_height 900 "https://www.google.com/"
```

## Focused file-level checks

Use the focused file-level regression commands only when the checkout already
has a branch-compatible Zig toolchain. The attached Zig `0.17.0-dev.299`
fallback can still fail in untouched branch files before these narrower tests
reach the new assertions.

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
```

If those focused Zig commands fail in untouched source before the relevant
assertions execute, fall back to the shared Enter-order ladder and the reduced
Google probe so the runtime boundary can still be narrowed honestly.

## Practical rule

Treat `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` as the runtime design
boundary and this note as the shortest replay order for that same slice.

Read `show_google_issue3_enter_submit_runtime_revalidation.ps1` first when you
want the full Windows-first helper surface. Read this note first when you want
the route in prose with the same command order and success signals visible on
one page.
