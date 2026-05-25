# Issue #3 Saved Zig Archive Route

Use this note when the Linux or WSL issue #3 re-entry lane still needs a
branch-compatible Zig toolchain, and the next run wants to know whether Memory
already holds a matching saved archive before falling back to the attached Zig
`0.17` bundle.

Companion helpers:

- `scripts/linux/check_issue3_saved_zig_archive_route_surface.sh`
- `scripts/linux/show_issue3_saved_zig_archive_route.sh`
- `scripts/check_issue3_saved_zig_archives.py`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## Goal

Keep the saved-Zig decision short and branch-local:

1. fail fast if the saved-Zig route files drift
2. scan the saved archives root for Zig archives
3. compare each archive to the branch minimum Zig line from `build.zig.zon`
4. print the exact restore commands for the preferred matching archive
5. hand back to the broader Linux build-readiness route once the toolchain is staged

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_route_surface.sh
```

Use `--json` when another helper needs the result as structured output.

## Print The Route

```bash
bash ./scripts/linux/show_issue3_saved_zig_archive_route.sh
```

That route keeps the saved-archive root, toolchains root, surface check, and
discovery command on one compact helper surface.

## Run The Discovery Helper

```bash
python scripts/check_issue3_saved_zig_archives.py --repo-root .
```

The helper:

- reads the branch minimum Zig line from `build.zig.zon`
- normalizes `repo_archives/browser` to its `dependencies/` folder when needed
- discovers saved Zig archives such as `zig-x86_64-linux-0.15.7.tar.xz`
- classifies them as matching, older-than-minimum, mismatched-line, or unknown-version
- prints the exact `restore_zig_toolchain_archive.sh` commands for the preferred matching archive

If there is no saved matching archive yet, the helper fails cleanly and points
the next run at either a newly saved Zig `0.15.x` archive or a staged toolchain
under `../toolchains`.

## Working Rules

- Prefer a saved Zig `0.15.x` archive over the attached Zig `0.17` fallback whenever one is available.
- Use the printed `restore_zig_toolchain_archive.sh` commands instead of rebuilding archive extraction by hand.
- After restoring a matching Zig line, rerun the broader Linux build-readiness helper before reopening the direct runtime patch.
- Treat the attached Zig `0.17` archive as fallback input only, not as honest validation evidence for this branch.
