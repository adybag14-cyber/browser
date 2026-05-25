# Issue #3 Saved Zig Archive Candidates Route

Use this note when the Linux or WSL re-entry lane needs to decide whether the
saved archives already contain a branch-compatible Zig `0.15.x` restore target
before the fallback Zig `0.17` bundle is staged or blamed for the next
readiness rerun.

This route keeps the saved-archive candidate discovery helper on its own compact
surface so future runs do not have to rebuild the same archive-selection steps
by hand.

## Companion Surfaces

- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`

## Use This Route When

- no staged Zig executable under `../toolchains` matches the branch minimum
  line from `build.zig.zon`
- the run needs to know whether the saved archives already include a Zig
  `0.15.x` restore target
- the next issue `#11` update should report saved-archive discovery work rather
  than direct runtime-file work

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
```

Use `--json` when another helper needs the route-surface result as structured
output.

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh
```

Use `--json` when another helper needs the saved-archive root, the branch
minimum Zig line, the preferred restore commands, or the fallback archive path
as structured output.

## Working Rules

- Run the route surface check first so missing docs or helper drift fails before
  the run trusts saved Zig archive discovery output.
- Run `python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
  before hand-picking a restore archive from the saved dependencies folder.
- Prefer an exact `0.15.2` archive when one exists, otherwise prefer the newest
  saved archive on the same `0.15.x` line.
- Keep the route under issue `#11` while the work is still about saved inputs,
  toolchain recovery, or Linux or WSL readiness gates.
- Move back to `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md` and the direct
  runtime re-entry notes only after a matching Zig archive is staged under
  `../toolchains`.
