# Issue #3 Restored-Checkout Refresh Route

Use this note when `../browser-memory-snapshot` already exists, but the next
Linux or WSL re-entry run is still blocked by stale helper-surface files inside
that restored checkout.

This route keeps the helper-surface refresh and the immediate follow-up checks
on one small live-helper surface so future runs do not have to rebuild the
recovery path by hand.

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/check_issue3_restored_checkout_refresh_route_surface.sh`
- `scripts/linux/show_issue3_restored_checkout_refresh_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- a restored checkout already exists at `../browser-memory-snapshot`, or at a
  caller-provided alternate destination
- the restored checkout is missing newer issue `#3` helper files, or the helper
  files drift from the live helper root
- the next Linux or WSL run wants to keep using that restored checkout instead
  of replacing it immediately

## Practical Order

1. Check that the live helper surface for this refresh route is present:

```bash
bash ./scripts/linux/check_issue3_restored_checkout_refresh_route_surface.sh
```

2. Print the compact refresh route:

```bash
bash ./scripts/linux/show_issue3_restored_checkout_refresh_route.sh
```

3. Dry-run the helper-surface refresh first:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
```

4. Refresh the helper surface in place without replacing the restored checkout:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
```

5. Re-run the restored-checkout readiness helper against the refreshed checkout:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

6. Re-run the saved-memory preflight and then the build-readiness or runtime
   route only after the refreshed checkout passes:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
  --repo-root ../browser-memory-snapshot
```

## Working Rule

If the restored checkout still looks like a valid browser repo but its issue
`#3` helper surface is stale, prefer an in-place `--sync-only` refresh before
re-extracting the saved repo snapshot.
