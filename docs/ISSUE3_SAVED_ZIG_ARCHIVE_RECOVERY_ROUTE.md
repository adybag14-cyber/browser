# Issue #3 Saved Zig Archive Recovery Route

Use this note when the issue `#3` Linux or WSL re-entry lane still needs a real
Zig `0.15.x` archive, but the current workspace only clearly surfaces the
attached Zig `0.17` fallback bundle.

This route gives future runs one small helper surface for:

- checking the branch minimum Zig line from `build.zig.zon`
- searching the saved Memory dependency root for real Zig archives
- searching any explicitly provided extra archive roots before hand-building
  restore commands
- surfacing the attached fallback Zig archive when no matching saved archive is
  available
- printing the exact restore commands for either a real saved archive or the
  fallback route-discovery bundle

Companion helpers:

- `scripts/check_issue3_saved_zig_archive_recovery.py`
- `scripts/linux/show_issue3_saved_zig_archive_recovery_route.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`

## When To Use It

Use this route when any of these are true:

- the branch still expects Zig `0.15.2`, but no staged toolchain under
  `../toolchains` matches that line yet
- the saved Memory dependency bundle might now include a real Zig archive and
  the next run wants to find it before falling back to the attached Zig `0.17`
  archive
- the next run wants one helper that prints both the real-archive restore
  commands and the fallback route-discovery restore commands

## Run The Helper

From the browser repo root:

```bash
python ./scripts/check_issue3_saved_zig_archive_recovery.py --repo-root .
```

Use `--saved-archives-root` when the saved browser archives live somewhere other
than the default `../memory/repo_archives/browser` path.

Use `--extra-search-root` one or more times when another local directory should
also be searched for Zig archives before the route gives up on a real `0.15.x`
candidate.

Use `--json` when another helper needs the discovered archive list, preferred
restore commands, or fallback restore commands as structured output.

## Print The Route

If you want the compact route reminder instead of calling the Python helper
directly:

```bash
bash ./scripts/linux/show_issue3_saved_zig_archive_recovery_route.sh
```

That wrapper simply prints the saved-archive discovery command with the chosen
overrides already filled in.

## Working Rules

- Prefer a real Zig `0.15.x` archive when the helper surfaces one.
- Treat the attached Zig `0.17` archive as route-discovery input only.
- Use `restore_zig_toolchain_archive.sh` when the helper finds a matching real
  archive.
- Use `restore_issue3_fallback_zig_toolchain.sh` only when the helper does not
  find a real match but the next run still wants the fallback bundle staged for
  later route checks.
- Keep the direct `Page.zig` plus `win32_backend.zig` runtime patch blocked
  until the broader Zig toolchain recovery route has a branch-compatible line.
