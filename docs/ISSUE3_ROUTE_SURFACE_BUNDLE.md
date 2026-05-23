# Issue #3 Recovery Route Surface Bundle

Use this note when a run wants one fail-fast command that checks the full Linux
or WSL issue `#3` recovery helper chain before it restores a checkout, stages
toolchains, replays the build-readiness route, or reopens the direct
`Page.zig` plus `win32_backend.zig` patch.

Companion helpers:

- `scripts/linux/check_issue3_route_surface_bundle.sh`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`

## When To Use It

Use this bundle check when any of these are true:

- the next run is about to rely on the saved-browser-snapshot restore route
- the next run needs the Linux or WSL build-readiness route before retrying the
  direct runtime patch
- the next run suspects helper drift more than source drift and wants one quick
  branch-local answer before replaying longer restore or toolchain steps

## Run The Bundle Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_route_surface_bundle.sh
```

Use `--json` when another helper wants the summary as structured output.

## What The Bundle Checks

The helper runs these surface checks in order:

1. `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
2. `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
3. `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
4. `scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh`

Each sub-check still owns the detailed failure output for its own route. The
bundle helper only answers whether the full Linux or WSL recovery chain is still
present and aligned.

## Working Rules

- If the bundle check fails, rerun the failing surface check directly and repair
  the helper or doc drift before trusting restore, toolchain, or runtime output.
- If the bundle check passes, move on to the saved-browser-snapshot route, the
  Linux or WSL build-readiness route, or the direct runtime route according to
  the current blocker.
- Treat this bundle as a route-surface guard only. It does not prove that the
  toolchain, offline dependencies, or direct issue `#3` runtime patch are green.
