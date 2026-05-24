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
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
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
- the saved-browser-snapshot restore route has already produced a disposable
  checkout that the live helper surface can target for the next Linux or WSL
  validation pass
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

When the run is using Linux or WSL validation with the saved Memory bundles,
start with the direct runtime surface check and then print the compact re-entry
route before trusting focused Zig output:

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

## Practical Re-entry Order

Use this exact order before reopening the direct runtime patch.

1. Reopen `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md` and confirm the
   target still stays narrowed to `Page.zig` plus `win32_backend.zig`.
2. Print the helper surface when you want the current branch-local runtime
   commands back on one Windows-first path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
```

3. Confirm a writable publication path exists for those two existing files.
4. Re-check the branch-side runtime contract markers before touching the patch:

```bash
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py --self-test
python tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py \
  --page src/browser/Page.zig \
  --win32 src/display/win32_backend.zig
```

5. Stage the expected sibling-path dependencies before blaming source changes:
   - `../zig-v8-fork`
   - `../boringssl-zig`
6. If the run is using saved dependency bundles, stage them before invoking Zig.
7. If the current run does not yet have a reusable checkout beside the
   workspace, print the saved-browser-snapshot route first. Prefer the synced
   helper-surface route when the restored checkout should become its own
   follow-up root because the saved archive can lag the current branch-local
   helper surface:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface
```

8. If the run depends on the saved Memory repo and dependency bundles, run the
   saved-input preflight before the Linux or WSL build-readiness helpers:

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

9. If the run still depends on the saved Memory repo snapshot or dependency
   bundles after the presence preflight, verify the saved-archive route surface
   and checksum path before trusting Linux or WSL follow-up work:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
python scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

10. When the run is using Linux or WSL staging, start with the direct runtime
    Linux or WSL surface and then print the compact re-entry route so the source
    contract check, build-readiness route, and Windows follow-up commands stay on
    one branch-local surface:

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

11. Re-check Linux or WSL build readiness before trusting file-level Zig output:

```bash
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

12. Only after a matching Zig line is actually staged, rerun the readiness helper
    without the Zig skip and then validate the toolchain with the normal project
    build flow before using focused file-level `zig test` as evidence.
13. Only after those gates are green, reopen the direct code patch and the
    focused regression tests.
14. After the focused tests are green, move back to the reduced Google probe and
    then the broader Windows replay ladder.

## Validation Ladder After The Gates Open

Once both gates are green, keep the replay narrow in this order:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1
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
- keep `show_google_issue3_enter_submit_runtime_revalidation.ps1` as the shared
  re-entry surface so the exact runtime route does not need to be rebuilt by hand
- use `show_issue3_saved_browser_snapshot_route.sh` first when the missing piece
  is still the disposable checkout for the next Linux or WSL validation pass
- prefer `show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface`
  when the restored checkout should become its own follow-up root because the
  saved archive can lag the current branch-local helper surface

If the toolchain gate is still closed:

- keep working in build/dependency readiness, docs, or validation routing
- do not treat untouched-source compile failure as a signal that the issue `#3`
  runtime patch regressed
- keep using the saved-memory preflight, the saved-archive integrity route, the
  Linux or WSL direct runtime surface check, the compact direct runtime route,
  the build-readiness surface, the saved-archive Linux route, and the readiness
  helper as the fast preflight set before widening back out to larger replay
  plans

## Working Rule

The direct issue `#3` runtime patch is worth doing only when the run can both:

- publish the real `Page.zig` and `win32_backend.zig` changes safely
- validate those changes with a branch-compatible toolchain and the reduced
  Google replay path

Until then, preserve the narrowed runtime target, use the dedicated runtime
helper to reopen the same branch-local route quickly, use the Linux build-
readiness route when the saved archives must be restaged, use the saved-browser-
snapshot route when the next run still lacks a reusable checkout, prefer the
synced helper-surface restore when the restored checkout should become its own
follow-up root because the saved archive can lag the current branch-local
helper surface, and spend scheduled cycles on smaller slices that improve the
next real re-entry instead of repeating the same blocked attempt.