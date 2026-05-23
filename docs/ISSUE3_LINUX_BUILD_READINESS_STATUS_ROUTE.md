# Issue #3 Linux Build-Readiness Status Route

Use this note when issue `#3` is still blocked on Linux or WSL build readiness
and the next run needs one truthful snapshot of the current recovery state
before choosing another helper route.

This companion is for the moment after the saved-archive and route printers
exist, but before you know whether the workspace actually has the saved Memory
inputs, a matching Zig line, a restored Rust `1.79.0` toolchain, and offline
dependencies staged.

Companion helpers:

- `scripts/check_issue3_linux_build_readiness_status.py`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_linux_build_readiness.py`
- `scripts/linux/show_issue3_linux_build_readiness_route.sh`
- `scripts/linux/show_issue3_saved_rust_toolchain_route.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`

## Run It

From the browser repo root:

```bash
python scripts/check_issue3_linux_build_readiness_status.py --repo-root .
```

Use `--json` when another helper needs the result as structured output.

## What It Checks

The helper stays read-only and reports:

1. whether the saved Memory repo snapshot, notes, blocker file, and dependency
   archives are present
2. whether the fallback attached Zig archive is visible beside the workspace
3. whether the default `zig` on `PATH` matches the branch's `0.15.x` line
4. which staged Zig candidates under `../toolchains` can be probed and whether
   any of them match the branch line
5. whether the restored Rust `1.79.0` toolchain under `../toolchains/rust-1.79.0`
   is actually runnable
6. whether `../offline-deps/{brotli,zlib,nghttp2,curl}` and a prebuilt
   `libc_v8_*.a` archive are already staged
7. the most relevant next branch-local command based on the current snapshot

## Working Rules

- Run this helper when the route printers exist but the next run still needs a
  factual snapshot of what is staged right now.
- If the helper says `saved-memory-inputs-missing`, reopen
  `scripts/check_issue3_saved_memory_inputs.py` before touching Zig or Rust.
- If the helper says `no-branch-compatible-zig`, reopen
  `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh` instead of
  treating Zig `0.17` fallback failures as source evidence.
- If the helper says `saved-rust-toolchain-not-restored`, reopen
  `scripts/linux/show_issue3_saved_rust_toolchain_route.sh` before trusting host
  `cargo` or `rustc`.
- If the helper says `offline-deps-not-staged`, reopen
  `scripts/linux/show_issue3_linux_build_readiness_route.sh` before retrying the
  broader readiness helper.
- Only reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch after
  this snapshot and the broader readiness helper both stop reporting the
  environment as the blocker.
