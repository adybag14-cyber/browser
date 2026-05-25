# Issue #3 Saved Zig Archive Candidates Route

Use this note when the Linux or WSL headed runtime re-entry lane needs to prove
which saved Zig toolchain archive is the best branch-compatible restore
candidate before broader build-readiness work is retried.

This route exists to keep saved-archive discovery on a branch-local helper
surface instead of forcing future runs to hand-scan `repo_archives/browser` for
possible Zig bundles. It also keeps generic archive filenames on a safe helper
path, because the candidate helper can infer the Zig version from the archive's
top-level extracted directory when the filename alone is not descriptive
enough.

Companion helpers:

- `scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- no staged Zig candidate under `../toolchains` matches the branch's expected
  `0.15.x` line
- a run needs to know whether the saved dependency archive area already contains
  a real `0.15.x` toolchain archive before falling back to the attached `0.17`
  archive
- the visible saved archive filename is generic, so the branch-compatible Zig
  line has to be inferred from the archive layout instead of the filename alone
- a run wants the exact restore commands for the preferred saved Zig archive
  without rebuilding them by hand
- a route wants to fail fast if the saved-archive helper, restore helper, or
  branch-local note has drifted out of place

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh
```

Use `--json` when another helper wants the surfaced discovery metadata as
structured output.

The surface checker confirms that the branch-local note, saved-archive helper,
restore helper, and `build.zig.zon` are all in place before a run trusts the
candidate discovery output.

## Surface The Saved Zig Archive Candidates

After the surface check passes, run:

```bash
python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
```

Use `--json` when another helper wants the discovered archive list, preferred
saved archive, or restore commands as structured output.

That helper can still surface a valid `0.15.x` candidate when the saved archive
filename is generic, because it can infer the Zig version from the archive's
top-level extracted directory before ranking the preferred restore target.

## Restore The Preferred Saved Archive

When the helper reports a preferred saved archive, run its surfaced restore
commands in this order:

```bash
bash ./scripts/linux/restore_zig_toolchain_archive.sh --check-only ...
bash ./scripts/linux/restore_zig_toolchain_archive.sh ...
```

Keep `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md` open while restoring
that archive so the shared `../toolchains` staging path stays aligned with the
current workspace.

## Working Rules

- Run the saved-archive candidate surface check first so helper drift fails
  before the route blames missing toolchains.
- Prefer the saved archive candidate helper over ad hoc filename scanning when
  the saved archive name is generic or reused across multiple toolchain drops.
- Prefer a saved Zig `0.15.2` or other `0.15.x` archive over the attached
  fallback `0.17` bundle whenever one is available.
- Treat the attached Zig `0.17` bundle as a surfaced stopgap only, not as
  branch-compatible validation evidence.
- After staging the preferred saved archive under `../toolchains`, rerun the
  matching-line gate and then the broader Linux build-readiness helper before
  reopening the direct `Page.zig` plus `win32_backend.zig` runtime patch.
