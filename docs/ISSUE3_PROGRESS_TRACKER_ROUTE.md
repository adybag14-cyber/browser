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
- offline dependency staging
- saved Rust toolchain reuse
- branch-compatible Zig recovery under `../toolchains`
- Linux or WSL helper-route work that reduces friction before the next real
  issue `#3` runtime re-entry

## Keep Using These Branch-Local Surfaces

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_linux_build_readiness.py`

## Working Rule

If a scheduled run is still blocked on publication safety or a branch-compatible
Linux or WSL validation toolchain, leave the progress update on issue `#11`
instead of retrying comments on issue `#2` or issue `#3`.

Only move back to issue `#3`-specific runtime commits after the environment
gates in `docs/ISSUE3_RUNTIME_REENTRY_GATES.md` are actually green.
