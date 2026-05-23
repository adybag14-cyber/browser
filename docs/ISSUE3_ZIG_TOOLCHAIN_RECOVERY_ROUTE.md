# Issue #3 Zig Toolchain Recovery Route

Use this note when the direct issue `#3` runtime path is still blocked on Linux
or WSL because the saved fallback Zig bundle does not match the branch's minimum
Zig line.

This route exists to stop the next run from treating the attached Zig `0.17`
dev archive as if it were branch-compatible validation evidence for a checkout
that still expects Zig `0.15.2`.

Companion helper:

- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`

## When To Use It

Use this route when any of these are true:

- `check_linux_build_readiness.py` says the current `zig` executable is on the
  wrong major or minor line for this branch
- the only visible Zig bundle is the attached
  `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` fallback archive
- a run needs to decide whether a staged Zig toolchain under `../toolchains` is
  good enough to reopen the Linux or WSL build-readiness lane

## Print The Route

From the browser repo root:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

If the checkout or toolchains folder lives somewhere unusual, override the
paths:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh \
  --repo-root /path/to/browser \
  --toolchains-root /path/to/toolchains
```

Use `--json` when another helper wants the discovery result as structured
output.

## What The Route Surfaces

The helper prints:

1. the branch minimum Zig line from `build.zig.zon`
2. the staged `../toolchains` search root
3. the attached fallback Zig archive location when it is present beside the repo
   workspace
4. a lightweight discovery command for `scripts/check_linux_build_readiness.py`
5. every staged Zig candidate it can probe, including the version line and
   whether that candidate matches the branch's expected major/minor line
6. the exact full readiness command to rerun once a matching Zig candidate is
   available

## Working Rules

- Prefer a Zig `0.15.2` or other `0.15.x` toolchain for honest validation on
  this branch.
- Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only.
- Do not reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch
  until the matching-line readiness command stops reporting the environment as
  the blocker.
- If no `0.15.x` candidate exists yet, stay in build-readiness, docs, or helper
  work instead of turning a toolchain mismatch into a source regression theory.
