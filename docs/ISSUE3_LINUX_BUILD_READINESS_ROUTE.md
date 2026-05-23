# Issue #3 Linux Build-Readiness Route

Use this note when the direct issue `#3` runtime patch is still blocked on the
toolchain and offline dependency gate, but the run still has the saved Memory
archives available.

This is the Linux or WSL companion for the Windows-first runtime re-entry
helpers:

- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1`
- `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `scripts/linux/check_issue3_linux_build_readiness_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`

## Goal

Give the next writable checkout one branch-local route for:

- checking that the saved Memory repo snapshot, notes, blocker file, dependency
  archives, and optional fallback Zig bundle are still present
- checking that the Linux build-readiness note and helper surfaces still line up
- staging the offline sibling dependencies expected by `build.zig.zon`
- restoring the saved Rust `1.79.0` toolchain
- surfacing the attached fallback Zig archive location when only the builder-attached Zig `0.17` dev bundle is available
- surfacing staged Zig candidates under `../toolchains` before the fallback Zig
  `0.17` path is blamed for branch behavior
- rerunning the readiness helper before trusting focused Zig output

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_linux_build_readiness_route_surface.sh
```

Use `--json` when another helper needs the surface-check result as structured
output.

## Restore A Checkout First When Needed

If there is no reusable extracted checkout beside the workspace yet, print the
saved-browser-snapshot route before reopening Linux or WSL staging from the live
repo root:

```bash
bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh
```

That route keeps the saved snapshot surface check, the restore command, the
saved-Memory preflight, and the first build-readiness/runtime follow-up commands
on one branch-local helper surface.

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

## Reopen The Zig Line Before Trusting Fallback Zig

If the route still only sees the attached Zig `0.17` dev bundle, print the
toolchain recovery surface before treating that fallback as meaningful evidence:

```bash
bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh
```

That helper reads the branch minimum Zig line from `build.zig.zon`, checks any
staged `../toolchains` candidates it can probe, and prints the exact
`check_linux_build_readiness.py --zig ...` command to rerun once a matching
`0.15.x` toolchain is available.

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
2. A saved-browser-snapshot restore route using
   `scripts/linux/show_issue3_saved_browser_snapshot_route.sh` when no reusable
   checkout exists yet
3. A saved-Memory preflight using `scripts/check_issue3_saved_memory_inputs.py`
4. A Zig-line recovery helper using
   `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
5. A saved-archive preflight using `scripts/check_linux_build_readiness.py`
6. A `prepare_offline_build_inputs.sh --check-only` command for the offline
   dependency surface
7. A saved Rust `1.79.0` restore command
8. A PATH export that keeps the restored Rust toolchain ahead of any host Rust
9. The attached fallback Zig archive location when it is present beside the repo
   workspace, so runs can surface it without treating it as branch-compatible
   validation evidence
10. A full readiness command that expects the saved archives, offline deps, and
    prebuilt V8 archive to be staged before retrying `zig build`

## Working Rules

- If there is no extracted checkout beside the workspace, run
  `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh` before the
  broader readiness helper so the restore and its immediate follow-up commands
  stay on one helper surface.
- Run `python scripts/check_issue3_saved_memory_inputs.py --repo-root .` before
  the broader readiness helper when the replay depends on the saved archives in
  Memory.
- Run `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh` when
  the route still only shows the attached Zig `0.17` fallback or when multiple
  staged Zig candidates need a quick `0.15.x` decision.
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