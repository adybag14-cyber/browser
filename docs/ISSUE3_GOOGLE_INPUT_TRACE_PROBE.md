# Issue #3 Google Input Trace Probe

Use this note when issue `#3` is already narrowed to the live Google headed-input path and you want the smallest branch-tracked repro that captures window-title changes plus the Win32/runtime trace files around click, typing, and Enter.

Keep these nearby:

- `tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1`
- `scripts/windows/show_google_issue3_input_trace_probe.ps1`
- `scripts/windows/check_google_issue3_input_trace_probe_surface.ps1`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`

## Goal

Rerun the existing headed Google trace probe from a live checkout without having to rediscover:

- the exact PowerShell command shape
- which trace artifacts should appear afterward
- how to tell whether the failure stayed in focus, text commit, or Enter submit

## Read-first route

Start with the fail-fast surface check so the note, helper, probe, and shared input helper are all present on the current branch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_input_trace_probe_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_input_trace_probe.ps1
```

If you already know the browser path or want a different query, keep the same surface but pass the overrides through the helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_input_trace_probe.ps1 -BrowserExe '.\zig-out\bin\lightpanda.exe' -SearchText 'lightpanda headed mode'
```

## Direct probe command

The helper above prints this command with the current arguments:

```powershell
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-input-trace-probe.ps1
```

Useful overrides:

- `-BrowserExe` to point at a non-default headed build
- `-Url` to rerun against a different Google surface
- `-SearchText` to keep the typed query obvious in the logs
- `-InputX` and `-InputY` when the browser window size or homepage layout moved
- `-PostLaunchSleepMs`, `-PostTypeSleepMs`, and `-PostEnterSleepMs` when the window or page needs more time

## Expected artifacts

The probe writes its outputs under `tmp-browser-smoke/google-investigation-next/`:

- `google-input-trace.before.png`
- `google-input-trace.browser.stdout.txt`
- `google-input-trace.browser.stderr.txt`
- `browse-render.log`
- `session-wait.log`
- `runtime-renderer.log`
- newest `runtime-input-backend-*.log`
- newest `wndproc-input-*.log`

The probe JSON also reports:

- `title_before`
- `title_after_type`
- `title_after_enter`
- whether the screenshot became ready
- whether the browser window exited cleanly

## How to read the result

Healthy direction:

- click reaches the Google query box
- `title_after_type` reflects typed-text progress instead of staying unchanged
- `title_after_enter` changes only after the Enter phase, not prematurely on keydown
- the runtime and Win32 tails agree on the order of keydown, keypress/text, and submit

Likely failure buckets:

- focus failure: title and input traces barely change after the click
- text commit failure: click lands but `title_after_type` stays flat and later text is missing in the runtime/input logs
- early Enter submit failure: Enter changes state before the expected keypress-time behavior
- stale suppression failure: `runtime-input-backend-*.log` and `wndproc-input-*.log` show mismatched later text handling after printable keydown

## Practical rule

Use this probe before reopening the larger Windows replay ladders when the question is specifically whether live Google still loses typed text or submit behavior on the real headed surface.

If the probe points back to the Enter/text-input boundary, reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and keep the next runtime edit constrained to `src/browser/Page.zig` plus `src/display/win32_backend.zig`.
