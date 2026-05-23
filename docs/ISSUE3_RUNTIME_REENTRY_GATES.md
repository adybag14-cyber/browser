# Issue #3 Runtime Re-entry Gates

Use this note before reopening the direct issue `#3` runtime patch in:

- `src/browser/Page.zig`
- `src/display/win32_backend.zig`

This is the short gate check that sits between the broader production guide and
the runtime-specific revalidation note. Its job is simple: stop the next run
from retrying the same headed Enter-submit patch before the environment is ready
to land and validate it honestly.

Read this together with:

- `docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/WINDOWS_FULL_USE.md`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_linux_build_readiness.py`

## When To Use It

Use this note when all of these are true:

- issue `#3` is already narrowed back to the native keydown/keypress/text-input
  boundary on the real headed Win32 path
- the next intended code change would touch `Page.zig` or
  `win32_backend.zig`
- the current run needs to decide whether it can make the real runtime commit,
  or whether it should stay on a smaller diagnostics, docs, or validation slice

## The Two Hard Gates

Do not reopen the direct runtime patch until both gates are green.

### Gate 1: Writable publication path

The direct issue `#3` runtime fix still lands in two large existing files.
Treat the patch as blocked until at least one of these is true:

- a writable checkout of `fork/headed-mode-foundation` is available
- the current publication path can safely materialize the exact live file bodies,
  apply a small patch, and republish them without manual full-body drift
- the current runtime can publish low-level blob/tree/commit updates from the
  real branch head without rebuilding those files by hand

If none of those is true, do not force the `Page.zig` and `win32_backend.zig`
update from a brittle full-file replacement flow.

### Gate 2: Branch-compatible validation toolchain

The direct issue `#3` runtime slice is not ready to validate just because some
Zig binary exists.

Before retrying the focused tests, make sure the toolchain can actually compile
this branch's current source layout and dependency shape.

Use a branch-compatible Zig toolchain and normal project invocation before
trusting any result from:

```powershell
zig test src/browser/Page.zig
zig test src/display/win32_backend.zig -target x86_64-windows-gnu
```

If a fallback Zig build fails immediately in untouched branch files, import
wiring, or older dependency surfaces, treat that as an environment problem
first, not as proof that the issue `#3` patch itself is wrong.

## Practical Re-entry Order

Use this exact order before reopening the direct runtime patch.

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and confirm the
   target still stays narrowed to `Page.zig` plus `win32_backend.zig`.
2. Confirm a writable publication path exists for those two existing files.
3. Re-check the branch-side runtime contract markers before touching the patch:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \
  --page src/browser/Page.zig \
  --win32 src/display/win32_backend.zig
```

4. Stage the expected sibling-path dependencies before blaming source changes:
   - `../zig-v8-fork`
   - `../boringssl-zig`
5. If the run is using saved dependency bundles, stage them before invoking Zig.
6. Re-check Linux or WSL build readiness before trusting file-level Zig output:

```bash
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

7. Only after a matching Zig line is actually staged, rerun the readiness helper
   without the Zig skip and then validate the toolchain with the normal project
   build flow before using focused file-level `zig test` as evidence.
8. Only after those gates are green, reopen the direct code patch and the
   focused regression tests.
9. After the focused tests are green, move back to the reduced Google probe and
   then the broader Windows replay ladder.

## Validation Ladder After The Gates Open

Once both gates are green, keep the replay narrow in this order:

```powershell
zig build -Dtarget=x86_64-windows-msvc --summary all
powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order
```

Only widen back out to live Google or the attached localhost bundle after the
reduced Google probe and the shared Enter-order ladder agree on the same
keydown/keypress/text-input ordering.

## If A Gate Is Still Closed

If the publication gate is still closed:

- stay on a smaller create-only docs, diagnostics, or validation slice
- do not hand-edit large existing file bodies through a brittle replacement path

If the toolchain gate is still closed:

- keep working in build/dependency readiness, docs, or validation routing
- do not treat untouched-source compile failure as a signal that the issue `#3`
  runtime patch regressed
- keep using the runtime-contract checker and the readiness helper as the fast
  preflight pair before widening back out to larger replay plans

## Working Rule

The direct issue `#3` runtime patch is worth doing only when the run can both:

- publish the real `Page.zig` and `win32_backend.zig` changes safely
- validate those changes with a branch-compatible toolchain and the reduced
  Google replay path

Until then, preserve the narrowed runtime target, but spend scheduled cycles on
smaller slices that improve the next real re-entry instead of repeating the same
blocked attempt.
