# Issue #3 Zig Toolchain Archive Restore Route

Use this note when the branch needs a real Zig `0.15.x` toolchain under
`../toolchains`, but the run only has an archive path and not an extracted
toolchain directory yet.

This route keeps the archive-restore step on one branch-local helper instead of
rebuilding `tar` or `unzip` commands by hand before the issue `#3` Linux or WSL
build-readiness helpers can see the candidate.

Companion helpers:

- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- a matching Zig `0.15.x` archive is available, but it is not staged under
  `../toolchains` yet
- the recovery route still reports no branch-compatible Zig candidate
- the run wants a check-only surface for where a Zig archive would extract
  before touching the filesystem

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh
```

Use `--json` when another helper needs the surface-check result as structured
output.

## Run The Helper

From the browser repo root:

```bash
bash ./scripts/linux/restore_zig_toolchain_archive.sh --archive /path/to/zig-0.15.2.tar.xz --check-only
```

If the toolchains root should live somewhere else, override it explicitly:

```bash
bash ./scripts/linux/restore_zig_toolchain_archive.sh \
  --browser-root /path/to/browser \
  --toolchains-root /path/to/toolchains \
  --archive /path/to/zig-0.15.2.tar.xz
```

Use `--json` when another helper wants the derived restore and follow-up paths
as structured output.

## What The Helper Does

The helper:

1. checks that the browser root and Zig archive exist
2. discovers the archive top-level folder for `.tar`, `.tar.gz`, `.tgz`,
   `.tar.xz`, or `.zip`
3. derives the destination under `../toolchains` by default
4. supports `--check-only` for a no-mutation surface check
5. extracts the archive and verifies that it produced a usable `zig` binary
6. prints the exact follow-up commands for the Zig recovery route and the Linux
   build-readiness helper

## Working Rules

- Run `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
  before the restore helper so route drift fails fast before toolchain staging
  starts.
- Prefer a Zig `0.15.2` or other `0.15.x` archive for honest validation on this
  branch.
- Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only,
  not as issue `#3` validation evidence.
- After restore, rerun
  `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh` so the
  current workspace can confirm the staged candidate and print the matching
  readiness command.
- Reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch only after
  the matching-line readiness helper stops reporting the environment as the
  blocker.
