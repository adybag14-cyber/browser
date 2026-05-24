# Issue #11 Saved-Snapshot Re-entry Chain

Use this note when issue `#3` is still blocked on Linux or WSL environment
readiness and the next run needs one compact path from the saved Memory snapshot
back to the narrower runtime route.

This note is intentionally small. It does not replace the existing route notes.
It keeps the right helpers in one order so future runs do not skip the
restored-checkout checkpoint between snapshot restore and broader build
readiness.

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/check_issue11_saved_snapshot_reentry_chain_surface.sh`
- `scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh`
- `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`

## When To Use It

Use this chain when all of these are true:

- the next follow-up still depends on the saved Memory repo snapshot
- the run wants to restore or reuse `../browser-memory-snapshot`
- the restored checkout should be proven ready before saved-input, archive,
  build-readiness, or runtime helpers widen the route

## Why It Exists

The branch already has the right pieces, but they are spread across several
route notes.

The trap is simple:

1. restore the saved snapshot
2. skip the restored-checkout readiness check
3. trust wider helper output from a follow-up root that is incomplete or stale

This chain keeps the restored-checkout route in the middle on purpose.

## Surface Check First

```bash
bash ./scripts/linux/check_issue11_saved_snapshot_reentry_chain_surface.sh
```

Use `--json` when another helper needs structured output.

## Print The Compact Chain

```bash
bash ./scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh
```

Use `--json` when another helper needs the command set as structured output.

## Ordered Route

1. Reopen the saved-browser-snapshot route.
2. Prefer the synced saved-browser-snapshot route when the restored checkout
   should become its own follow-up root with the current helper surface copied
   in.
3. Run the restore helper in `--check-only` mode.
4. Restore the checkout when the route is green.
5. Reopen the restored-checkout route surface and route printer from the live
   helper root.
6. Run `scripts/check_issue3_restored_checkout.py` against the restored
   checkout before anything wider.
7. Run the synced-helper-surface form of that same helper when the restored
   checkout should match the current live helper root.
8. Reopen the saved-Memory route and its raw preflight from the restored
   checkout.
9. Reopen the Linux build-readiness route from the restored checkout.
10. Hand back to the narrower direct runtime gate note and Windows runtime
   helper only after the restored checkout and Linux build-readiness routes
   agree.

## Working Rule

For issue `#11`, the first honest checkpoint after a saved snapshot restore is
the restored-checkout readiness helper, not the broader build-readiness helper.
