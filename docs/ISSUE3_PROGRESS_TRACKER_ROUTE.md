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
- offline dependency staging
- saved Rust toolchain reuse
- branch-compatible Zig toolchain recovery under `../toolchains`
- Linux/WSL helper routes that unblock the next real issue `#3` runtime re-entry

## Keep Using These Branch-Local Surfaces

- `scripts/linux/check_issue3_progress_tracker_route_surface.sh`
- `scripts/linux/show_issue3_progress_tracker_route.sh`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/check_issue11_saved_memory_helper_contract.py`
- `scripts/check_issue11_reentry_inventory_consistency.py`
- `scripts/check_issue11_toolchains_root_candidates.py`
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

If the immediate slice is about choosing between visible `toolchains/` and
hidden `.toolchains/` roots before later Linux or WSL helpers trust a guessed
default, keep the toolchains-root candidate helper visible first:

```bash
python ./scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use its surfaced `--toolchains-root` override before rerunning saved-Rust,
build-readiness rerun, matching-line, Linux build-readiness, or Zig recovery
helpers from the same workspace layout.

If the immediate slice is about trusting an already-restored checkout as its
own helper root, keep `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
visible, fail fast on its route surface, run the narrower sync check before
saved-memory or build-readiness follow-up helpers are trusted from that restored
root, and use the `--sync-only` refresh route when the helper surface is stale.

If the immediate slice is about choosing the exact saved Rust archive before
toolchain restore, keep `docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md`
visible, fail fast on its route surface, surface the staged-toolchain
candidate helper before unpacking the archive again, and print the saved-Rust
archive candidate route before falling back to the raw restore ladder.

If the immediate slice is about reusing a staged Rust candidate before any
archive restore, fail fast on the narrower staged-Rust route first and print
its compact handoff before the broader saved-Rust archive or build-readiness
bridge routes are trusted:

```bash
bash ./scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh
bash ./scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh
```

Keep the staged-toolchain candidate helper visible before unpacking the archive
again:

```bash
python ./scripts/check_issue3_staged_rust_toolchain_candidates.py --repo-root .
```

If the immediate slice is about reusing or restoring the saved Rust `1.79.0`
toolchain, keep `docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md` visible,
fail fast on the saved-Rust build-readiness bridge surface before the broader
Linux or WSL build-readiness route is trusted, surface the staged-toolchain
candidate helper before unpacking the archive again, and reuse the surfaced
`PATH`, `CARGO`, and `RUSTC` exports from
`docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md` when the exact restore or export
surface is still needed.

When that Rust-first slice is running from a nested or restored checkout and the
run wants one branch-local command that surfaces the practical helper, Memory,
agent-files, and restored-checkout roots before the saved-memory preflight
widens into Rust archive selection or restore work, keep the nested-workspace
rerun helper visible:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
```

Use the quick-presence variant when the run only needs the routed saved-memory
presence check before the Rust bridge widens:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
  --skip-archive-integrity-check
```

## Check The Tracker-Specific Helper Surface Before Trusting The Wider Ladder

When the immediate issue `#11` slice is about whether a checkout still carries
the newer tracker-specific helpers, fail fast on the tracker surface before the
broader restore, saved-memory, or build-readiness routes are trusted:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
python ./scripts/check_issue11_saved_memory_helper_contract.py --repo-root .
python ./scripts/check_issue11_reentry_inventory_consistency.py --repo-root .
```

Keep the existing build-readiness rerun helper visible when a compatible staged
Zig candidate should already exist and the next question is the exact honest
Linux or WSL readiness command to run:

```bash
python ./scripts/check_issue3_build_readiness_rerun.py --repo-root .
```

Use the saved-memory helper-contract checker before the broader saved-memory
preflight when the immediate slice is about whether a restored helper surface
still matches the live restore-helper sync inventory that issue `#11` now
expects:

```bash
python ./scripts/check_issue11_saved_memory_helper_contract.py --repo-root .
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

Use that helper after the saved-Zig candidate discovery route or a successful
workspace-aware readiness check so the next rerun command stays anchored to the
same shared `memory`, `toolchains`, `agent_files`, and `offline-deps` roots.

If the run wants those surfaced roots threaded into the saved-memory preflight
through one branch-local command before the tracker widens into saved-Rust,
saved-Zig, or broader build-readiness follow-ups, keep the nested-workspace
rerun helper visible on the same issue `#11` handoff:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh
```

Use the quick-presence variant when the route only needs the surfaced saved-
Memory presence check before later tracker follow-up helpers widen again:

```bash
bash ./scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh \
  --skip-archive-integrity-check
```

If the immediate slice has already narrowed to the saved-memory preflight, the
broader Linux or WSL build-readiness ladder, or the Zig-line recovery follow-up,
keep their compact route printers visible on the same issue `#11` handoff:

```bash
bash ./scripts/linux/show_issue3_saved_memory_inputs_route.sh
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

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

## Comment Templates

When issue `#11` is the active progress log, keep the start and completion
updates compact so scheduled reruns leave the same fields the route printer and
surface checker expect:
