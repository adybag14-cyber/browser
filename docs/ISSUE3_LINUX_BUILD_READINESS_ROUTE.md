# Issue #3 Linux Build-Readiness Route

Use this note when the direct issue `#3` runtime patch is still blocked on the
toolchain and offline dependency gate, but the run still has the saved Memory
archives available.

This is the Linux or WSL companion for the Windows-first runtime re-entry
helpers:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/check_issue3_saved_memory_inputs.py`

## Goal

Give the next writable checkout one branch-local route for:

- checking that the saved Memory repo snapshot, notes, blocker file, dependency
  archives, and optional fallback Zig bundle are still present
- checking that the Linux build-readiness note and helper surfaces still line up
- staging the offline sibling dependencies expected by `build.zig.zon`
- restoring the saved Rust `1.79.0` toolchain
- surfacing the attached fallback Zig archive location when only the builder-attached Zig `0.17` dev bundle is available
- rerunning the readiness helper before trusting focused Zig output

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
```

Use `--json` when another helper needs the surface-check result as structured
output.

## Run The Saved-Memory Preflight Next

After the surface check passes, confirm the saved Memory repo snapshot,
dependency bundles, and fallback Zig surface before the broader Linux or WSL
readiness helper:

```bash
python scripts/check_issue3_saved_memory_inputs.py --repo-root .
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle lives somewhere other
than the default `../agent_files/` location beside the repo workspace.

## Run The Helper

After the saved-memory preflight passes, print the saved-archive-first route:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh
```

If the repo checkout is not sitting beside the saved Memory folder, override the
paths explicitly:

```bash
bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh \
  --repo-root /path/to/browser \
  --saved-archives-root /path/to/memory/repo_archives/browser \
  --rust-toolchain-dir /path/to/toolchains/rust-1.79.0
```

Use `--fallback-zig-archive` when the attached
`zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle lives somewhere other
than the default `../agent_files/` location beside the repo workspace.

Use `--json` when another helper needs the command set as structured output.

## What The Route Surfaces

The Linux route now stays short and ordered:

1. A fail-fast surface check using
   `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
2. A saved-Memory preflight using `scripts/check_issue3_saved_memory_inputs.py`
3. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
4. A `prepare_offline_build_inputs.sh --check-only` command for the offline
   dependency surface
5. A saved Rust `1.79.0` restore command
6. A PATH export that keeps the restored Rust toolchain ahead of any host Rust
7. The attached fallback Zig archive location when it is present beside the repo
   workspace, so runs can surface it without treating it as branch-compatible
   validation evidence
8. A full readiness command that expects the saved archives, offline deps, and
   prebuilt V8 archive to be staged before retrying `zig build`

## Working Rules

- Run `python scripts/check_issue3_saved_memory_inputs.py --repo-root .` before
  the broader readiness helper when the replay depends on the saved archives in
  Memory.
- Do not treat `403` fetch failures for `brotli`, `zlib`, `nghttp2`, or `curl`
  as source regressions before the offline restore route is staged.
- Do not treat Zig `0.17` fallback failures in untouched branch files as issue
  `#3` patch evidence.
- Treat the attached `zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz` bundle
  as a surfaced fallback artifact only; do not treat its Zig `0.17` dev line as
  honest issue `#3` validation evidence for this branch.
- Prefer a Zig `0.15.2` toolchain for honest branch validation after the saved
  archives and Rust toolchain are staged.
- Reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch only after
  this Linux or WSL route and the Windows reduced Google route agree that the
  environment is no longer the blocker.
