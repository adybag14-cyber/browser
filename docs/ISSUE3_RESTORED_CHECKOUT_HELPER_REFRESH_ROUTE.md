# Issue #3 Restored-Checkout Helper Refresh Route

Use this note when `../browser-memory-snapshot` already exists, but the next
Linux or WSL follow-up still needs the newer issue `#3` helper surface from the
live branch before build-readiness or runtime re-entry work can continue.

This route exists for the stale-helper case only:

- the saved repo snapshot restored successfully
- the restored checkout still looks like a browser repo
- the restored checkout is missing newer route helpers or docs from the live
  branch
- the next step should refresh the helper surface in place instead of
  re-extracting the whole saved archive

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- `../browser-memory-snapshot` already exists
- the restored checkout should stay the follow-up root
- helper drift, not archive absence, is the current blocker
- the next run wants a compact command surface for `--sync-only`

## Surface Check

Run the dedicated surface check first:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh
bash ./scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh
```

That keeps the refresh note, route printer, restore helper, restored-checkout
readiness helper, saved-Memory preflight, saved-archive integrity helper, Linux
build-readiness route, and direct runtime route on one visible branch-local
surface before the refresh is trusted.

## Practical Order

Use this order when the restored checkout already exists and only the helper
surface needs to be refreshed:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh
bash ./scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py \
  --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
  --repo-root ../browser-memory-snapshot
```

## Working Rule

If the restored checkout already exists, prefer this helper-refresh route before
retrying a full snapshot extraction. The purpose is to refresh the branch-local
issue `#3` helper surface in place and then re-run the same restored-checkout,
saved-input, build-readiness, and runtime re-entry gates from a self-contained
follow-up root.
