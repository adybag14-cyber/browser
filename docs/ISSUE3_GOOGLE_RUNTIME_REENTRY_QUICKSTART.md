# Issue #3 Google Runtime Re-entry Quickstart

Use this note when the current issue `#3` replay is no longer blocked on the
attached localhost bundle itself and the next run needs to reopen the smallest
browser-runtime slice that still explains the real Google homepage failure.

This quickstart is intentionally narrow. It does not replace the deeper runtime
note or the broader Windows runbook. It points the next writable checkout back
to the exact files, probes, and validation order that matter once the replay is
already narrowed to the Google input/runtime boundary.

Read these in order:

1. `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
2. `docs/WINDOWS_FULL_USE.md`
3. `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`

If the replay is still on the attached-localhost route rather than the runtime
route, stop here and re-enter through the attached-page guides first:

- `docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md`
- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md`

## When to switch to this quickstart

Use this runtime-first route only after the current run has already narrowed the
failure to the shared Google-shaped input path instead of the saved-page
catalog, sidecar bundle, or broader launcher flow.

Typical signals:

- the attached-page helper route is already green enough to stop blaming the
  localhost bundle
- the reduced Google probe is the next honest failure boundary
- the remaining risk sits between Win32 native input delivery and
  `src/browser/Page.zig`

## Required working assumptions

Before changing code again, make sure the next run has all three of these:

1. A writable checkout or another safe publication path for existing-file edits
   on `fork/headed-mode-foundation`
2. A branch-compatible Zig toolchain or build path for focused validation
3. The current branch copies of `src/browser/Page.zig` and
   `src/display/win32_backend.zig`

Do not treat the attached Zig `0.17.0-dev.299` fallback as proof that the
runtime slice itself is broken. Recent revalidation showed that toolchain fails
in untouched branch files before the focused Enter-submit coverage can finish.

## Exact runtime slice to reopen

Keep the code change focused to these two files:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

The intended behavior boundary is:

- printable text still lands in the focused Google query input
- stale text-input suppression does not swallow later real text
- Enter submit waits until the keypress phase instead of firing too early on
  native keydown

Do not widen into unrelated rendering or shell work while replaying this slice.

## Validation order

Start with the smallest route that still exercises the shared Google-shaped
input path.

1. Confirm the toolchain/build path is usable for this branch.
2. Re-run the reduced Google title probe before widening back out to live
   Google.
3. Only after the reduced probe behaves correctly should the run revisit the
   real homepage.

Recommended commands:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

If the replay is already pinned to the reduced Google fixture, keep this direct
headed launch nearby too:

```powershell
.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1
```

If the reduced probe still diverges before submit, inspect the existing runtime
trace logs before widening the investigation:

- `runtime-input-backend-*.log`
- `wndproc-input-*.log`

## Practical handoff rule

When this runtime slice reopens, start from
`docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`, keep the edit limited to
`Page.zig` plus `win32_backend.zig`, and prove the event ordering on the
reduced Google probe before spending time on the full live homepage again.

That keeps the next writable run anchored to the smallest real headed-mode
boundary instead of rediscovering the same route from scratch.
