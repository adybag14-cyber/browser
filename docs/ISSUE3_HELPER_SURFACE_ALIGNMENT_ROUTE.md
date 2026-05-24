# Issue #3 Helper-Surface Alignment Route

Use this note when the blocked issue `#3` restore and Linux or WSL re-entry path
needs a quick answer to one question before anything else:

Do the saved-Memory preflight, restored-checkout readiness helper, and
saved-browser-snapshot sync helper all agree on which issue `#3` helper-surface
files belong in a self-contained restored checkout?

This route exists because the saved repo snapshot can lag the live branch-local
helper surface, and a restore path is only as honest as the helper inventory it
copies and validates.

Companion helpers:

- `scripts/check_issue3_helper_surface_alignment.py`
- `scripts/linux/show_issue3_helper_surface_alignment_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_restored_checkout.py`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- the next run wants to trust `--sync-helper-surface` or `--sync-only` on the
  saved-browser-snapshot restore path
- the saved-Memory preflight and the restored-checkout helper appear to disagree
  about which route docs or scripts belong in a synced checkout
- a future rerun needs to catch helper-surface drift before Linux or WSL
  build-readiness work starts

## Run The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_helper_surface_alignment_route.sh
```

If the live helper root or restore destination lives somewhere unusual,
override them explicitly:

```bash
bash ./scripts/linux/show_issue3_helper_surface_alignment_route.sh \
  --repo-root /path/to/browser \
  --helper-root /path/to/live/browser \
  --destination /path/to/browser-memory-snapshot
```

Use `--json` when another helper wants the route as structured output.

## What The Route Surfaces

The route prints:

1. the live helper-root alignment check for
   `scripts/check_issue3_helper_surface_alignment.py`
2. the saved-browser-snapshot route for the current helper root
3. the preferred synced restore route when the restored checkout should carry
   the current helper surface
4. the post-restore alignment check against the restored checkout itself
5. the restored-checkout readiness helper that should follow only after the
   alignment check passes

## Direct Commands

If the route is already narrowed and you just need the exact commands, use this
order:

```bash
python ./scripts/check_issue3_helper_surface_alignment.py --repo-root .
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root . --helper-root . --destination ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root . --helper-root . --destination ../browser-memory-snapshot --sync-helper-surface
python ./scripts/check_issue3_helper_surface_alignment.py --repo-root ../browser-memory-snapshot
python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
```

## Working Rules

- Run the live alignment check first so helper-surface drift is caught before a
  restore path copies stale assumptions into a synced checkout.
- Prefer the synced restore route when the saved archive helper surface is older
  than the current branch-local helper surface.
- Re-run the alignment checker against the restored checkout after a synced
  restore so route drift is caught before Linux or WSL build-readiness work
  starts.
- Run `check_issue3_restored_checkout.py` only after the alignment checker
  passes for the helper root that will drive follow-up commands.
- Use `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` after this route when the next
  question is whether the direct `Page.zig` plus `win32_backend.zig` runtime
  patch can reopen honestly.
