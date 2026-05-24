# Issue #3 Build Recovery Bundle Route

Use this note when the direct issue `#3` runtime patch is still blocked by
environment recovery work and the next Linux or WSL run needs one compact
surface for the saved-input, offline-staging, Rust, and Zig recovery helpers.

This route does not replace the narrower helpers. It bundles them in a stable
order so the next run can reopen build readiness without rebuilding the command
chain by hand.

Companion docs and helpers:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/check_issue3_build_recovery_bundle_route_surface.sh`
- `scripts/linux/show_issue3_build_recovery_bundle_route.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`

## When To Use It

Use this route when any of these are true:

- the direct `Page.zig` plus `win32_backend.zig` runtime patch is still blocked
  on Linux or WSL toolchain or dependency recovery
- the saved Memory repo snapshot and dependency bundles are present, but the
  next run wants the ordered recovery commands on one branch-local surface
- a run needs to restage offline inputs, restore the saved Rust toolchain, and
  recover a branch-compatible Zig line before trusting focused Zig output again

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_build_recovery_bundle_route_surface.sh
```

Use `--json` when another helper wants the result as structured output.

## Print The Bundle Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_build_recovery_bundle_route.sh
```

Override the default paths when the checkout or saved artifacts live somewhere
unusual:

```bash
bash ./scripts/linux/show_issue3_build_recovery_bundle_route.sh \
  --repo-root /path/to/browser \
  --saved-archives-root /path/to/memory/repo_archives/browser/dependencies \
  --offline-deps-root /path/to/offline-deps \
  --toolchains-root /path/to/toolchains
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle is not sitting under
the default `../agent_files` location beside the repo workspace.

## What The Bundle Prints

The helper keeps these steps on one surface:

1. the fail-fast surface check for
   `scripts/linux/check_issue3_build_recovery_bundle_route_surface.sh`
2. the saved Memory input preflight for
   `scripts/check_issue3_saved_memory_inputs.py`
3. the saved-archive integrity preflight for
   `scripts/check_issue3_saved_archive_integrity.py`
4. the dedicated offline build-inputs route for
   `scripts/linux/show_issue3_offline_build_inputs_route.sh`
5. the saved Rust restore route for
   `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
6. the Zig line recovery route for
   `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
7. a lightweight `check_linux_build_readiness.py` preflight that keeps Zig
   probing skipped until the earlier restore steps are done
8. a full `check_linux_build_readiness.py` rerun that expects the saved
   archives and offline dependency layout to be staged
9. the handoff back to the Windows-first issue `#3` runtime re-entry helper
   once environment recovery stops being the blocker

## Working Rules

- Run the surface checker first so missing docs or helper drift fails before the
  route starts blaming archive or toolchain state.
- Keep the saved Memory input preflight and saved-archive integrity preflight
  ahead of the restore routes when the next run still depends on the saved repo
  snapshot and dependency bundles.
- Use the dedicated offline build-inputs route before rebuilding sibling
  dependency restore commands by hand.
- Use the saved Rust route before trusting host `cargo` or `rustc`.
- Use the Zig recovery route before treating the attached Zig `0.17` bundle as
  meaningful evidence for this branch.
- Treat the attached `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle
  as a surfaced fallback only, not as honest issue `#3` validation evidence for
  a branch that still expects Zig `0.15.x`.
- After the bundle route stops failing on archive presence, offline staging,
  Rust setup, or Zig-line mismatch, move back to the direct Windows runtime
  re-entry helper before widening out to larger replay.
