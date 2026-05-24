# Issue #3 Restored Helper-Surface Sync Route

Use this note when `../browser-memory-snapshot` already exists, but the issue
`#3` helper surface inside that restored checkout is stale, incomplete, or out
of sync with the current live helper root.

This route exists for one narrow recovery path:

- the saved browser snapshot restore already worked
- the restored checkout still looks like a browser repo
- `scripts/check_issue3_restored_checkout.py` reports `stale-helper-surface`,
  `helper-surface-drift`, or `partial-helper-surface-and-drift`
- the next Linux or WSL run wants to repair only the helper docs and route
  scripts in place instead of re-extracting the full repo archive

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
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

- the restored checkout already exists at `../browser-memory-snapshot` or an
  equivalent destination
- the saved repo archive itself does not need to be replaced
- the missing piece is the branch-local helper surface, not the underlying
  browser checkout files
- the next run wants the restored checkout to become a usable follow-up root

## Practical Order

1. Run the helper-surface sync route surface check and print the compact route:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
```

2. Confirm the stale-surface diagnosis against the restored checkout:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

3. Print the sync-only helper route before mutating the restored checkout:

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

5. Re-run the restored-checkout readiness check:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
```

6. Re-run the saved-Memory preflight and saved-archive integrity helper:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py \
  --repo-root ../browser-memory-snapshot
```

7. Only after the repaired helper surface is green, widen back into Linux or WSL
   build readiness and the direct runtime re-entry route:

```bash
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh \
  --repo-root ../browser-memory-snapshot
```

## If Sync-Only Is Not Enough

If `--sync-only` fails because the destination is missing, incomplete, or no
longer trustworthy as a browser checkout:

- fall back to the full synced restore route from
  `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- rerun `restore_saved_browser_snapshot.sh --sync-helper-surface`
- only then return to the restored-checkout readiness check

Treat `--sync-only` as a helper-surface repair path, not as a substitute for the
full restore when the checkout itself is broken.

## Working Rule

When the saved archive is still fine but the restored helper surface has aged
out, prefer `restore_saved_browser_snapshot.sh --sync-only` over a full
re-extract. Repair the helper surface first, prove it with
`check_issue3_restored_checkout.py`, and only then return to saved-input,
archive-integrity, build-readiness, and direct runtime re-entry work.
