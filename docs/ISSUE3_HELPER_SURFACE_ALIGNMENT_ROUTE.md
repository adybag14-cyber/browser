# Issue #3 Helper Surface Alignment Route

Use this note when a Linux, WSL, or scheduled headed-mode run needs to confirm
that the restore helper, restored-checkout checker, and saved-Memory preflight
still agree on the issue `#3` helper surface before a restored checkout is
trusted.

This route keeps the helper-surface alignment checker, its dedicated surface
check, the progress-tracker handoff, and the immediate restore or saved-Memory
follow-up routes on one compact branch-local surface.

Companion helpers:

- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh`
- `scripts/linux/show_issue3_helper_surface_alignment_route.sh`
- `scripts/check_issue3_helper_surface_alignment.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_memory_inputs_route.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`

## When To Use It

Use this route when any of these are true:

- a scheduled run wants a fast drift check before it trusts a restored checkout
  or the saved-Memory preflight
- the restore helper surface has grown and the run needs to know whether the
  saved-Memory and restored-checkout helpers still match it
- a restored checkout is present but may have been synced from an older live
  helper surface
- the direct issue `#3` runtime lane is still blocked and the safest useful
  work is tightening the Linux or WSL re-entry guard rails

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_helper_surface_alignment_route.sh
```

If the live helper checkout lives somewhere unusual, override the repo root:

```bash
bash ./scripts/linux/show_issue3_helper_surface_alignment_route.sh \
  --repo-root /path/to/browser
```

Use `--json` when another helper wants the resolved command set as structured
output.

## Run The Alignment Check

After the route surface is green, run the helper-surface alignment checker:

```bash
python ./scripts/check_issue3_helper_surface_alignment.py --repo-root .
```

That command compares the helper-surface path inventories embedded in:

- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_restored_checkout.py`

It also fails fast when the critical issue `#3` Linux or WSL re-entry helpers
drop off any one of those inventories even if two lists still happen to match
each other.

## Immediate Follow-up

If the alignment check fails because the helper inventories drifted, keep issue
`#11` visible as the progress lane while the environment gates remain closed:

```text
docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
```

Then choose the next route by the actual failure:

If the saved-Memory preflight inventory is stale relative to the restore
surface:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
```

If the restore route is the source of drift or the run still needs to recreate
or refresh a self-contained checkout:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

If the restored checkout already exists and the run needs to re-check that
surface directly after helper sync:

```bash
python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
```

## Working Rules

- Run the helper-surface route surface check first so missing notes or helper
  scripts fail before the route blames the inventories themselves.
- Run the alignment checker before trusting a restored checkout that was synced
  from a live helper surface.
- Keep `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md` visible whenever the route is
  still working in the Linux or WSL re-entry lane so start and completion
  updates continue to land on issue `#11`.
- Use the saved-Memory route when the alignment failure points at
  `scripts/check_issue3_saved_memory_inputs.py`.
- Use the saved-browser-snapshot route when the alignment failure points at the
  restore helper or when the run still needs a refreshed self-contained
  checkout.
- Treat this route as a guard rail for restore and preflight drift, not as proof
  that the direct `Page.zig` plus `win32_backend.zig` runtime patch is ready to
  reopen.
