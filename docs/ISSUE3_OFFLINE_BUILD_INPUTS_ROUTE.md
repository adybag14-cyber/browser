# Issue #3 Offline Build Inputs Route

Use this note when the blocked issue `#3` Linux or WSL recovery path still
needs the saved offline build inputs staged before the broader build-readiness
helper or any focused Zig command can be trusted.

This route keeps the saved-Memory preflight, the offline-input surface check,
the raw `prepare_offline_build_inputs.sh` commands, and the immediate
post-staging follow-up checks on one branch-local surface so future reruns do
not have to rebuild the archive wiring by hand.

Companion helpers:

- `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
- `scripts/linux/show_issue3_offline_build_inputs_route.sh`
- `scripts/linux/prepare_offline_build_inputs.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- the saved browser dependency archive and BoringSSL archive are present in
  Memory, but `../zig-v8-fork`, `../boringssl-zig`, or `../offline-deps` are
  still missing beside the repo workspace
- the next Linux or WSL run wants the exact `--check-only` and restore commands
  on one compact helper surface before rerunning readiness
- a run needs to restage the offline inputs before the saved Rust route or Zig
  line recovery route can provide honest evidence

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_offline_build_inputs_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh
```

If the checkout or saved archives live somewhere unusual, override the paths:

```bash
bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh \
  --repo-root /path/to/browser \
  --saved-archives-root /path/to/memory/repo_archives/browser/dependencies \
  --offline-deps-root /path/to/offline-deps
```

Use `--json` when another helper wants the route as structured output.

## What The Route Surfaces

The helper prints:

1. a fail-fast surface check command for
   `scripts/linux/check_issue3_offline_build_inputs_route_surface.sh`
2. the saved-Memory preflight command for
   `scripts/check_issue3_saved_memory_inputs.py`
3. the exact `prepare_offline_build_inputs.sh --check-only` command for the
   saved browser dependency, BoringSSL, and optional html5ever archives
4. the real restore command that stages `../zig-v8-fork`, `../boringssl-zig`,
   and `../offline-deps`
5. the saved Rust toolchain route and Zig toolchain recovery route that should
   follow once the offline inputs are staged
6. the post-staging `check_linux_build_readiness.py` rerun that confirms the
   saved archives and offline dependency layout before focused Zig work resumes

## Working Rules

- Run the surface check first so missing docs or helper drift fails before the
  route starts blaming archive or dependency state.
- Run `python scripts/check_issue3_saved_memory_inputs.py --repo-root .` before
  the restore commands when the route depends on the saved repo snapshot and
  dependency bundles in Memory.
- Keep the raw restore command on this helper surface instead of rebuilding the
  archive arguments by hand.
- Treat this route as the offline dependency staging step that sits between the
  saved-Memory preflight and the saved Rust or Zig-line recovery routes.
- Do not treat missing `../offline-deps` or sibling dependency folders as a
  source regression before this route has been replayed.
- Do not treat fallback Zig `0.17` failures in untouched branch files as issue
  `#3` evidence until this route, the saved Rust route, and the Zig-line route
  are all green.
