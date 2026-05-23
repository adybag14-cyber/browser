# Issue #3 Saved Browser Snapshot Restore Route

Use this note when the saved Memory repo archive is present, but the next Linux
or WSL build-readiness or runtime re-entry step still lacks a reusable local
browser checkout.

This route keeps the snapshot restore and the first follow-up checks on one
small branch-local surface so future runs do not need to rebuild the extraction
path by hand.

Companion helpers:

- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`

## When To Use It

Use this route when any of these are true:

- `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip` is present
  in Memory, but there is no extracted checkout beside the workspace
- a scheduled run needs to reopen the Linux build-readiness route before the
  direct `Page.zig` plus `win32_backend.zig` patch can be retried
- the next run needs a disposable local checkout for helper validation without
  relying on remote GitHub file publication

## Surface Check

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh
bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only
```

The first command verifies that the restore note, route printer, and follow-up
helpers are still present on the branch-local surface before the route tries to
extract anything.

The second command prints the saved archive location, the inferred top-level
folder from the zip, the default restore destination, and the first follow-up
commands.

When you want the whole restore route on one compact command surface instead,
print the route helper:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

Use `--json` when another helper needs the restore route as structured output.
Use `--helper-root /path/to/live/browser` when the route should keep using a
specific live checkout for its follow-up helpers instead of assuming the current
repo root.

## Restore The Checkout

Restore the saved repo snapshot into a reusable sibling checkout:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh
```

By default this extracts:

- archive: `../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
- destination: `../browser-memory-snapshot`

Use `--destination` when the checkout should live somewhere else, and use
`--force` only when it is safe to replace an older extracted checkout.

When the restored checkout should also carry the current issue #3 helper docs
and route scripts, add `--sync-helper-surface`.

That mode copies the current helper surface from the live helper root into the
restored checkout after extraction so the next Linux or WSL follow-up commands
can target the restored checkout directly instead of staying anchored to a
separate live checkout.

## Recommended Self-Contained Restore

Prefer the synced restore path when the restored checkout should become its own
follow-up root for the next Linux or WSL replay:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Prefer this self-contained route when the saved archive can lag the current
branch-local helper surface and the follow-up commands should live inside the
restored checkout instead of depending on a separate live helper root.

## Immediate Follow-up

After the restore succeeds, choose one of these follow-up modes.

Keep using the current repo root helper surface against the extracted checkout:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Or restore with `--sync-helper-surface` and then switch the follow-up helpers
into the restored checkout itself:

```bash
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

The saved archive is a stable historical snapshot, so it may not contain the
newest branch-local recovery helpers. Do not switch into the restored checkout
and assume these route scripts exist there unless the restore used
`--sync-helper-surface`.

The route helper prints those same commands with the resolved archive,
destination, helper-root, optional helper-surface sync mode, and optional
fallback Zig archive surface already filled in.

That keeps the saved-Memory preflight, the Linux build-readiness route, and the
runtime re-entry route anchored to the restored checkout before the direct issue
`#3` runtime lane is reopened again.

## Working Rules

- Use this restore route before blaming missing checkout state on the runtime
  patch itself.
- Prefer a disposable restored checkout for helper validation when the live
  branch still needs a safer publication path for large existing files.
- Prefer `--sync-helper-surface` when the restored checkout should be more
  self-contained for the next Linux or WSL route replay.
- Keep the follow-up helper root on the live branch-local surface only when the
  restore should stay as a clean historical snapshot.
- Treat this route as a setup step for build-readiness and runtime re-entry, not
  as proof that the branch is ready for focused Zig validation.
