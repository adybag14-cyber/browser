# Issue #11 Linux or WSL Re-entry Route Index

Use this note as the small branch-local index for the lower-volume Linux or WSL
re-entry lane tracked on issue `#11`.

This is the right lane when the direct issue `#3` runtime patch in
`src/browser/Page.zig` plus `src/display/win32_backend.zig` is still blocked on
checkout restore, saved-input trust, Rust or Zig setup, or offline dependency
staging.

## Progress Tracker

Leave start and completion updates on issue `#11` while the work is still in
this lane:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker`

Keep issue `#2` and issue `#3` as historical context, not as the default place
for routine re-entry updates.

## Read First

Read these branch-local notes in this order:

1. `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
2. `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
3. `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
4. `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
5. `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
6. `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
7. `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
8. `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
9. `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
10. `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
11. `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
12. `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`

## Route Order

Use the helper routes in this order, only widening when the current stage is
actually green.

1. Saved Memory inputs:
   `bash ./scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh`
   `bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh`
   `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`

2. Saved archive integrity when the run must trust the exact saved bundles:
   `bash ./scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh`
   `bash ./scripts/linux/show_issue3_saved_archive_integrity_route.sh`
   `python ./scripts/check_issue3_saved_archive_integrity.py --repo-root .`

3. Saved browser snapshot restore when no reusable checkout exists yet:
   `bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
   `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`

4. Restored-checkout re-entry when `../browser-memory-snapshot` already exists
   or was just restored:
   `bash ./scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
   `bash ./scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
   `python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot`

5. Saved Rust toolchain route when host Rust is missing or not the saved branch
   companion:
   `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
   `bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh`

6. Zig toolchain recovery route when the branch still only sees the attached
   Zig `0.17` fallback or staged candidates need a quick `0.15.x` decision:
   `bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
   `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`

7. Zig archive restore route when a real Zig `0.15.x` archive exists but is not
   staged under `../toolchains` yet:
   `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
   `bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only`

8. Offline build inputs route when `../zig-v8-fork`, `../boringssl-zig`, or
   `../offline-deps` still need staging:
   `bash ./scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
   `bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh`

9. Linux build-readiness route once the saved inputs, checkout, Rust, Zig, and
   offline dependency surfaces are lined up:
   `bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
   `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
   `python ./scripts/check_linux_build_readiness.py --repo-root . --expect-saved-archives --expect-offline-deps --require-prebuilt-v8`

10. Windows runtime handoff only after the Linux or WSL environment gates stop
    being the blocker:
    `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1`
    `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1`

## Pick The Next Route By Symptom

- If the run is unsure whether the saved repo snapshot, README, blocker file, or
  dependency bundles are even present, start with the saved-Memory route.
- If the inputs are present but trust in the exact artifacts is still the real
  question, use the saved-archive integrity route next.
- If the archives are trustworthy but there is still no reusable checkout,
  reopen the saved-browser-snapshot route.
- If a restored checkout exists but the next run should prove that checkout
  before wider helpers trust it, use the restored-checkout route.
- If `cargo` or `rustc` are missing, use the saved Rust route.
- If the only visible Zig line is the attached `0.17` fallback, use the Zig
  recovery route before treating Zig failures as source evidence.
- If a real Zig `0.15.x` archive is available but not staged, use the Zig
  archive restore route.
- If sibling dependencies or `../offline-deps` are missing, use the offline
  build-inputs route.
- If all of those surfaces are green, use the Linux build-readiness route and
  then hand back to the narrower Windows runtime route.

## Working Rules

- Do not reopen the direct `Page.zig` plus `win32_backend.zig` patch while the
  blocker is still environment setup.
- Treat the attached `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle
  as surfaced fallback input only, not as honest branch validation evidence.
- Prefer a real Zig `0.15.x` toolchain before trusting focused Linux or WSL Zig
  output on this branch.
- Keep the route compact: once a helper answers the current question, widen to
  the next route instead of rerunning older stages unchanged.
- Use issue `#11` for this lane until the environment gates are actually green
  and the narrower issue `#3` runtime work is ready to resume.
