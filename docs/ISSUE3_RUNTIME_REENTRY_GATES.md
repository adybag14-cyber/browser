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
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/WINDOWS_FULL_USE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
- `scripts/linux/show_issue3_saved_archive_integrity_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/linux/show_issue3_windows_runtime_handoff_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
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

8. If the restore route is creating or reusing `../browser-memory-snapshot`, run
   the restored-checkout route surface first and then print the restored-checkout
   helper before the saved-memory preflight or archive-integrity helpers:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh
bash ./scripts/linux/show_issue3_restored_checkout_reentry_route.sh
python scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

9. If the restored checkout should become its own helper root after a synced
   restore or `--sync-only` refresh, run the narrower helper-surface sync and
   issue `#11` helper-contract checks before the broader saved-memory preflight:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_saved_memory_helper_contract.py \
  --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_reentry_inventory_consistency.py \
  --repo-root ../browser-memory-snapshot
```

10. If the run depends on the saved Memory repo and dependency bundles, surface
    the saved-memory route first and then run the saved-input preflight before the
    Linux or WSL build-readiness helpers:

```bash
bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

11. If the run still depends on the saved Memory repo snapshot or dependency
    bundles after the presence preflight, verify the saved-archive route surface
    and checksum path before trusting Linux or WSL follow-up work:

```bash
bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh
bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh
python scripts/check_issue3_saved_archive_integrity.py --repo-root .
```

12. If the next blocker has already narrowed to saved Rust archive choice,
    staged Rust reuse, or the Rust-to-build-readiness bridge, run the saved Rust
    archive-candidates surface first and then print the saved Rust archive and
    build-readiness routes before widening back to the broader Linux or WSL
    ladder:

```bash
bash ./scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
python scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
python scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

13. When the route still depends on the saved Rust archive, run the saved Rust
    surface first and then print the saved Rust toolchain route before host
    `cargo` or `rustc` are treated as meaningful signals:

```bash
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

14. When the route still only sees the attached Zig `0.17` fallback or needs a
    branch-compatible `0.15.x` decision, run the Zig recovery surface first and
    then print the toolchain recovery route before trusting focused Zig output:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

15. If a real Zig `0.15.x` archive is available but not staged yet, fail fast
    on the archive-restore surface before rebuilding the restore command by
    hand:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

16. If the route still needs `../zig-v8-fork`, `../boringssl-zig`, or
    `../offline-deps`, print the offline build-inputs route before dropping to
    the raw archive restore commands:

```bash
bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh
```

17. When the run is using Linux or WSL staging, start with the direct runtime
    Linux or WSL surface and then print the compact re-entry route so the source
    contract check, build-readiness route, and Windows follow-up commands stay on
    one branch-local surface:

```bash
bash ./scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh
```

18. Re-check Linux or WSL build readiness before trusting file-level Zig output:

```bash
python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check
```

19. Only after a matching Zig line is actually staged, rerun the readiness helper
    without the Zig skip and then validate the toolchain with the normal project
    build flow before using focused file-level `zig test` as evidence.
20. Only after those gates are green, reopen the direct code patch and the
    focused regression tests.
21. After the focused tests are green, move back to the reduced Google probe and
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

If Linux or WSL staging has already cleared both gates and the next operator
needs the narrower Windows-only replay ladder back on one surface, print the
compact handoff route first:

```bash
bash ./scripts/linux/show_issue3_windows_runtime_handoff_route.sh
```

Use that handoff after the reduced Google probe when the next step is the
Windows build, reduced fixture, live Google, and trace-inspection ladder on one
compact bridge.

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
- keep the restored-checkout route surface and helper visible between the saved
  snapshot restore and the saved-memory preflight so the next Linux or WSL
  follow-up does not trust an incomplete checkout
- when the restored checkout should become its own helper root, keep the
  restored-helper sync route and the issue `#11` helper-contract checks between
  the restored-checkout route and the broader saved-memory preflight so late-added
  saved-Rust, staged-toolchain, and rerun-route expectations fail fast
- prefer `show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface`
  when the restored checkout should become its own follow-up root because the
  saved archive can lag the current branch-local helper surface

If the toolchain gate is still closed:

- keep working in build/dependency readiness, docs, or validation routing
- do not treat untouched-source compile failure as a signal that the issue `#3`
  runtime patch regressed
- keep using the saved-memory route, the saved-archive integrity route, the
  saved Rust route, the saved Rust archive-candidates route, the saved Rust
  build-readiness route, the staged-Rust candidate helpers, the Zig recovery
  route, the Zig archive-restore surface, the offline build-inputs route, the
  Linux or WSL direct runtime surface check, the compact direct runtime route,
  the build-readiness surface, the saved-archive Linux route, the readiness
  helper, and the build-readiness rerun helper as the fast preflight set before
  widening back out to larger replay plans

## Working Rule

The direct issue `#3` runtime patch is worth doing only when the run can both:

- publish the real `Page.zig` and `win32_backend.zig` changes safely
- validate those changes with a branch-compatible toolchain and the reduced
  Google replay path

Until then, preserve the narrowed runtime target, use the dedicated runtime
helper to reopen the same branch-local route quickly, use the Linux build-
readiness route when the saved archives must be restaged, use the saved-browser-
snapshot route when the next run still lacks a reusable checkout, use the
restored-checkout route when the saved snapshot already exists but the follow-up
root still needs a quick readiness answer, use the restored-helper sync route
and the issue `#11` helper-contract checks before the broader saved-memory
preflight whenever the restored checkout should become its own helper root, use
the saved-memory route before raw presence checks when the helper chain itself
may have drifted, use the saved Rust route, the saved Rust archive-candidates
route, and the saved Rust build-readiness bridge before trusting host toolchains
or widening back to the broader Linux build-readiness ladder, use the Zig
recovery route before trusting fallback Zig output, use the offline build-inputs
route before rebuilding archive-restore commands by hand, prefer the synced
helper-surface restore when the restored checkout should become its own
follow-up root because the saved archive can lag the current branch-local helper
surface, use the Linux-or-WSL-to-Windows handoff route when the gates are green
and the next operator needs the Windows-only replay ladder reopened from a Linux
or WSL staging pass, and spend scheduled cycles on smaller slices that improve
the next real re-entry instead of repeating the same blocked attempt.
