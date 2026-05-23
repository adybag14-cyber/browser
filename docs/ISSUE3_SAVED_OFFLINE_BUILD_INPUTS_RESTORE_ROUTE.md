# Issue #3 Saved Offline Build Inputs Restore Route

Use this note when the blocked issue `#3` Linux or WSL recovery path still
needs the saved offline dependency bundles restored from Memory before the
broader build-readiness helper or focused Zig commands can be trusted.

This route adds one Memory-default restore command on top of the existing
offline-input staging helper so future reruns do not have to rebuild the saved
archive arguments by hand.

Companion helpers:

- `scripts/linux/restore_saved_offline_build_inputs.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- the saved browser dependency archive, BoringSSL archive, and html5ever bundle
  are already present in Memory and the run wants one command with branch-local
  defaults
- `../zig-v8-fork`, `../boringssl-zig`, or `../offline-deps` still need to be
  restaged beside the repo workspace
- a run wants the exact check-only and restore commands on one helper surface
  before reopening saved Rust or Zig-line recovery

## Run The Memory Preflight First

From the browser repo root:

```bash
python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

This confirms that the saved repo snapshot, blocker file, and dependency
archives are still present before the restore command starts blaming the live
checkout.

## Run The Route

From the browser repo root:

```bash
bash ./scripts/linux/restore_saved_offline_build_inputs.sh --check-only
bash ./scripts/linux/restore_saved_offline_build_inputs.sh
```

If the checkout or saved dependencies live somewhere unusual, override the
paths:

```bash
bash ./scripts/linux/restore_saved_offline_build_inputs.sh \
  --browser-root /path/to/browser \
  --dependencies-root /path/to/memory/repo_archives/browser/dependencies \
  --offline-deps-root /path/to/offline-deps \
  --check-only
```

## What The Helper Does

The helper:

1. defaults the saved archive paths to `../memory/repo_archives/browser/dependencies`
2. reuses `scripts/linux/prepare_offline_build_inputs.sh` for the real staging
3. supports `--check-only` so the resolved archive inputs are visible before
   mutation
4. restores the offline dependency layout expected by `build.zig.zon`
5. prints the next saved-Rust, Zig-line, and readiness commands after staging

## Working Rules

- Run `python ./scripts/check_issue3_saved_memory_inputs.py --repo-root .`
  before the restore helper when the route depends on the saved Memory bundles.
- Use `--check-only` first when the saved archive paths or workspace layout may
  have drifted.
- Treat this helper as the Memory-default wrapper around
  `scripts/linux/prepare_offline_build_inputs.sh`, not a separate staging path.
- After staging succeeds, move to the saved Rust toolchain route and the Zig
  toolchain recovery route before trusting focused Zig output.
