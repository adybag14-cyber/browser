# Issue #3 Helper-Surface Sync Recovery

Use this note when `../browser-memory-snapshot` already exists, but the next
issue `#3` replay still needs newer branch-local helper docs or route scripts
before Linux, WSL, or direct runtime follow-up can continue.

This route keeps the in-place helper refresh path on one compact surface so a
run can repair helper drift without re-extracting the saved repo snapshot.

Companion helpers:

- `scripts/linux/check_issue3_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_helper_surface_sync_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- `../browser-memory-snapshot` already exists, but it is missing newer helper
  files such as `scripts/check_issue3_saved_memory_inputs.py`
- the restored checkout still has `build.zig.zon`, but helper-surface drift is
  blocking the next Linux or WSL recovery route
- the saved-browser restore route already ran successfully and the next step is
  only to refresh branch-local docs and scripts in place

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_helper_surface_sync_route.sh
```

Use the first command when the route should fail fast on missing notes, helper
scripts, or sync-only support before a run trusts the refresh path.

Use the second command when the route should print the exact sync-only helper
surface refresh commands, follow-up checks, and optional fallback Zig surface on
one compact output.

## Refresh The Helper Surface

Keep the restored checkout in place and refresh only the branch-local helper
surface:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
```

That route preserves the existing restored checkout contents and only copies the
current issue `#3` helper docs and scripts into the restored checkout.

Use `--destination` when the restored checkout lives somewhere other than
`../browser-memory-snapshot`.

Use `--helper-root /path/to/live/browser` when the refresh should copy helper
files from a specific live checkout instead of the current repo root.

## Immediate Follow-up

After the helper-surface refresh succeeds, run these checks in order:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Run the restored-checkout readiness check first so missing helper files or a bad
checkout surface fail before broader recovery steps reopen.

Run the saved-Memory preflight next so missing archives, unreadable bundles, or
helper drift fail before Linux or WSL staging is trusted.

Run the saved-archive integrity check immediately after that when the route
still depends on the exact saved repo and dependency bundles.

## Working Rules

- Prefer this route when the checkout already exists and only the helper surface
  needs repair.
- Prefer the full saved-browser restore route when the restored checkout is
  missing entirely or no longer looks like a browser checkout.
- Keep helper refresh separate from archive extraction so replay can distinguish
  stale helper drift from broken restore state.
- Reopen the direct `Page.zig` plus `win32_backend.zig` runtime lane only after
  the refreshed checkout passes the restored-checkout and saved-Memory checks.
- Treat `--sync-only` as a branch-local helper repair step, not as proof that
  Zig, Rust, or offline dependency staging is already healthy.
