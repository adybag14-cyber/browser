# Issue #11 Linux Re-entry Quickstart

Use this note when the Linux or WSL headed-mode re-entry lane is active and the
run needs one compact reminder of the issue `#11` helper order before broader
build-readiness or runtime replay is reopened.

This quickstart keeps the main issue `#11` recovery surfaces together:

- `scripts/linux/show_issue11_linux_reentry_quickstart.sh`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`

## Use It When

Use this quickstart when any of these are true:

- the run needs to reopen issue `#11` rather than the comment-capped issue `#2`
  or issue `#3` threads
- the checkout sits in a nested or restored workspace and the next helper would
  otherwise guess the wrong shared roots by hand
- the saved Memory archives should be trusted before restore or offline staging
- there is still no reusable checkout restored from the saved repo snapshot, or
  a restored checkout should be revalidated before wider Linux or WSL replay
- Linux or WSL build-readiness work is blocked on saved Rust reuse or a
  mismatched Zig line

## Suggested Order

From the browser repo root:

```bash
bash ./scripts/linux/show_issue11_linux_reentry_quickstart.sh
```

That quickstart keeps this compact order visible:

1. Reopen the issue `#11` progress-tracker route.
2. Run the workspace-context helper when the checkout is nested or restored more
   deeply than the default sibling layout.
3. Reopen the saved-archive integrity route before trusting saved inputs.
4. Reopen the synced saved-browser-snapshot route when no reusable checkout
   exists.
5. Reopen the restored-checkout route when a reusable checkout already exists or
   immediately after the synced restore finishes.
6. Reopen the saved-memory route before broader staging or route widening.
7. Reopen the saved Rust route before trusting host `cargo` or `rustc`.
8. Reopen the Linux build-readiness route after the saved inputs are trusted.
9. Run the Zig matching-line gate and reopen the Zig toolchain recovery route
   when the staged Zig line still does not match `build.zig.zon`.

## Working Rules

- Treat issue `#11` as the current status lane for Linux or WSL re-entry work.
- Run the workspace-context helper before rebuilding `memory`, `toolchains`,
  `offline-deps`, or fallback-Zig overrides by hand.
- Prefer the archive-integrity route before restore or offline dependency
  staging when the run depends on saved Memory bundles.
- Prefer the synced saved-browser-snapshot route when no reusable checkout is
  already present beside the workspace.
- Reopen the restored-checkout route before widening back out to broader saved-
  Memory, saved Rust, or Linux build-readiness helpers.
- Reopen the saved-memory route before treating a restored checkout as a trusted
  follow-up root for later issue `#11` work.
- Reopen the saved Rust route before trusting host tooling for Linux or WSL
  build-readiness reruns.
- Reopen the Zig recovery route before treating the attached Zig `0.17` bundle
  as meaningful validation evidence for a branch that still expects Zig `0.15.x`.
- Hand control back to the direct Windows runtime re-entry route only after the
  Linux or WSL environment gates stop being the blocker.
