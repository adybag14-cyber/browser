# Issue #3 Restored-Checkout Re-entry Route

Use this note when the direct issue `#3` runtime lane is still blocked on Linux or WSL by checkout state rather than by the narrowed `Page.zig` or `win32_backend.zig` patch itself.

This route exists for one specific trap: a saved browser snapshot can be restored successfully, but the next run can still lose time if it jumps straight into saved-memory preflights, build-readiness helpers, or runtime replay before proving that the restored checkout is actually ready to serve as the follow-up root.

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- the current run still depends on the saved Memory repo snapshot
- the next Linux or WSL step wants to restore or reuse `../browser-memory-snapshot`
- the run needs an explicit yes-or-no answer about whether that restored checkout is safe to trust before wider validation begins

## Why This Check Matters

The restore step alone is not enough.

A restored checkout can still fail follow-up work when:

- the checkout is missing core browser repo files such as `build.zig.zon`
- the synced issue `#3` helper surface was not copied into the restored checkout
- the restored helper files drift from the live helper root that produced the route
- the next run starts calling saved-memory or runtime helpers against an incomplete follow-up root

That is why `scripts/check_issue3_restored_checkout.py` should run immediately after restore and before the saved-memory preflight, saved-archive integrity check, Linux build-readiness route, or direct runtime re-entry route.

## Practical Order

Use this order when the run is reopening from a saved snapshot:

1. Print the saved-browser-snapshot route first:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

2. Run the restore helper in check-only mode so the archive path, destination, and sync mode are confirmed before extraction:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot \
  --check-only
```

3. Restore the checkout when the surface check is green:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot
```

4. Run the restored-checkout readiness helper before anything wider:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot
```

5. If the restore used the synced helper-surface mode, keep the live checkout as the comparison root and require the helper surface explicitly:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

6. Only after the restored checkout passes, run the saved-memory preflight:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot
```

7. If the route still depends on the exact saved archives, run the saved-archive integrity helper next:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py \
  --repo-root ../browser-memory-snapshot
```

8. When the restored checkout and saved inputs are both green, move into Linux or WSL build readiness:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root ../browser-memory-snapshot
```

9. Reopen the narrowed runtime route only after the restored checkout, saved inputs, and build-readiness surfaces agree:

```bash
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
  --repo-root ../browser-memory-snapshot
```

## Healthy Signals

Treat the restored checkout as ready only when all of these are true:

- `scripts/check_issue3_restored_checkout.py` passes without missing required browser repo files
- synced helper-surface mode reports no drift against the live helper root
- the saved-memory preflight sees the repo snapshot, README, blocker intelligence, dependency bundles, and optional fallback Zig archive in the expected places
- the saved-archive integrity and build-readiness routes no longer fail on missing checkout state

## If The Check Fails

If the restored-checkout helper fails:

- do not treat later Linux or WSL helper output as trustworthy yet
- rerun the snapshot restore in synced helper-surface mode when the restored checkout should become its own follow-up root
- keep using the live helper root when the restored checkout should remain a clean historical snapshot
- fix the checkout-state problem before blaming the direct `Page.zig` plus `win32_backend.zig` runtime slice

## Working Rule

For saved-snapshot re-entry, the first meaningful checkpoint after restore is not the saved-memory preflight. It is the restored-checkout readiness check.

Run `scripts/check_issue3_restored_checkout.py` first, then widen into saved inputs, archive integrity, Linux build readiness, and finally the direct issue `#3` runtime route.