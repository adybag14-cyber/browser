# Issue #3 Enter-Submit Patch Replay Checklist

Use this checklist when the branch is ready to reopen the smallest headed runtime fix for the remaining Google search-box failure on Windows.

This note is meant to sit next to `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`.
The revalidation note explains the behavior boundary. This checklist turns that boundary into a branch-local replay sequence that a writable checkout can execute without re-deriving the same two-file plan.

## Scope

Keep the replay limited to these two runtime files:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

Keep these validation helpers nearby:

- `src/browser/tests/page/google_home_title_probe.html`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`

## Replay goal

The replay is only complete when all of these are true:

- printable headed input still lands in the focused Google-style query input
- stale Win32 text-input suppression state no longer drops later real text
- native Enter submit waits until the keypress phase instead of submitting too early on keydown
- the reduced Google fixture still shows the `KEYDOWN:` title before the `SUBMIT:` title transition

## Page.zig checklist

Reopen `src/browser/Page.zig` with this exact shape:

- add `_defer_native_text_input_enter_submit: bool`
- add `_pending_native_enter_submit: ?*Element.Html.Input`
- add `beginDeferredNativeTextInputEnterSubmit()`
- add `endDeferredNativeTextInputEnterSubmit()`
- add `applyDeferredNativeTextInputEnterSubmit()`
- queue the focused text-like input instead of submitting immediately when deferred native Enter submit is active
- when the deferred submit is later applied, confirm the same input is still focused before calling `submitForm(...)`

Keep or re-add the focused reduced-Google tests for:

- reduced Google fixture accepts keyboard text and Enter submit
- reduced Google fixture defers native Enter submit until keypress

## win32_backend.zig checklist

Reopen `src/display/win32_backend.zig` with this exact shape:

- replace the scalar `pending_text_input_suppressions` counter with queued `TextInputEvent` entries
- deinit that queue with the backend
- clear the queue on reset
- begin deferred native Enter submit before the synthetic Enter keypress phase
- end the deferred submit scope after the keypress phase finishes
- apply the deferred submit only when Enter was still allowed
- queue printable-key text suppression by exact bytes instead of by count only
- suppress later `text_input` only when the queued bytes match the later text exactly
- clear stale queued suppression entries when later text does not match, so real input is not swallowed by an old record

Keep or re-add focused Win32 regression tests for:

- matching later `text_input` is suppressed after printable keydown across batches
- later real text still lands when stale suppression bytes do not match
- matching text is still suppressed when stale entries drop out of order

## Validation order

Use this order so failures stay narrow:

1. Rebuild or retest the reduced source-level coverage first.
2. Run the reduced Google title probe before the live homepage.
3. Only jump to `https://www.google.com/` after the reduced probe shows the right event ordering.

## Reduced replay commands

For the Windows headed route, keep the smaller replay first:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

If the reduced fixture is already the active surface, keep this direct route nearby too:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

## Expected probe signals

Treat this as the healthy reduced path:

- typing lands `n` in the focused query input
- Enter keydown alone does not force the submit transition
- the title still shows `KEYDOWN:n|...` before submit
- the later keypress phase is what allows the `SUBMIT:n|...` transition
- stale later text is not lost when suppression bytes do not match

If the path still diverges, compare these logs before widening the replay again:

- `runtime-input-backend-*.log`
- `wndproc-input-*.log`

## Practical stop rule

Do not widen this replay into broader runtime cleanup while the two-file patch is still unpublished.

If the environment still cannot safely publish large existing-file edits, stop after revalidating the two-file patch and keep the handoff anchored on this checklist plus `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` until a writable checkout or safer patch-oriented publication path is available.
