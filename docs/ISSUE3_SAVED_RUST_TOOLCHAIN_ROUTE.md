# Issue #3 Saved Rust Toolchain Restore Route

Use this note when the blocked issue `#3` Linux or WSL recovery path still
needs the saved Rust `1.79.0` toolchain from Memory before the broader
build-readiness helper can be trusted.

This route keeps the saved Rust archive check, the restore command, and the
shell handoff on one branch-local surface so future reruns do not need to
rebuild the Rust staging path by hand. It now defaults to the same restored
location used by the broader Linux build-readiness helper:
`../toolchains/rust-1.79.0` beside the repo workspace.

Companion helpers:

- `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
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

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Surface Saved Archive Candidates Before Restore

When the run wants to confirm which saved Rust archive should drive the restore
command, print the candidate summary first:

```bash
python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred archive, saved-archives
root, or restore commands as structured output.

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
  --toolchain-root /path/to/toolchains/rust-1.79.0
```

Use `--json` when another helper wants the route as structured output.

## What The Route Surfaces

The helper prints:

1. a fail-fast surface check command for
   `scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
2. a saved-archive candidate discovery command for
   `scripts/check_issue3_saved_rust_archive_candidates.py`
3. a `--check-only` surface check for `restore_saved_rust_toolchain.sh`
4. the restore command for the saved Rust `1.79.0` archive
5. the exact `PATH`, `CARGO`, and `RUSTC` exports to reuse after restore
6. the matching `check_linux_build_readiness.py` preflight to rerun after the
   toolchain is restored
7. the aligned default restore destination under `../toolchains/rust-1.79.0`
   so the saved-Rust route and the broader build-readiness route point at the
   same toolchain tree

## Working Rules

- Run `bash ./scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh`
  first so missing route docs or helper drift fails before the saved archive is
  blamed.
- Run `python ./scripts/check_issue3_saved_rust_archive_candidates.py --repo-root .`
  before hand-picking the saved Rust archive or rebuilding restore commands by
  hand.
- Run this route before blaming missing `cargo` or `rustc` on the source tree.
- Keep the saved Rust restore on this helper surface instead of rebuilding the
  tar extraction command by hand.
- Reuse the restored `PATH`, `CARGO`, and `RUSTC` values when rerunning the
  Linux or WSL build-readiness helper.
- Pair this route with `show_issue3_linux_build_readiness_route.sh` when the run
  still needs the saved archive, offline dependency, and Zig line surfaces in
  one ordered path.