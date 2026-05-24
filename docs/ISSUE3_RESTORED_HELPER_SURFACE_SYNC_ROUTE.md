# Issue #3 Restored Helper Surface Sync Route

Use this note when a reusable restored checkout already exists, but the next
Linux or WSL issue `#3` follow-up may still be pointing at stale helper docs or
route scripts copied from an older saved archive.

This route keeps the helper-surface drift check and the repair path on one
small branch-local surface so future runs can tell the difference between:

- a missing restored checkout
- a restored checkout that exists but is missing newer helper files
- a restored checkout whose helper files drifted away from the current branch

Companion helpers:

- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- `../browser-memory-snapshot` already exists, but the saved archive may lag the
  current branch-local helper surface
- the next Linux or WSL run wants to know whether it can trust the restored
  checkout's own helper scripts
- a prior restore happened without `--sync-helper-surface`
- `check_issue3_saved_memory_inputs.py` reported helper-surface drift or missing
  helper files in the restored checkout

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
```

The first command verifies that this route note, the route printer, and the
underlying saved-Memory and restore helpers are still present before the route
tries to reason about drift.

The second command prints the exact sync-check and repair commands with the
resolved live helper root, restored checkout root, Memory root, and optional
fallback Zig archive already filled in.

Use `--json` when another helper needs the route as structured output.

## Check For Drift

The dedicated sync route uses the saved-Memory preflight in comparison mode:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root . \
  --helper-root . \
  --restored-checkout-root ../browser-memory-snapshot
```

That check reports whether:

- the restored checkout exists
- the restored checkout has `build.zig.zon`
- the required issue `#3` helper surface exists there
- the restored helper files match the current branch-local helper root

If the restored checkout is missing, switch back to the saved-browser-snapshot
restore route first:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

## Repair Drift

When the restored checkout exists but its helper surface is missing files or has
drifted away from the live helper root, prefer re-running the restore with
helper-surface sync enabled:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --force
```

Then re-run the sync check:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root ../browser-memory-snapshot \
  --restored-checkout-root ../browser-memory-snapshot
```

That self-contained follow-up treats the restored checkout as both the repo root
and the helper root, which is the intended shape after a synced restore.

## After The Sync Turns Green

Once the helper surface is synced, continue with the normal restored-checkout
follow-up ladder:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Keep the helper surface synced before reopening focused `Page.zig` plus
`win32_backend.zig` work so future runs do not misread old helper scripts as a
runtime regression.

## Working Rules

- Use this route only after a restored checkout already exists or when drift is
  the suspected blocker.
- Use the saved-browser-snapshot restore route first when no restored checkout
  exists yet.
- Prefer the synced restore repair path over hand-copying individual helper
  files into the restored checkout.
- Treat helper-surface drift as route hygiene, not as proof that the direct
  issue `#3` runtime patch changed behavior.
