# Issue #11 Toolchains-Root Candidates Route

Use this note when Linux or WSL re-entry work has already narrowed to the
staged toolchains root and the next rerun should stop guessing between
`toolchains/` and `.toolchains/`.

This route gives the issue `#11` environment-readiness lane one compact handoff
for:

- surfacing the preferred shared toolchains root above the current checkout
- warning when both visible and hidden toolchains roots exist
- threading the preferred `--toolchains-root` override into the next workspace,
  saved-memory, readiness, and Zig recovery helpers
- keeping the nested-workspace saved-memory preflight and the Zig recovery route
  pointed at the same staged-toolchain surface

## Companion Surfaces

- `scripts/linux/check_issue11_toolchains_root_candidates_route_surface.sh`
- `scripts/linux/show_issue11_toolchains_root_candidates_route.sh`
- `scripts/check_issue11_toolchains_root_candidates.py`
- `scripts/check_issue3_workspace_context.py`
- `scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue11_toolchains_root_candidates_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue11_toolchains_root_candidates_route.sh
```

Use `--json` when another helper wants the preferred toolchains root plus the
ready-to-rerun follow-up commands as structured output.

## Run The Helper

From the browser repo root:

```bash
python scripts/check_issue11_toolchains_root_candidates.py --repo-root .
```

Use `--helper-root` when the current repo root is a restored checkout and the
follow-up helpers still need to come from a live helper checkout.

Use `--json` when another helper wants the preferred toolchains root, warnings,
or ready-to-rerun commands as structured output.

## What The Route Surfaces

The route keeps these outputs on one compact handoff:

1. the current repo root and helper root
2. the visible `.toolchains` candidate, if present
3. the visible `toolchains/` candidate, if present
4. the preferred shared toolchains root for the next rerun
5. a ready-to-rerun workspace-context helper command
6. a ready-to-rerun issue `#11` nested-workspace saved-memory preflight command
7. a ready-to-rerun Linux build-readiness command with the preferred
   `--toolchains-root` already filled in
8. a ready-to-rerun Zig recovery route command with the preferred
   `--toolchains-root` already filled in

## Working Rules

- Run this route before broader Linux or WSL reruns when both `.toolchains` and
  `toolchains/` may exist above the checkout.
- Treat the surfaced `--toolchains-root` override as the shared handoff for the
  next saved-memory preflight, readiness rerun, and Zig recovery command from
  the same workspace layout.
- Keep the workspace-context helper visible when the checkout sits deeper than
  the default sibling layout and the next rerun still needs the practical shared
  roots surfaced first.
- Keep the nested-workspace saved-memory preflight visible when the next rerun
  needs the resolved helper, Memory, agent-files, and restored-checkout roots
  threaded through one branch-local wrapper before Rust or Zig follow-up work
  widens again.
- Keep the Zig recovery route visible when the toolchains-root question is
  settled but the branch-compatible Zig `0.15.x` line is still missing.
