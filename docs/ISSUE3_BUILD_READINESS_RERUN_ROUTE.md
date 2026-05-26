# Issue #3 Build-Readiness Rerun Route

Use this note when the Linux or WSL headed runtime re-entry lane already has a
branch-compatible staged Zig candidate and needs the exact saved-archive-aware
`check_linux_build_readiness.py` rerun command without rebuilding it by hand.

This route exists to keep the final readiness rerun on a branch-local helper
surface after the saved Zig archive route or the staged Zig candidate helper has
already narrowed the toolchain choice.

Companion helpers:

- `scripts/linux/check_issue3_build_readiness_rerun_route_surface.sh`
- `scripts/linux/show_issue3_build_readiness_rerun_route.sh`
- `scripts/check_issue3_build_readiness_rerun.py`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- `scripts/check_issue3_staged_zig_toolchain_candidates.py` already surfaces a
  matching Zig `0.15.x` candidate under `../toolchains`
- `scripts/linux/check_issue3_zig_toolchain_match.sh` passes, but the next run
  still needs the exact broader readiness command before trusting Linux or WSL
  validation output
- the run wants one compact helper surface for the staged Zig candidate check,
  the matching-line gate, the exact readiness rerun command, and the fallback
  path back to the broader Zig recovery route

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_build_readiness_rerun_route_surface.sh
```

Use `--json` when another helper wants the surfaced route metadata as structured
output.

## Print The Exact Rerun Route

After the surface check passes, run:

```bash
bash ./scripts/linux/show_issue3_build_readiness_rerun_route.sh
```

Use `--json` when another helper wants the staged-candidate command, the
matching-line gate, or the exact `check_linux_build_readiness.py` rerun command
as structured output.

## Working Rules

- Run the route surface check first so note drift or helper drift fails before a
  scheduled run trusts the printed rerun command.
- Surface the staged Zig candidate helper before the rerun helper so a matching
  staged toolchain is visible on the same branch-local route.
- Run the matching-line gate before the rerun helper so the same shared
  `../toolchains` root has to prove a real `0.15.x` candidate exists.
- Use `scripts/check_issue3_build_readiness_rerun.py` to print the exact
  saved-archive-aware `check_linux_build_readiness.py` command once the staged
  Zig line is known.
- Keep `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md` visible when this slice is still
  part of the environment-gated issue `#11` lane.
- Return to `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md` when no matching
  staged Zig candidate is available yet.
- Return to `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md` once the rerun command
  is settled and the broader Linux or WSL helper ladder is the next step again.
