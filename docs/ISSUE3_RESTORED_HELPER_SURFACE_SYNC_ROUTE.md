# Issue #3 Restored Helper-Surface Sync Route

Use this note when a saved browser snapshot was already restored, but the next
Linux or WSL rerun still needs a quick answer about whether that restored
checkout carries the newer issue `#11` helper surface closely enough to trust
the follow-up routes.

This route is narrower than the full restored-checkout readiness route. It does
not ask whether the restored checkout is a browser repo at all. It asks a more
specific question:

- does the restored checkout contain the late-added re-entry helper files that
  the issue `#11` Linux or WSL lane now expects
- and, when those files exist on both sides, do they still match the live
  helper root that produced the route

Keep these nearby:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`

## When To Use It

Use this route when all of these are true:

- a restored checkout already exists, usually at `../browser-memory-snapshot`
- the route intends to use synced helper-surface mode, or needs to confirm that
  a previous synced restore is still current
- the next step would otherwise trust saved-memory, saved-archive, build-
  readiness, or runtime re-entry helpers from the restored checkout itself

## Why This Check Matters

A restored checkout can pass the broader repo-shape check and still miss newer
issue `#11` route files. That is especially easy to miss when the saved archive
is older than the current live helper surface.

Use the narrower sync check to catch cases where:

- the restored checkout is missing newer issue `#11` route files
- the restored checkout still has an older copy of a helper that drifted from
  the live helper root
- a run should refresh the helper surface in place with `--sync-only` instead
  of assuming the restored checkout is already current

## Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
```

Override the roots when the live helper checkout or restored checkout live
somewhere unusual:

```bash
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh \
  --helper-root /path/to/live/browser \
  --restored-root /path/to/browser-memory-snapshot
```

Use `--json` when another helper wants the exact sync-check command as
structured output.

## Run The Sync Check

Once the route surface is green, run the narrower comparison helper:

```bash
python ./scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
```

Use `--json` when another helper wants the missing-file or drift report as
structured output.

## Keep Issue #11 Helper-Contract Checks In The Sequence

When the restored checkout is supposed to become its own helper root, do not
jump straight from the narrower sync check to the broader saved-memory preflight.

Re-run the two issue `#11` helper-contract checks while the restored checkout is
still being compared against the live helper root:

```bash
python ./scripts/check_issue11_saved_memory_helper_contract.py \
  --repo-root ../browser-memory-snapshot
python ./scripts/check_issue11_reentry_inventory_consistency.py \
  --repo-root ../browser-memory-snapshot
```

Those checks keep the saved-memory helper inventory and the wider issue `#11`
re-entry inventory visible before later saved-memory, saved-archive, or Linux
build-readiness follow-up work is treated as trustworthy.

## Keep Saved-Memory Preflight In Order

When the next commands will run from the restored checkout itself, do not treat
an apparently healthy saved-memory preflight as a replacement for this narrower
sync check.

The saved-memory helper is still the right follow-up for archive presence,
archive readability, and fallback Zig surfacing, but it should run only after
this sync route confirms that the restored checkout and the live helper root
agree on the current issue `#11` helper files.

Use this order when the restored checkout is supposed to become its own
follow-up helper root:

```bash
python ./scripts/check_issue3_restored_checkout.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --expect-helper-surface
python ./scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
python ./scripts/check_issue11_saved_memory_helper_contract.py \
  --repo-root ../browser-memory-snapshot
python ./scripts/check_issue11_reentry_inventory_consistency.py \
  --repo-root ../browser-memory-snapshot
python ./scripts/check_issue3_saved_memory_inputs.py \
  --repo-root ../browser-memory-snapshot \
  --helper-root . \
  --restored-checkout-root ../browser-memory-snapshot
```

That ordering keeps stale helper-surface drift from being hidden behind a later
saved-memory pass.

## If The Check Fails

Do not trust the restored checkout as the follow-up helper root yet.

Refresh the helper surface in place:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot \
  --sync-only
```

Then rerun the narrower sync check before widening back out to saved-memory,
saved-archive, build-readiness, or direct runtime re-entry helpers.

## Working Rule

For restored snapshots that are supposed to carry the current issue `#11`
helper surface, use this narrower sync route after the broader restored-
checkout readiness check, keep the issue `#11` helper-contract checks between
that sync step and the broader saved-memory preflight, and only then trust the
restored checkout as its own helper root.

A passing saved-memory preflight is useful follow-up evidence, but it is not the
replacement for this sync check when the route commands themselves will be
invoked from the restored checkout.
