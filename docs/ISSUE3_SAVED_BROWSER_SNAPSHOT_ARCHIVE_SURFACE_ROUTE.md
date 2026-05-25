# Issue #3 Saved Browser Snapshot Archive Surface Route

Use this note when the saved Memory browser snapshot archive is present, but the
next Linux or WSL replay needs a fast answer to one practical question:

- does the saved zip already carry the current issue #3 helper surface
- or should the next restore prefer `--sync-helper-surface` before follow-up
  route commands trust the restored checkout

This route keeps that check on the same compact wrapper surface used by the
other issue `#3` Linux or WSL re-entry helpers.

## Companion Surfaces

- `scripts/linux/check_issue3_saved_browser_snapshot_archive_surface_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_archive_surface_route.sh`
- `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_archive_surface_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_archive_surface_route.sh
```

Use `--json` when another helper wants the resolved archive path, recommended
restore mode, missing helper paths, and follow-up route commands as structured
output.

## Run The Helper

From the browser repo root:

```bash
python scripts/check_issue3_saved_browser_snapshot_archive_surface.py --repo-root .
```

Use `--json` when another helper or a scheduled run wants the missing helper
paths and restore recommendation as structured output.

If the saved archive is not under the default Memory layout, provide it
explicitly:

```bash
python scripts/check_issue3_saved_browser_snapshot_archive_surface.py \
  --repo-root . \
  --archive /path/to/01-browser-fork-headed-mode-foundation.zip
```

## What The Route Surfaces

The helper route prints:

1. the resolved snapshot archive path
2. the inferred top-level folder inside the zip
3. whether the current helper surface is already present in the archive
4. whether the next restore should stay plain or prefer `--sync-helper-surface`
5. the missing helper paths when the saved archive is stale
6. a ready-to-rerun saved browser-snapshot route command
7. a ready-to-rerun workspace-context route command
8. a ready-to-rerun issue `#11` progress-tracker route command
9. a ready-to-rerun direct runtime revalidation route command

## Working Rules

- Run this route before the next restore when the saved snapshot may lag the
  current branch-local helper surface.
- Run the route surface check first when a scheduled run is about to trust the
  wrapper route instead of calling the archive-surface helper directly.
- Prefer a plain restore only when the route reports that the archive helper
  surface is complete.
- Prefer `--sync-helper-surface` when the route reports missing helper paths,
  especially when the restored checkout will become its own follow-up root.
- Use the printed issue `#11` progress-tracker route when the next rerun still
  needs a lower-volume status lane before reopening the direct runtime patch.
