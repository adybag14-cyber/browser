# Issue #3 Re-entry Route Index

Use this note when a scheduled or manual run needs one compact branch-local
index for the blocked issue `#3` recovery path.

This index does not replace the narrower route notes. Its job is to point the
next run at the right helper surface in the right order so it stops rebuilding
the same restore, archive, toolchain, and runtime path by hand.

Companion helpers:

- `scripts/linux/check_issue3_reentry_route_index_surface.sh`
- `scripts/linux/show_issue3_reentry_route_index.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route index when any of these are true:

- the next run needs the whole issue `#3` recovery ladder back on one compact
  Linux or WSL helper surface
- a run needs to decide whether to stay on the live helper root or switch into a
  restored checkout from the saved Memory snapshot
- the saved archive, toolchain, offline dependency, and direct runtime helpers
  all exist, but the next step is still too fragmented to replay confidently

## Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_reentry_route_index_surface.sh
```

Use `--json` when another helper wants the result as structured output.

## Print The Index

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_reentry_route_index.sh
```

Use `--sync-helper-surface` when the restored checkout should become its own
follow-up root because the saved snapshot can lag the current branch-local
helper surface.

Use `--json` when another helper wants the command set as structured output.

## What The Index Surfaces

The route index prints:

1. a fail-fast surface check for the index itself
2. the saved-browser-snapshot restore route from the live helper root
3. the recommended synced restore variant when the restored checkout should own
   the next follow-up commands
4. the saved-Memory preflight and saved-archive integrity checks against the
   restored checkout
5. the Linux or WSL build-readiness route against the restored checkout
6. the direct runtime re-entry route against the restored checkout
7. the equivalent live-root Linux or WSL build-readiness and runtime helpers
   when a restore is not needed

## Working Rules

- Run the surface check first so helper drift fails before the run blames saved
  archives, toolchains, or runtime state.
- Prefer the synced restore route when the restored checkout should become its
  own follow-up root because the saved snapshot can lag the current helper
  surface.
- Run the saved-Memory preflight and saved-archive integrity commands before
  treating Linux or WSL build output as issue `#3` evidence.
- Use the restored-checkout Linux or WSL build-readiness route before reopening
  the direct `Page.zig` plus `win32_backend.zig` lane when the environment is
  still the blocker.
- Use the restored-checkout direct runtime route only after the saved-archive,
  toolchain, and offline dependency gates are green.
- Keep the live-root Linux or WSL route and direct runtime route visible on this
  index so a run can skip the restore step when a reusable checkout already
  exists.
