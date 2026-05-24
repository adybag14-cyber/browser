# Issue #3 Saved Build Bootstrap Route

Use this note when a Linux or WSL run needs one compact path from the saved
Memory browser snapshot to the blocked issue `#3` runtime re-entry surface.

This route exists for the case where the environment is still too cold to trust
focused `zig build` or file-level runtime tests. Instead of reopening each
recovery helper one by one from memory, the bootstrap route keeps the synced
snapshot restore, saved-input checks, archive integrity check, offline-inputs
route, saved Rust route, Zig recovery route, and final runtime handoff on one
branch-local surface.

Companion helpers:

- `scripts/linux/check_issue3_saved_build_bootstrap_route_surface.sh`
- `scripts/linux/show_issue3_saved_build_bootstrap_route.sh`
- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- the saved repo archive and dependency bundles are present, but the next run
  still lacks a reusable restored checkout for Linux or WSL follow-up work
- the next run needs the exact command order for restore, integrity, offline
  inputs, Rust, Zig, and runtime re-entry on one compact helper surface
- the direct issue `#3` runtime fix is still blocked, but the run can still move
  the environment forward by reopening the saved bootstrap ladder cleanly

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_build_bootstrap_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_build_bootstrap_route.sh
```

If the repo root, Memory folder, restored checkout path, toolchains folder, or
offline dependency root live somewhere unusual, override the paths:

```bash
bash ./scripts/linux/show_issue3_saved_build_bootstrap_route.sh \
  --repo-root /path/to/browser \
  --memory-root /path/to/workspace/memory \
  --restored-checkout-root /path/to/browser-memory-snapshot \
  --saved-archives-root /path/to/memory/repo_archives/browser/dependencies \
  --toolchains-root /path/to/toolchains \
  --offline-deps-root /path/to/offline-deps
```

Use `--json` when another helper wants the route as structured output.

## What The Route Surfaces

The helper prints:

1. a synced saved-snapshot restore surface check for
   `restore_saved_browser_snapshot.sh --check-only`
2. the real synced restore command for the saved browser snapshot
3. the restored-checkout saved-Memory preflight command for
   `check_issue3_saved_memory_inputs.py`
4. the restored-checkout archive integrity command for
   `check_issue3_saved_archive_integrity.py`
5. the restored-checkout offline build-inputs route helper
6. the restored-checkout saved Rust route helper
7. the restored-checkout Zig recovery route helper
8. the restored-checkout runtime re-entry route helper

## Working Rules

- Run the bootstrap surface check first so missing docs or helper drift fails
  before the saved archives or restored checkout are blamed.
- Use the synced snapshot restore before the other route helpers so the restored
  checkout becomes its own follow-up root.
- Run the saved-Memory preflight before the archive integrity check when the run
  depends on the saved snapshot, dependency bundles, and optional fallback Zig
  archive.
- Run the archive integrity check before trusting the offline-inputs, saved
  Rust, or Zig recovery routes as evidence.
- Run the offline-inputs route before the saved Rust and Zig routes when sibling
  dependencies or `offline-deps` may still be missing.
- Run the runtime re-entry route only after the restored checkout has passed the
  saved-input, archive, offline-dependency, Rust, and Zig-line gates.
- Treat this route as the compact environment bootstrap for blocked issue `#3`
  reruns, not as proof that the direct `Page.zig` plus `win32_backend.zig`
  patch is ready to land yet.
