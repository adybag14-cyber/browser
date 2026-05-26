# Issue #3 Progress Tracker Route

Use this note when the next headed-mode run needs to leave progress updates for
the blocked issue `#3` runtime re-entry lane, but the long-running historical
threads are no longer practical places to comment.

## Why This Exists

The main historical threads still matter:

- issue `#2` is the broad production tracker
- issue `#3` is the direct headed Google input/runtime bug

But both threads are now poor fit as routine scheduled-run logs because new
comments can fail once those issue conversations become too large.

Use issue `#11` instead for the lower-volume Linux or WSL re-entry lane:

- `Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker`

That tracker is the right place to leave start and completion updates for work
that prepares the next honest runtime attempt without reopening the direct
`Page.zig` plus `win32_backend.zig` patch too early.

## Use Issue #11 For

- saved snapshot restore and restored-checkout readiness
- restored helper-surface sync checks for already-restored snapshots
- saved archive integrity checks
- saved Rust archive candidate discovery and staged-toolchain reuse
- saved Zig archive candidate discovery and restore selection
- offline dependency staging
- saved Rust toolchain reuse
- branch-compatible Zig recovery under `../toolchains`
- Linux or WSL helper-route work that reduces friction before the next real
  issue `#3` runtime re-entry

## Keep Using These Branch-Local Surfaces

- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
- `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_issue3_restored_helper_surface_sync.py`
- `scripts/check_linux_build_readiness.py`

## Working Rule

If a scheduled run is still blocked on publication safety or a branch-compatible
Linux or WSL validation toolchain, leave the progress update on issue `#11`
instead of retrying comments on issue `#2` or issue `#3`.

If the immediate slice is about surfacing the practical shared roots for a
nested or restored checkout before later helpers trust their defaults, keep
`docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md` visible, fail fast on its route
surface, print the compact route, and run `scripts/check_issue3_workspace_context.py`
before rebuilding `memory`, `toolchains`, `saved-archives`, `offline-deps`, or
fallback-Zig overrides by hand.

If the immediate slice is about trusting an already-restored checkout as its
own helper root, keep `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
visible, fail fast on its route surface, run the narrower sync check before
saved-memory or build-readiness follow-up helpers are trusted from the restored
root, and use the `--sync-only` refresh route when the helper surface is stale.

If the immediate slice is about choosing the exact saved Rust archive before
toolchain restore, keep `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
visible, fail fast on its route surface, surface the staged-toolchain candidate
helper before unpacking the archive again, and print the saved-Rust archive
candidate route before falling back to the raw restore ladder.

If the immediate slice is about reusing or restoring the saved Rust `1.79.0`
toolchain, keep `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md` visible,
fail fast on the saved-Rust build-readiness bridge surface before the broader
Linux or WSL build-readiness route is trusted, surface the staged-toolchain
candidate helper before unpacking the archive again, and reuse the surfaced
`PATH`, `CARGO`, and `RUSTC` exports from
`docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md` when the exact restore or export
surface is still needed.

If the immediate slice is about picking or restoring a saved Zig `0.15.x`
archive, keep `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md` visible,
surface the staged Zig candidate helper before unpacking the archive again,
surface `scripts/check_issue3_build_readiness_rerun.py` after a matching staged
toolchain appears so it can print the exact Linux or WSL rerun command, run the
matching-line gate after any staged restore, and surface the archive-restore
checker before broader readiness is trusted again.

If the immediate slice is about reusing a staged Zig candidate before archive
restore, fail fast on the narrower staged-Zig route first and print its compact
handoff before the broader saved-Zig or recovery routes are trusted:

```bash
bash ./scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
```

Only move back to issue `#3`-specific runtime commits after the environment
gates in `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` are actually green.

## Fail Fast On The Route Surface

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Surface The Workspace-Context Route First When The Layout Is Unusual

When the immediate issue `#11` work is about a nested or restored checkout whose
next helper would otherwise guess the wrong shared roots, fail fast on the
workspace-context route first:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
```

Keep the root-discovery helper visible before later saved-memory, saved-Rust,
saved-Zig, build-readiness, or Zig recovery routes are trusted:

```bash
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

Use `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached archive is not sitting under the nearest discovered
`agent_files` root and the follow-up routes need to inspect the same surfaced
path.

## Surface The Restored Helper-Surface Sync Route When Reusing An Existing Restore

When the immediate issue `#11` work is about trusting an already-restored
checkout as its own helper root, fail fast on the narrower helper-surface sync
route before later saved-memory, saved-archive, build-readiness, or runtime
follow-up helpers are trusted from that restored root:

```bash
bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh
bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh
```

Keep the narrower comparison helper visible before the route widens out again:

```bash
python ./scripts/check_issue3_restored_helper_surface_sync.py \
  --helper-root . \
  --restored-root ../browser-memory-snapshot
```

Use the in-place helper refresh when the restored checkout already exists and
the helper surface is stale:

```bash
bash ./scripts/linux/restore_saved_browser_snapshot.sh \
  --browser-root . \
  --helper-root . \
  --memory-root ../memory \
  --archive ../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip \
  --destination ../browser-memory-snapshot \
  --sync-only
```

## Surface The Saved Rust Bridge When Toolchain Reuse Is The Slice

When the immediate issue `#11` work is about restoring or reusing the saved
Rust `1.79.0` toolchain, fail fast on the saved-Rust build-readiness bridge
surface before the broader Linux or WSL build-readiness route is trusted:

```bash
bash ./scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_build_readiness_route.sh
```

If the exact saved-Rust restore or shell-export surface is still needed after
the bridge narrows the route, reopen the raw saved-Rust route directly:

```bash
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

Keep the staged-toolchain candidate helper visible before unpacking the archive
again:

```bash
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

## Surface The Saved Zig Route First When Archive Selection Is The Slice

When the immediate issue `#11` work is about choosing or restoring a saved Zig
`0.15.x` archive, fail fast on the saved-Zig route surface before trusting the
archive-selection route output:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
```

Keep the narrower staged-toolchain route visible when the immediate slice is
staged candidate reuse rather than saved-archive selection:

```bash
bash ./scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh
```

Keep the staged-toolchain candidate helper visible before unpacking the archive
again:

```bash
python ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .
```

Use `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached archive is not sitting beside the repo workspace and the
saved-Rust, saved-Zig, saved-Memory, build-readiness, or Zig recovery follow-up
helpers need to inspect the same surfaced archive path.

When a matching staged Zig candidate already exists, print the exact Linux or
WSL build-readiness rerun command before broader readiness is trusted again:

```bash
python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

After restoring a saved Zig candidate, fail fast on the matching-line gate and
the archive-restore surface before broader readiness is trusted again:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

## Print The Compact Handoff

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_progress_tracker_route.sh
```

Use `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached archive is not sitting beside the repo workspace and the
saved-Rust, saved-Memory, saved-Zig, build-readiness, and Zig recovery follow-up
routes all need to inspect the same surfaced archive path.
