# Issue #3 Saved Rust Toolchain Restore Route

Use this note when the blocked issue `#3` Linux or WSL recovery path still
needs the saved Rust `1.79.0` toolchain from Memory before the broader
build-readiness helper can be trusted.

This route keeps the saved Rust archive check, the restore command, and the
shell handoff on one branch-local surface so future reruns do not need to
rebuild the Rust staging path by hand.

Companion helpers:

- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/restore_saved_rust_toolchain.sh`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- the Linux or WSL build-readiness route is about to reuse the saved Memory
  archives and needs the saved Rust toolchain back on `PATH`
- `cargo` or `rustc` are missing, or the host Rust toolchain is not the saved
  branch companion expected by the offline issue `#3` route
- a run wants the exact restore and shell setup commands on one compact helper
  surface before reopening `zig build`

## Run The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh
```

If the checkout, Memory folder, or toolchain destination lives somewhere
unusual, override the paths:

```bash
bash ./scripts/linux/show_issue3_saved_rust_toolchain_route.sh \
  --browser-root /path/to/browser \
  --dependencies-root /path/to/memory/repo_archives/browser/dependencies \
  --toolchain-root /path/to/rust-1.79.0-x86_64-unknown-linux-gnu
```

Use `--json` when another helper wants the route as structured output.

## What The Route Surfaces

The helper prints:

1. the saved Rust archive location
2. a `--check-only` surface check for `restore_saved_rust_toolchain.sh`
3. the restore command for the saved Rust `1.79.0` archive
4. the exact `PATH`, `CARGO`, and `RUSTC` exports to reuse after restore
5. the matching `check_linux_build_readiness.py` preflight to rerun after the
   toolchain is restored

## Working Rules

- Run this route before blaming missing `cargo` or `rustc` on the source tree.
- Keep the saved Rust restore on this helper surface instead of rebuilding the
  tar extraction command by hand.
- Reuse the restored `PATH`, `CARGO`, and `RUSTC` values when rerunning the
  Linux or WSL build-readiness helper.
- Pair this route with `show_issue3_linux_build_readiness_route.sh` when the run
  still needs the saved archive, offline dependency, and Zig line surfaces in
  one ordered path.
