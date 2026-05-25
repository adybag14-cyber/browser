# Issue #3 Workspace-Context Route

Use this note when a restored checkout does not sit in the default sibling
layout expected by the Linux or WSL issue `#3` recovery helpers.

This route exists to surface the practical paths for:

- the shared `toolchains` directory
- the saved Memory browser archives
- the attached fallback Zig archive under `agent_files`
- the nearest shared offline dependency root
- the practical restored-checkout root when a saved snapshot was unpacked away
  from the default sibling layout

without rebuilding those paths by hand every time a checkout is restored deeper
than `/workspace/browser`.

## Companion Surfaces

- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `scripts/check_issue3_saved_rust_archive_candidates.py`
- `scripts/check_issue3_staged_rust_toolchain_candidates.py`

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
```

Use `--json` when another helper wants the route-surface result as structured
output.

## Print The Compact Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_workspace_context_route.sh
```

Use `--json` when another helper wants the resolved roots plus the follow-up
route and helper commands as structured output.

## Run The Helper

From the browser repo root:

```bash
python scripts/check_issue3_workspace_context.py --repo-root .
```

Use `--json` when another helper or a scheduled run wants the resolved paths as
structured output.

If the fallback Zig archive is not sitting under the nearest discovered
`agent_files` directory, provide it explicitly:

```bash
python scripts/check_issue3_workspace_context.py \
  --repo-root . \
  --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
```

## What The Helper Surfaces

The helper prints:

1. the current repo root
2. whether `build.zig.zon` is present
3. the nearest shared `toolchains` root it can find while walking up the
   workspace tree
4. the nearest saved browser-archives root under `memory/repo_archives/browser`
5. the nearest `agent_files` root
6. the fallback Zig archive path it resolved, if one exists
7. the nearest shared offline dependency root
8. the practical restored-checkout root
9. a ready-to-rerun `scripts/check_linux_build_readiness.py` command that uses
   the resolved roots
10. a ready-to-rerun issue `#11` progress-tracker route command
11. a ready-to-rerun saved Rust route command
12. a ready-to-rerun saved Rust archive candidates command
13. a ready-to-rerun staged Rust toolchain candidates command
14. a ready-to-rerun saved browser-snapshot route command
15. a ready-to-rerun Zig recovery route command
16. a ready-to-rerun Zig matching-line gate command
17. a ready-to-rerun saved Zig archive candidates command

## Working Rules

- Run this helper first when a restored checkout sits deeper than the default
  sibling layout and the next Linux or WSL readiness command would otherwise
  guess the wrong `toolchains`, `memory`, or `agent_files` root.
- Run the route surface check first when a scheduled run is about to trust the
  wrapper route instead of calling `check_issue3_workspace_context.py`
  directly.
- Treat the surfaced readiness command as the shortest honest handoff back to
  `scripts/check_linux_build_readiness.py`.
- Use the printed issue `#11` progress-tracker route command when the next rerun
  still needs a lower-volume status lane before reopening the direct runtime
  patch.
- Use the printed saved Rust route and candidate commands when the next rerun
  still needs to restore or reuse Rust before the broader Linux build-readiness
  route is trusted.
- Use the printed saved browser-snapshot, Zig recovery, and saved Zig archive
  candidates route commands when the next rerun still needs more than the raw
  readiness command.
- Keep using explicit overrides when the desired roots are outside the current
  workspace ancestry.
