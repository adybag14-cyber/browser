# Issue #3 Synced Helper Surface Check

Use this note after restoring the saved browser snapshot with
`scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface`.

Its job is simple: confirm that the restored checkout really carries the full
branch-local helper surface before the next Linux or WSL recovery step trusts
that checkout as its working root.

## Run The Check

From the live helper checkout:

```bash
python ./scripts/check_issue3_synced_helper_surface.py --repo-root ../browser-memory-snapshot
```

If the restored checkout lives somewhere else, point `--repo-root` at that
directory instead.

## What It Verifies

The helper checks:

1. the restored checkout still has `build.zig.zon`
2. the direct issue `#3` route notes are present
3. the saved-browser-snapshot, Linux build-readiness, Zig recovery, offline
   inputs, and saved Rust helper scripts are present
4. the runtime revalidation helper surface copied by
   `--sync-helper-surface` is present before the restored checkout is used as a
   self-contained follow-up root

## When To Use It

Use this check when:

1. the saved snapshot was restored with `--sync-helper-surface`
2. the next run wants to point `python scripts/check_issue3_saved_memory_inputs.py`
   or the Linux route helpers at the restored checkout itself
3. blocker history suggests the restored checkout may lag the current helper
   surface

## Working Rule

If this check fails, reopen the restore route from the live helper checkout and
resync the helper surface before trusting the restored checkout for Linux or WSL
issue `#3` recovery work.
