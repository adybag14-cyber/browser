# Issue #3 Re-entry Stack Route

Use this note when a Linux or WSL follow-up run needs the full saved-snapshot
recovery ladder back on one compact surface before reopening the blocked issue
`#3` Enter-submit runtime lane.

This route is for a common scheduled-run problem: the branch already has several
good smaller helpers, but the next run still loses time hopping between restore,
restored-checkout, archive-integrity, offline-dependency, saved-Rust, Zig-line,
build-readiness, and direct-runtime notes by hand.

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/check_issue3_reentry_stack_surface.sh`
- `scripts/linux/show_issue3_reentry_stack.sh`

## When To Use It

Use this route when all of these are true:

- the direct issue `#3` runtime patch is still blocked on environment or
  publication readiness rather than on a newly narrowed source diff
- the current run depends on the saved Memory repo snapshot, saved dependency
  bundles, or both
- the next step would benefit from printing the whole recovery order instead of
  reopening each smaller helper individually

## Practical Order

1. Run the stack surface check first:

```bash
bash ./scripts/linux/check_issue3_reentry_stack_surface.sh
```

2. Print the compact stack route:

```bash
bash ./scripts/linux/show_issue3_reentry_stack.sh
```

3. If no reusable checkout exists yet, start with the saved-browser-snapshot
   route and prefer the synced helper-surface form when the restored checkout
   should become its own follow-up root.
4. Run the restored-checkout route immediately after restore so missing repo
   files or helper-surface drift fails before broader preflights.
5. Run the saved-archive integrity route before trusting offline dependency or
   toolchain staging work that still depends on the exact saved bundles.
6. Run the offline build-inputs, saved-Rust, and Zig-line routes in that order
   when the next blocker is still Linux or WSL staging rather than direct
   runtime logic.
7. Run the Linux build-readiness route only after the saved checkout and saved
   bundles are trusted.
8. Reopen the direct runtime revalidation route only after the publication and
   toolchain gates are green.

## Working Rule

This route is a stack printer, not a replacement for the narrower helpers.

Use it when the next run needs one compact, truthful replay ladder from saved
snapshot restore through direct runtime re-entry, and then drop back down to the
smaller route that matches the first still-closed gate.
