# Issue #3 Runtime Re-Entry Bridge

Use this note when issue `#3` is already narrowed to the native Enter-submit ordering boundary and the next run should reopen the smallest headed runtime slice before widening back out to attached-page replay or the live Google homepage.

This bridge is intentionally shorter than the broader issue `#3` attached-page notes. Its job is to route future runs back to the exact runtime files, the reduced validation ladder, and the known Linux fallback caveats without rediscovering the same boundary conditions.

Keep these nearby:

- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `src/browser/Page.zig`
- `src/display/win32_backend.zig`
- `tmp-browser-smoke/form-controls/enter-submit-probe.ps1`
- `tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1`
- `src/browser/tests/page/google_home_title_probe.html`

## When To Use This Bridge

Choose this runtime-first route when the current failure looks like one of these:

- the real headed Google search box can focus, but typed text still does not commit reliably
- Enter submit still looks too early or too late relative to the keypress phase
- the reduced Google-shaped field is a better next checkpoint than the broader attached-page replay ladder
- the next source edit is already narrowed to `Page.zig` and `win32_backend.zig`

Do not start here when the current failure is still about bundle completeness, local asset closure, broader localhost routing, or a multi-page compatibility regression. In those cases, reopen the attached-page route first through `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md` or the broader Windows runbook.

## Runtime Boundary

Treat the remaining issue `#3` risk as a boundary between:

- browser-side deferred Enter-submit behavior in `src/browser/Page.zig`
- Win32 printable-key suppression and later `text_input` delivery in `src/display/win32_backend.zig`

The runtime revalidation note is the system of record for the exact target shape:

- defer native Enter submit until the keypress-time DOM path has had a chance to run
- suppress later `text_input` by matching queued bytes instead of a scalar counter only
- keep later real text available when stale suppression state does not match

## Smallest Validation Ladder

Use these steps in order and stop at the first failing rung:

1. Shared form-controls baseline

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1
```

2. Deferred Enter path

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -DeferredEnter
```

3. Reduced Google-shaped Enter ordering

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus
```

4. Reduced Google title probe before live Google

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

Only widen back out to the broader attached-page route or the live homepage after the reduced runtime ladder identifies the first failing boundary honestly.

## Linux Fallback Caveat

Recent scheduled reruns confirmed that the attached Zig `0.17.0-dev.299` fallback is still a poor truth source for this issue-specific runtime slice.

Treat these as branch/toolchain traps first, not as proof that the narrowed issue `#3` logic is wrong:

- `zig test src/browser/Page.zig -O Debug`
- `zig test src/display/win32_backend.zig -O Debug`

The current honest validation route for this runtime slice is still the normal Windows MSVC build plus the reduced Google probe ladder.

## Practical Next Step Rule

If the next writable checkout is available, reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` first and keep the change focused to `src/browser/Page.zig` plus `src/display/win32_backend.zig` until:

- the reduced Google-shaped field accepts text reliably
- Enter waits for the keypress phase before submit
- stale printable-key suppression no longer drops later real text

If the writable checkout is not available yet, use this bridge as the shortest handoff note before switching to the broader attached-page route or another independent lane.