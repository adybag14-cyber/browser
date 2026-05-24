# Issue #11 Linux Or WSL Re-entry Tracker Route

Use this route when issue `#11` is the active lane for reopening the blocked
issue `#3` Enter-submit runtime path from Linux or WSL.

This route is the branch-local companion for the GitHub tracker:

- issue `#11`: Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker

Companion helpers:

- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `scripts/check_issue3_saved_snapshot_archive.py`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/show_issue11_linux_reentry_tracker_route.sh`

## Goal

Keep one compact route for the lower-volume issue `#11` lane that:

- reopens the saved-Memory and saved-archive trust checks first
- audits the saved snapshot itself before restore commands widen the replay
- restores or reuses a trustworthy local checkout
- rechecks the restored helper surface before wider replay
- reopens the saved Rust, Zig-line, and offline-input staging helpers in order
- reruns Linux or WSL build-readiness only after those helper surfaces are green
- hands control back to the direct issue `#3` runtime route as soon as the
  environment gate is no longer the blocker

## Run The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue11_linux_reentry_tracker_route.sh
```

Use `--json` when another helper needs the command set as structured output.
Use `--restored-checkout-root` when the reusable checkout lives somewhere other
than `../browser-memory-snapshot`.

## Suggested Order

1. `check_issue3_saved_memory_inputs_route_surface.sh`
2. `show_issue3_saved_memory_inputs_route.sh`
3. `check_issue3_saved_archive_integrity_route_surface.sh`
4. `show_issue3_saved_archive_integrity_route.sh`
5. `python ./scripts/check_issue3_saved_snapshot_archive.py`
6. `check_issue3_saved_browser_snapshot_route_surface.sh`
7. `show_issue3_saved_browser_snapshot_route.sh`
8. `python ./scripts/check_issue3_restored_checkout.py`
9. `check_issue3_saved_rust_toolchain_route_surface.sh`
10. `show_issue3_saved_rust_toolchain_route.sh`
11. `check_issue3_zig_toolchain_recovery_route_surface.sh`
12. `show_issue3_zig_toolchain_recovery_route.sh`
13. `check_issue3_offline_build_inputs_route_surface.sh`
14. `show_issue3_offline_build_inputs_route.sh`
15. `check_issue3_linux_build_readiness_route_surface.sh`
16. `show_issue3_linux_build_readiness_route.sh`
17. `check_issue3_enter_submit_runtime_revalidation_route_surface.sh`
18. `show_issue3_enter_submit_runtime_revalidation_route.sh`

## Working Rules

- Use the saved-Memory and saved-archive helpers before blaming source changes.
- Run `python ./scripts/check_issue3_saved_snapshot_archive.py` after the
  saved-archive integrity route so stale helper-surface drift is caught before a
  restore path is trusted.
- If the snapshot audit reports a historical helper-surface gap, prefer the
  synced restore route before treating the saved archive as a self-contained
  follow-up root.
- If there is no reusable checkout yet, reopen the saved-browser-snapshot route
  before toolchain recovery or offline-input staging.
- If a reusable checkout already exists, run
  `python ./scripts/check_issue3_restored_checkout.py` before widening the route.
- Reopen the saved Rust route before trusting host `cargo` or `rustc`.
- Reopen the Zig recovery route before treating the attached Zig `0.17` dev
  archive as meaningful issue `#3` evidence.
- Reopen the offline-inputs route before raw archive staging commands.
- Reopen the broader Linux or WSL build-readiness route only after the smaller
  helper surfaces agree that the environment is ready.
- Reopen the direct issue `#3` runtime route only after the Linux or WSL lane
  is no longer the blocker.
