# Issue #3 Saved Browser Snapshot Restore Route

Use this note when the saved Memory repo archive is present, but the next Linux
or WSL build-readiness or runtime re-entry step still lacks a reusable local
browser checkout.

This route keeps the snapshot restore and the first follow-up checks on one
small branch-local surface so future runs do not need to rebuild the extraction
path by hand.

Companion helpers:

- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md`
- `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`
- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
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
python ./scripts/check_issue3_saved_browser_snapshot_archive_surface.py
bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only
```

The first command verifies that the restore note, route printer, archive-surface
helper, and follow-up helpers are still present on the branch-local surface
before the route tries to extract anything.

The second command checks whether the saved snapshot archive already contains the
current helper surface or whether `--sync-helper-surface` is the safer restore
mode before the route chooses its follow-up root.

The third command prints the saved archive location, the inferred top-level
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
follow-up root for the next Linux or WSL replay, or whenever
`check_issue3_saved_browser_snapshot_archive_surface.py` reports that the saved
archive is missing one or more current helper paths:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_saved_memory_helper_contract.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_reentry_inventory_consistency.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_rust_archive_candidates.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Prefer this self-contained route when the saved archive can lag the current
branch-local helper surface and the follow-up commands should live inside the
restored checkout instead of depending on a separate live helper root.

If `../browser-memory-snapshot` already exists and only the helper docs and
route scripts are stale, refresh them in place without re-extracting the saved
repo archive:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only --check-only
bash ./scripts/linux/restore_saved_browser_snapshot.sh --sync-only
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_saved_memory_helper_contract.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_reentry_inventory_consistency.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_rust_archive_candidates.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

`--sync-only` implies `--sync-helper-surface`, preserves the existing restored
checkout contents, and only refreshes the branch-local issue #3 helper surface
inside that checkout.

A concrete stale-archive symptom is a restored checkout that still looks like a
browser repo but is missing newer helper files such as
`scripts/check_issue3_saved_memory_inputs.py` or
`scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`.
Treat that as archive age, not restore corruption, and rerun the restore with
`--sync-helper-surface` before Linux or WSL follow-up work.

Use `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md` when the restore itself is
already working and the next question is whether the restored checkout is ready
to trust before the saved-Memory preflight, saved-archive integrity check, Linux
or WSL build-readiness route, or direct runtime re-entry route.

Use `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md` when a synced restore or
sync-only refresh already happened and the next question is whether the
restored checkout now carries the late-added issue `#11` helper surface closely
enough to trust it as its own follow-up helper root.

Use `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md` and
`docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md` when the synced restore is
healthy but the next gate has narrowed to saved Rust archive choice, staged
Rust reuse, or the bridge back into the broader Linux build-readiness ladder.

## Immediate Follow-up

After the restore succeeds, choose one of these follow-up modes.

Keep using the current repo root helper surface against the extracted checkout:

```bash
python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Or restore with `--sync-helper-surface` and then switch the follow-up helpers
into the restored checkout itself:

```bash
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_helper_surface_sync.py --helper-root . --restored-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_saved_memory_helper_contract.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue11_reentry_inventory_consistency.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
python ../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_saved_rust_archive_candidates.py --repo-root ../browser-memory-snapshot
python ../browser-memory-snapshot/scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
bash ../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root ../browser-memory-snapshot
bash ../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root ../browser-memory-snapshot
```

Run the restored-checkout readiness check first so missing `build.zig.zon`,
missing helper-surface files, or helper drift fail before the saved-Memory and
saved-archive preflights.

When the route used `--sync-helper-surface` or `--sync-only`, print the
restored-helper sync route and run the narrower sync check before the broader
saved-Memory and saved-archive preflights trust the restored checkout as its
own helper root.

After the narrower sync check passes, use the issue `#11` helper-contract and
inventory checks before the broader saved-Memory preflight so newer tracker,
saved-Rust, staged-toolchain, and rerun-route expectations fail fast instead of
silently narrowing the restored checkout back to an older helper surface.

Run the saved-Memory preflight next so missing archives or helper drift fail
before deeper staging. Run the saved-archive integrity check immediately after
that when the route needs to prove the repo snapshot and dependency bundles
still match the expected exact artifacts before broader Linux or WSL staging.

If the next blocker has already narrowed to saved Rust archive selection,
staged Rust reuse, or the Rust-to-build-readiness bridge, reopen the saved Rust
candidate helper and the compact saved Rust build-readiness route before
jumping straight back to the broad Linux build-readiness ladder.

The saved archive is a stable historical snapshot, so it may not contain the
newest branch-local recovery helpers. Do not switch into the restored checkout
and assume these route scripts exist there unless the restore used
`--sync-helper-surface` or a later `--sync-only` refresh.

The archive-surface helper keeps that stale-archive decision on its own compact
preflight before the restore mode is chosen. Use it whenever the run needs a
quick answer about whether a plain restore is still safe.

The route helper prints those same commands with the resolved archive,
destination, helper-root, optional helper-surface sync mode, and optional
fallback Zig archive surface already filled in.

That keeps the restored-helper sync route, the issue `#11` helper-contract
checks, the restored-checkout readiness check, the saved-Memory preflight, the
saved-archive integrity check, the saved Rust candidate bridge, the Linux
build-readiness route, and the runtime re-entry route anchored to the restored
checkout before the direct issue `#3` runtime lane is reopened again.

## Working Rules

- Use this restore route before blaming missing checkout state on the runtime
  patch itself.
- Prefer a disposable restored checkout for helper validation when the live
  branch still needs a safer publication path for large existing files.
- Run `check_issue3_saved_browser_snapshot_archive_surface.py` before choosing
  between a plain restore and `--sync-helper-surface` when the archive age is in
  doubt.
- Run `check_issue3_restored_checkout.py` immediately after restore so missing
  repo surfaces or helper drift fail before the archive-focused preflights.
- Run `check_issue3_restored_helper_surface_sync.py` after a synced restore or
  `--sync-only` refresh when the restored checkout should become its own issue
  `#11` helper root.
- Run `check_issue11_saved_memory_helper_contract.py` and
  `check_issue11_reentry_inventory_consistency.py` after the narrower sync
  check when the restored checkout is expected to carry the broader issue `#11`
  helper surface, including saved-Rust and rerun-route follow-ups.
- Prefer `--sync-helper-surface` when the restored checkout should be more
  self-contained for the next Linux or WSL route replay.
- Prefer `--sync-only` when the restored checkout already exists and only the
  helper surface needs to be refreshed.
- Keep the follow-up helper root on the live branch-local surface only when the
  restore should stay as a clean historical snapshot.
- Treat this route as a setup step for build-readiness and runtime re-entry, not
  as proof that the branch is ready for focused Zig validation.
- When exact saved inputs matter, run `check_issue3_saved_archive_integrity.py`
  right after the saved-Memory preflight instead of assuming the mounted
  archives are still the expected copies.
- When the restore is green but the next environment gate is Rust-specific, use
  the saved Rust archive-candidates route and saved Rust build-readiness bridge
  before widening back out to the full Linux build-readiness route.
