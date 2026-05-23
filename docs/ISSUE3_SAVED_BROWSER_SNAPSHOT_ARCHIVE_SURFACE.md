# Issue #3 Saved Browser Snapshot Archive Surface

Use this helper when the saved Memory snapshot exists, but the next Linux or
WSL replay needs to know whether that archive already contains the current issue
#3 restore-route helper surface.

This keeps one repeat blocker on a small branch-local command surface:

- the saved repo snapshot can lag the newer helper docs and route scripts
- a plain restore can look valid even when the restored checkout is missing the
  helper surface needed for the next follow-up commands
- future runs should know up front when `--sync-helper-surface` is the safer
  restore mode

Companion helper:

- `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`

## Usage

From the browser repo root:

```bash
python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py
python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py --json
```

Use `--memory-root /path/to/memory` or `--archive /path/to/snapshot.zip` when
the saved snapshot lives outside the default agent layout.

## What It Reports

The helper inspects the saved archive and reports:

- the resolved snapshot archive path
- the inferred top-level folder inside the zip
- whether the current helper surface is already present inside the archive
- which helper paths are missing when the archive is stale
- whether a plain restore is safe or `--sync-helper-surface` should be used

The required helper surface currently includes:

- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## Working Rules

- Prefer a plain restore only when the helper reports that the archive already
  contains the current restore-route helper surface.
- Prefer `--sync-helper-surface` when one or more helper paths are missing from
  the saved archive.
- Keep the live helper root for the next follow-up commands whenever the archive
  helper surface is stale.
- Treat this helper as a fast restore-route preflight, not as proof that Linux
  or WSL validation is already ready to reopen the direct runtime lane.
