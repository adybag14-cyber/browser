# Issue #3 Shared Enter-Order Runtime Bridge

Use this note when issue `#3` is already narrowed to the shared Enter-submit ladder and the next step needs to stay honest about where the failure boundary moves from probe coverage into the real headed runtime.

Keep these nearby:

- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_ROADMAP.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `tmp-browser-smoke/form-controls/enter-submit-probe.ps1`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

## Goal

Move from the smallest shared Enter-order checks toward the live Google failure without losing the exact point where behavior first diverges.

Use this bridge when you need to answer three questions in order:

1. Does the simple headed Enter-submit baseline still work?
2. Does the Google-shaped shared field still wait until keypress before submit?
3. If the shared ladder passes but the reduced Google or live Google path fails, are you now down to the focused `Page.zig` plus `win32_backend.zig` runtime slice?

## Read-First Ladder

Run the shared form-controls probe in this order and stop widening as soon as one rung fails:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
```

Use the default probe to confirm the plain autofocus, type, and Enter-submit path.
Use `-DeferredEnter` after any change that touches delayed submit handling.
Use `-GoogleEnterOrder` when the shared Google-shaped field must prove that submit still waits until the keypress phase.
Use `-GoogleEnterOrder -ClickFocus` when reproducing the closer issue `#3` click-first path before widening to the reduced Google probe or the real homepage.

## What Passing Means

Treat the shared ladder as healthy only when all of these remain true:

- typed text lands in the focused field
- Enter still submits the form successfully
- the Google Enter-order mode reports submit at `keypress`, not `keydown`
- the Google Enter-order mode preserves the focused query field and caret state at submit time

If one of those checks fails inside `enter-submit-probe.ps1`, stay on the shared ladder and fix that first. Do not jump to the reduced Google probe or the live homepage yet.

## When To Escalate

Escalate to the reduced Google probe only after the full shared ladder passes:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

If the reduced Google probe is already the chosen replay surface, keep this direct route nearby too:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only widen to `https://www.google.com/` after the reduced probe shows the same healthy ordering.

## Runtime Re-Entry Rule

If the shared ladder passes but the reduced Google probe or the live homepage still fails, reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` immediately.

At that point, keep the implementation slice focused to:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

That runtime note is the source of truth for the remaining issue `#3` gap:

- defer native text-input Enter submit until the keypress-time DOM behavior has had a chance to run
- suppress later Win32 `text_input` only when the queued bytes actually match the just-handled printable keydown
- avoid clearing later real text because of stale suppression state

## Practical Stop Rule

If the available publication path still cannot safely update large existing files, do not broaden the implementation target beyond `Page.zig` and `win32_backend.zig`.

Use this bridge to keep the probe order honest, then use `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` as the exact runtime handoff until a writable checkout or a safer patch publication path is available.
