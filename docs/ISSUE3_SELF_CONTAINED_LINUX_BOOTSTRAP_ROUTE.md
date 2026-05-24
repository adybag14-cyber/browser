# Issue #3 Self-Contained Linux Bootstrap Route

Use this note when the next issue `#3` replay should restore a reusable checkout
from the saved Memory snapshot and then keep the saved-archive, offline-input,
saved-Rust, and runtime re-entry helpers inside that restored checkout instead
of bouncing between multiple roots.

This route is intentionally narrower than the broader Linux build-readiness
guide. It is the compact handoff for runs that already know the direct runtime
target is still `src/browser/Page.zig` plus `src/display/win32_backend.zig`,
but first need a self-contained checkout that can carry its own helper surface.

Companion helpers:

- `scripts/linux/check_issue3_self_contained_linux_bootstrap_route_surface.sh`
- `scripts/linux/show_issue3_self_contained_linux_bootstrap_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- the saved Memory repo archive is present, but the next Linux or WSL replay
  still needs a reusable checkout that carries the current helper surface
- the broader Linux build-readiness route is still correct, but the next run
  would benefit from one tighter command ladder anchored to the restored
  checkout itself
- the next follow-up wants to stage offline inputs and the saved Rust toolchain
  before reopening the focused runtime route

## Surface Check

From the live helper checkout:

```bash
bash ./scripts/linux/check_issue3_self_contained_linux_bootstrap_route_surface.sh
bash ./scripts/linux/show_issue3_self_contained_linux_bootstrap_route.sh
```

Run the surface check first so missing route files fail before the restore path
widens into archive, dependency, or toolchain diagnosis.

## Suggested Route

From the live helper checkout:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_linux_build_readiness.py --repo-root ../browser-memory-snapshot --skip-zig-check --expect-saved-archives --expect-offline-deps
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Prefer the synced restore path here because the saved repo archive is a stable
historical snapshot and can lag the newer helper surfaces committed on the live
branch.

If the restored checkout already exists and only its helper surface is stale,
refresh that surface in place:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
```

## Working Rules

- Run the restored-checkout readiness check immediately after the synced restore
  so missing helper files fail before deeper archive or dependency preflights.
- Run the saved-Memory and saved-archive integrity checks before trusting any
  Linux or WSL build-readiness output from the restored checkout.
- Reopen the offline-input, saved-Rust, and Zig-line helpers from the restored
  checkout itself so the next run stays anchored to one root.
- Treat the fallback Zig 0.17 dev archive as a surfaced input only; it is not
  honest branch validation evidence for this fork's expected Zig 0.15.x line.
- Once the Linux or WSL gates are green, switch from this bootstrap route to
  `show_issue3_enter_submit_runtime_revalidation_route.sh` before retrying the
  focused `Page.zig` and `win32_backend.zig` slice.
