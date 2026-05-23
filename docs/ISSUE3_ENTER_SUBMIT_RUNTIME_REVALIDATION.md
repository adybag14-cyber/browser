# Issue #3 Enter-Submit Runtime Revalidation

Use this note when issue `#3` is narrowed back to the smallest headed runtime slice that still explains why the real Google homepage can focus the search box but fail to commit typed text or submit reliably.

This note is intentionally runtime-first. It keeps the two source files, the exact behavior gap, the focused regression expectations, and the Windows replay route together so the next writable checkout can reopen the fix without rediscovering the same boundary conditions.

Keep these nearby:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/tests/page/google_home_title_probe.html`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

## Goal

Preserve the browser-side distinction between native `keydown`, synthetic `keypress`, and later text-input delivery so headed Win32 input can:

- keep typed text in the focused Google query box
- avoid dropping real later text when stale suppression state is present
- submit the focused form only after the Enter keypress phase, not too early on the native keydown side

## Current runtime gap

The remaining Google failure is not just a missing visual caret. The functional risk sits at the boundary between the Win32 backend and the page runtime:

- `Page.zig` still needs a way to defer native text-input Enter submit until keypress-time DOM behavior has had a chance to run.
- `win32_backend.zig` still needs to suppress only the matching later `text_input` bytes that correspond to a just-handled printable keydown, instead of clearing later real text blindly by counter only.

That pair matters because the Google homepage can react differently from the simpler localhost fixtures even when the broader headed typing baseline already works.

## Target `Page.zig` slice

Reopen the Enter path in `src/browser/Page.zig` with this shape:

- add a small deferred-submit state on `Page`
  - `_defer_native_text_input_enter_submit: bool`
  - `_pending_native_enter_submit: ?*Element.Html.Input`
- add three focused helpers
  - `beginDeferredNativeTextInputEnterSubmit()`
  - `endDeferredNativeTextInputEnterSubmit()`
  - `applyDeferredNativeTextInputEnterSubmit()`
- in the Enter activation path for text-like inputs, queue the focused input when deferred native Enter submit is active instead of calling `submitForm(...)` immediately
- when the deferred submit is later applied, confirm the same input is still focused before submitting its form

## Target `win32_backend.zig` slice

Reopen the Win32 printable-key path in `src/display/win32_backend.zig` with this shape:

- replace the scalar `pending_text_input_suppressions` counter with a queued `std.ArrayListUnmanaged(TextInputEvent)`
- start deferred native Enter submit before the synthetic keypress phase for Enter and end it afterward
- when Enter was allowed, apply the deferred submit after the keypress phase completes
- queue printable-key suppression by exact text bytes instead of by count only
- suppress later `text_input` only when the queued bytes match
- clear stale queued suppressions when later text does not match, so real text is not dropped by an old entry

## Focused regression coverage

Keep the runtime slice small by proving it with the narrower existing tests instead of reopening a broad headed rewrite.

In `src/browser/Page.zig`, keep or add regression coverage for:

- focused reduced Google fixture accepts keyboard text and Enter submit
- reduced Google fixture defers native Enter submit until keypress

In `src/display/win32_backend.zig`, keep or add regression coverage for:

- matching later `text_input` is suppressed after printable keydown across batches
- later real text still lands when stale suppression bytes do not match
- matching text is still suppressed when stale entries drop out of order

## Current live regression anchors

These are the current on-branch anchors worth keeping visible while the runtime slice is reapplied:

- `src/browser/Page.zig` already carries `test "Page reduced Google fixture accepts focused keyboard text and Enter submit"`
- `src/display/win32_backend.zig` already carries `test "win32 dispatchInput suppresses later text_input after printable keydown across batches"`
- the next writable checkout should extend those exact anchors rather than inventing a wider replay surface first

## Windows replay route

Use the normal Windows headed build and then prefer the smaller Google title probe before jumping straight back to the live homepage:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

If the reduced Google fixture is already the chosen replay surface, keep this nearby too:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only jump to the real homepage after the reduced probe shows the keydown, typing, and submit boundary behaving in the right order.

## Expected signals

For the reduced Google probe, the healthy path is:

- printable keydown and keypress land text in the focused query input
- Enter keydown alone does not force an early submit title transition
- the later Enter keypress phase is what allows the submit transition
- later `text_input` remains available when stale suppression bytes do not match

The trace-heavy probe is still useful when the runtime diverges before submit:

- inspect `runtime-input-backend-*.log`
- inspect `wndproc-input-*.log`
- compare the title transition around `KEYDOWN:` versus `SUBMIT:`

## Validation caveats from scheduled reruns

Recent scheduled reruns confirmed that the runtime slice still narrows cleanly, but the fallback Linux validation path has two non-issue-specific traps:

- `zig test src/browser/Page.zig -O Debug` under the attached Zig `0.17.0-dev.299` fallback hits broader module-path and branch/toolchain compatibility errors before the issue-specific assertions run
- `zig test src/display/win32_backend.zig -O Debug` under the same fallback hits the known preexisting Zig 0.17 syntax drift in untouched code (`[_]u16{0} ** ...`) before the focused suppression tests run
- because of that, prefer the normal Windows MSVC build plus the reduced title probe or reduced fixture replay for honest issue-specific validation in this branch state

## Practical rule

Prefer landing this exact runtime slice from a writable checkout of `fork/headed-mode-foundation`.

If the publication path only supports full existing-file replacement, treat this note as the re-entry point and keep the change focused to `Page.zig` plus `win32_backend.zig` until the reduced Google fixture and Win32 suppression tests both agree on the same event ordering.
