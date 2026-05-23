# Issue #3 Runtime Re-entry Quickstart

Use this note when issue `#3` is already narrowed to the direct headed Enter-submit
runtime boundary in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

This is the shortest branch-local handoff for reopening that work without
rebuilding the route from older notes, validation suites, and helper scripts by
hand.

Keep these nearby:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/windows/show_google_issue3_runtime_reentry_quickstart.ps1`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/windows/show_headed_validation_suites.ps1`

## When To Use It

Use this quickstart when all of these are true:

- the next useful headed-mode work still maps to issue `#3`
- the direct source target is still `Page.zig` plus `win32_backend.zig`
- the current run needs a fast answer about whether it should reopen the direct
  runtime patch or stay on a smaller validation, docs, or diagnostics slice

Do not use this quickstart when the run is still mainly about:

- attached localhost page bundle routing
- broader navigation or rendering replay
- build recovery that has not yet reached the issue `#3` runtime boundary

## One-Screen Route

Run the compact helper first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runtime_reentry_quickstart.ps1
```

That helper keeps this reduced route together:

1. fail fast on missing runtime notes, helper scripts, or reduced Google replay surfaces
2. reopen the full runtime helper output on one Windows-first command surface
3. prove the source-based runtime contract checker still distinguishes guarded and vulnerable samples
4. check the live branch for the expected `Page.zig` and `win32_backend.zig` runtime markers
5. reopen the shared Enter-order ladders before widening back out to reduced Google replay
6. confirm Linux or WSL build readiness before trusting focused Zig output
7. use the reduced Google probe before live Google

## Fast Replay Order

Use this order when the runtime path is the real next question:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runtime_reentry_quickstart.ps1
python .\tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py --self-test
python .\tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py --page .\src\browser\Page.zig --win32 .\src\display\win32_backend.zig
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
python .\scripts\check_linux_build_readiness.py --repo-root . --skip-zig-check
```

Only after those stay aligned should the run widen into:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
```

Only after the reduced Google title probe agrees with the shared Enter-order
ladder should the run jump back to live Google or the direct runtime patch.

## Stop Conditions

Stay off the direct `Page.zig` and `win32_backend.zig` edit when any of these
is still true:

- the runtime surface check fails
- the source-based runtime contract check fails unexpectedly and the live branch
  is no longer carrying the narrowed markers you expected
- the current publication path still cannot safely land changes to large
  existing files
- the available Zig line still fails in untouched branch files before the
  issue-specific assertions run

When one of those stays red, keep the run on smaller create-only validation,
docs, or diagnostics work instead of retrying the same blocked runtime edit.

## Working Rule

Use this quickstart as the shortest re-entry bridge into the direct issue `#3`
runtime slice.

Use `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` for the hard go or no-go decision.
Use `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` for the exact code and
regression target once both gates are green.
