# Issue #3 Restored Helper-Surface Sync Route

Use this note when the saved browser snapshot already exists at
`../browser-memory-snapshot`, but the next Linux or WSL follow-up still cannot
trust it because the issue `#3` helper surface is stale, missing, or drifted
against the live helper checkout.

This route exists for a specific recovery path:

- the saved snapshot restore already succeeded once
- the restored checkout should stay reusable instead of being re-extracted from
  scratch
- the next run needs the current helper docs and helper scripts copied into that
  restored checkout before restored-checkout checks, saved-memory preflights,
  or Linux build-readiness helpers are trustworthy again

Keep these nearby:

- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- `../browser-memory-snapshot` already exists
- the live helper checkout has newer issue `#3` docs or route helpers than the
  restored checkout
- a restored-checkout readiness check failed because helper-surface files were
  missing or drifted
- the right fix is to refresh the helper surface in place instead of replacing
  the restored checkout with a fresh extraction

## Why This Route Matters

The restore helper already supports `--sync-helper-surface` and `--sync-only`,
but that path is easy to miss when the next run starts from a half-ready
restored checkout.

Without a compact sync route, a future run can waste time by:

- rerunning a full restore when only the helper surface drifted
- calling saved-memory or build-readiness helpers from a restored checkout that
  still carries stale route docs
- comparing a synced follow-up root against the live helper checkout without a
  dedicated refresh step in between

This route makes the refresh path explicit: surface check, sync-only command,
restored-checkout verification, saved-memory preflight, saved-archive
integrity, Linux build-readiness, then the direct runtime route.

## Practical Order

1. Run the sync-route surface check and print the compact route first:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
```

2. Confirm the current restored checkout needs a helper refresh:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

3. Print the restore helper in check-only mode with sync-only enabled so the
   exact live helper root, Memory root, snapshot archive path, and restored
   checkout destination are visible before anything mutates:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot \
  --sync-only \
  --check-only
```

4. Refresh the helper surface in place:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot \
  --sync-only
```

5. Re-run the restored-checkout helper and require the synced helper surface:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

6. Re-run the saved-memory preflight against the refreshed restored checkout:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --memory-root ../memory \
  --restored-checkout-root ../browser-memory-snapshot
```

7. If the route still depends on the exact saved archives, verify them next:

```bash
python ./scripts/check_issue3_saved_archive_integrity.py \
  --repo-root ../browser-memory-snapshot
```

8. Once the refreshed checkout is trusted again, move into Linux or WSL
   build-readiness and then the narrowed runtime route:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
  --repo-root ../browser-memory-snapshot
```

## Healthy Signals

Treat the helper-surface refresh as complete only when all of these are true:

- the sync-route surface checker passes
- `scripts/check_issue3_restored_checkout.py` no longer reports stale helper
  surface or helper drift
- `scripts/check_issue3_saved_memory_inputs.py` passes against the refreshed
  restored checkout
- Linux or WSL follow-up route printers no longer depend on stale helper files

## If The Refresh Fails

If the sync-only helper refresh fails:

- do not trust later helper output from `../browser-memory-snapshot` yet
- rerun the saved-browser-snapshot route in full restore mode only if the
  restored checkout itself is corrupted or missing required repo files
- keep using the live helper root for route commands until the restored
  checkout passes the helper-surface comparison again

## Working Rule

When the restored checkout already exists and only the issue `#3` helper
surface drifted, prefer the sync-only refresh route over a full snapshot
re-extract.

Run the sync-route surface checker and route printer first, refresh with
`restore_saved_browser_snapshot.sh --sync-only`, re-run the restored-checkout
helper, and only then widen back out to saved inputs, archive integrity, Linux
build readiness, and the direct runtime re-entry route.
