# Issue #3 Toolchains-Root Candidates Route

Use this note when the Linux or WSL headed runtime re-entry lane needs one
branch-local route for choosing between visible `toolchains/` and hidden
`.toolchains/` roots before later helpers trust a guessed default.

This route keeps the issue `#11` toolchains-root helper, the staged Rust and
Zig routes, the Linux build-readiness helper, the broader Linux build-readiness
route, the Zig recovery route, and the issue `#11` progress-tracker handoff on
one compact surface.

## Companion Surfaces

- `scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh`
- `scripts/linux/show_issue3_toolchains_root_candidates_route.sh`
- `scripts/check_issue11_toolchains_root_candidates.py`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh`
- `scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh`
- `scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh`
- `scripts/linux/show_issue3_saved_rust_build_readiness_route.sh`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- a nested or restored checkout can see both `.toolchains/` and `toolchains/`
- the next Linux or WSL helper needs an explicit `--toolchains-root` override
- a saved-Rust, staged-Rust, staged-Zig, Zig recovery, or build-readiness rerun
  should reuse the same surfaced root
- issue `#11` is still the active tracker for environment-readiness work

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_toolchains_root_candidates_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_toolchains_root_candidates_route.sh
```

Use `--json` when another helper wants the surfaced commands as structured
output.

## Run The Helper

From the browser repo root:

```bash
python ./scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use `--json` when another helper wants the preferred toolchains root and the
suggested follow-up commands as structured output.

## Working Rules

- Run the surface check first so missing route files fail before later reruns
  trust a guessed toolchains root.
- Use the toolchains-root helper before staged Rust, staged Zig, Zig recovery,
  or broader Linux build-readiness helpers so later commands can pass
  `--toolchains-root` explicitly.
- Keep the issue `#11` nested-workspace preflight visible when the route still
  needs the practical helper, Memory, and restored-checkout roots surfaced
  before later toolchain-specific reruns widen again.
- Keep the issue `#11` progress-tracker route visible when this slice is still
  about environment readiness rather than reopening the direct `Page.zig` plus
  `win32_backend.zig` runtime patch.
