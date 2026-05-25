# Issue #3 Saved Browser Snapshot Sync Decision Route

Use this helper when the Linux or WSL re-entry lane needs to decide whether the
saved browser snapshot should be:

- restored as-is
- restored with `--sync-helper-surface`
- refreshed in place with `--sync-only`

This is a small preflight for the issue `#11` build-readiness lane. It keeps
the stale-archive decision on one command before a run reopens broader restore,
offline staging, or direct runtime work.

## Helper

```bash
python scripts/check_issue3_saved_browser_snapshot_sync_decision.py
```

Use `--json` when another helper or automation step needs the recommendation as
structured output.

## What It Checks

The helper compares the current live helper-surface list from:

- `scripts/linux/restore_saved_browser_snapshot.sh`

against:

- `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
- the current restore destination, usually `../browser-memory-snapshot`

## Recommendations

The helper returns one of these recommendations:

- `plain-restore`
  The archive already carries the current helper surface, and there is no
  existing restored checkout yet.
- `sync-helper-surface`
  The archive is missing one or more current helper-surface paths, so the first
  restore should overlay the live helper surface.
- `sync-only`
  A restored checkout already exists and the archive is stale, so the helper
  surface should be refreshed in place instead of re-extracting the snapshot.
- `reuse-existing-checkout`
  A restored checkout already exists and the archive already matches the current
  helper surface closely enough that the next step can move straight to the
  restored-checkout readiness check.

## Typical Flow

When the route needs the shortest decision path:

```bash
python scripts/check_issue3_saved_browser_snapshot_sync_decision.py
```

If the helper recommends `sync-helper-surface`:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface
```

If the helper recommends `sync-only`:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
```

If the helper recommends `plain-restore`:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh
```

If the helper recommends `reuse-existing-checkout`, move straight to:

```bash
python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
```

## Why This Exists

The saved browser snapshot is intentionally stable, so it can lag the branch's
current route helpers. Without a quick decision helper, runs can waste time
reproducing the same stale-archive symptom before noticing that `--sync-only`
or `--sync-helper-surface` was the better path.