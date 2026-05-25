# Issue #3 Linux Build-Readiness Re-entry Bridge

Use this note when the Linux or WSL issue `#11` lane needs one compact command
that combines the broader build-readiness check with the saved Zig archive
candidate helper before the direct headed runtime patch is reopened.

This bridge exists for the re-entry gap between the large route notes and the
narrow helper output. Instead of reading the broader Linux route and the
saved-Zig route separately, the bridge helper runs both underlying checks and
surfaces one combined next step:

- reuse a staged matching Zig toolchain when one already exists under
  `../toolchains`
- surface the preferred saved Zig archive restore commands when a branch-
  compatible `0.15.x` archive is already available
- fall back to the broader readiness helper guidance when neither of those
  paths is ready yet

Companion helpers:

- `scripts/check_issue3_linux_build_readiness_reentry.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`

## When To Use It

Use the bridge when any of these are true:

- the immediate issue `#11` slice is still Linux or WSL environment recovery,
  not a direct `Page.zig` or `win32_backend.zig` patch
- the run wants the exact next toolchain step without manually comparing the
  output of `scripts/check_linux_build_readiness.py` and
  `scripts/check_issue3_saved_zig_archive_candidates.py`
- the route needs to know whether it should reuse a staged Zig candidate,
  restore a saved `0.15.x` archive, or stay on the broader readiness lane

## Run The Bridge

From the browser repo root:

```bash
python ./scripts/check_issue3_linux_build_readiness_reentry.py \
  --repo-root . \
  --expect-saved-archives \
  --expect-offline-deps \
  --require-prebuilt-v8
```

Use `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`
when the attached fallback archive is not sitting beside the repo workspace and
all Linux or WSL follow-up helpers should inspect the same surfaced archive
path.

Use `--json` when another helper wants the combined readiness payload,
individual helper payloads, or the bridge's `combined_next_step` as structured
output.

## What The Bridge Surfaces

The helper returns or prints:

1. the current status from `scripts/check_linux_build_readiness.py`
2. the current status from `scripts/check_issue3_saved_zig_archive_candidates.py`
3. the current branch minimum Zig line
4. any staged matching Zig candidates already available under `../toolchains`
5. the preferred saved Zig archive and exact restore commands when a branch-
   compatible saved archive is available
6. one `combined_next_step` that tells the run whether to reuse a staged
   toolchain, restore a saved archive, or stay on the broader readiness route

## Working Rules

- Keep issue `#11` as the progress tracker while this bridge is still talking
  about saved archives, toolchain staging, or Linux or WSL readiness gates.
- Treat the bridge as a decision helper for the environment lane, not as proof
  that the direct headed runtime patch is ready to reopen.
- If the bridge surfaces a staged matching Zig candidate, rerun the broader
  readiness helper with `--zig <candidate>` before trusting later runtime
  evidence.
- If the bridge surfaces saved archive restore commands, run the `restore_check`
  command first and then the real restore command before rerunning readiness.
- If the bridge still falls back to the broader readiness guidance, stay on the
  Linux or WSL helper chain described in
  `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`.
