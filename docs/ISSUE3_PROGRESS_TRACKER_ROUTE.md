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
- `docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`
- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
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
- `scripts/check_linux_build_readiness.py`

## Working Rule

If a scheduled run is still blocked on publication safety or a branch-compatible
Linux or WSL validation toolchain, leave the progress update on issue `#11`
instead of retrying comments on issue `#2` or issue `#3`.

If the immediate slice is about reusing or restoring the saved Rust `1.79.0`
toolchain, keep `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md` visible, surface
the staged-toolchain candidate helper before unpacking the archive again, and
reuse its surfaced `PATH`, `CARGO`, and `RUSTC` exports before broader
build-readiness is trusted.

If the immediate slice is about picking or restoring a saved Zig `0.15.x`
archive, keep `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md` visible,
surface the staged Zig candidate helper before unpacking the archive again,
surface `scripts/check_issue3_build_readiness_rerun.py` after a matching staged
toolchain appears so it can print the exact Linux or WSL rerun command, run the
matching-line gate after any staged restore, and surface the archive-restore
checker before broader readiness is trusted again.

Only move back to issue `#3`-specific runtime commits after the environment
gates in `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` are actually green.

## Fail Fast On The Route Surface

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_progress_tracker_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Surface The Saved Rust Route First When Toolchain Reuse Is The Slice

When the immediate issue `#11` work is about restoring or reusing the saved
Rust `1.79.0` toolchain, fail fast on the saved-Rust route surface before the
broader Linux build-readiness route is trusted:

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

Use `--json` when another helper wants the issue number, issue URL, staged Zig
candidate command, build-readiness rerun command, start template, completion
template, and follow-up route commands as structured output.

## Compact Comment Shapes

Use this start format when the run is about to begin a Linux or WSL re-entry
helper slice:

```text
Goal: <state the exact Linux/WSL re-entry helper or environment gate work>
Started: <UTC timestamp>
Next: <state the first concrete helper, validation check, or branch-safe change you are about to make>
```

Use this completion format only after the branch commit exists:

```text
Achieved: <state what route, helper, or branch-safe re-entry improvement landed>
Completed: <UTC timestamp>
Commit: <commit sha>
Validation: <state the focused helper check, self-test, or follow-up route that now applies>
```