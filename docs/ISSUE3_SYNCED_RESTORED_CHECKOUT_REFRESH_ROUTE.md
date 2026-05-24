# Issue #3 Synced Restored Checkout Refresh Route

Use this note when `../browser-memory-snapshot` already exists, but the next
Linux or WSL follow-up should trust the restored checkout's own helper surface
instead of a separate live checkout.

This is the smaller companion to the saved-browser-snapshot restore route. It
does not re-extract the saved repo archive. It refreshes the current issue `#3`
helper docs and scripts in place with `--sync-only`, then reruns the checks
that prove the restored checkout is safe to use for the next build-readiness or
runtime re-entry step.

Companion helpers:

- `scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh`
- `scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when all of these are true:

- `../browser-memory-snapshot` already exists
- the restored checkout still looks like a browser repo
- the saved archive can lag the current branch-local helper surface
- the next Linux or WSL follow-up should run from the restored checkout itself

Typical stale-helper symptoms include a restored checkout that still has
`build.zig.zon` plus the headed runtime files, but is missing newer helper
surface files such as:

- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

Treat that as helper-surface drift, not as proof that the restored checkout or
saved archive is corrupt.

## Surface Check

From the live browser repo root:

```bash
bash ./scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh
bash ./scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh
```

Use `--json` when another helper needs the route as structured output.

## Refresh In Place

Refresh the helper surface inside the existing restored checkout without
re-extracting the saved repo archive:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_restored_checkout_reentry_route.sh --repo-root ../browser-memory-snapshot --helper-root . --restored-checkout-root ../browser-memory-snapshot --expect-helper-surface
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

`--sync-only` implies `--sync-helper-surface`, preserves the restored checkout
contents, and only refreshes the branch-local issue `#3` helper surface.

If `../browser-memory-snapshot` is missing, do not use this route first. Go
back to `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md` and restore the checkout
before trying to refresh it in place.

## Working Rules

- Run the synced-refresh surface check first so missing docs or route drift fail
  before the helper refresh is trusted.
- Run `restore_saved_browser_snapshot.sh --sync-only --check-only` before the
  real refresh so the route confirms the destination, helper root, and follow-up
  commands without mutating the checkout.
- Run `check_issue3_restored_checkout.py` immediately after the refresh so
  missing helper files or helper-root drift fail before broader staging.
- Run the saved-Memory preflight after the refreshed restored-checkout check.
- Run the saved-archive integrity check next when the route needs to prove the
  restored checkout still points back to the expected saved repo and dependency
  bundles.
- Use `show_issue3_restored_checkout_reentry_route.sh` when the refreshed
  checkout should remain the main follow-up root for the next Linux or WSL run.
- Reopen the direct `Page.zig` plus `win32_backend.zig` runtime lane only after
  the refreshed helper surface and the build-readiness gate agree that the
  environment is ready.
