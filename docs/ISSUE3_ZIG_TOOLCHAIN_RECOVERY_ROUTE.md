# Issue #3 Zig Toolchain Recovery Route

Use this note when the direct issue `#3` runtime path is still blocked on Linux
or WSL because the saved fallback Zig bundle does not match the branch's minimum
Zig line.

This route exists to stop the next run from treating the attached Zig `0.17`
dev archive as if it were branch-compatible validation evidence for a checkout
that still expects Zig `0.15.2`.

Companion helpers:

- `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
- `scripts/linux/check_issue3_zig_toolchain_match.sh`
- `scripts/check_issue3_saved_zig_archive_candidates.py`
- `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
- `scripts/linux/show_issue3_zig_toolchain_recovery_route.sh`
- `scripts/linux/restore_issue3_fallback_zig_toolchain.sh`
- `scripts/linux/restore_zig_toolchain_archive.sh`
- `scripts/check_linux_build_readiness.py`
- `docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md`
- `scripts/linux/check_issue3_workspace_context_route_surface.sh`
- `scripts/linux/show_issue3_workspace_context_route.sh`
- `scripts/check_issue3_workspace_context.py`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
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
- a run needs a branch-local list of saved Zig archives before choosing a real
  `0.15.x` restore candidate
- the checkout sits deeper than the default sibling layout and the next recovery
  or archive-restore helper would otherwise guess the wrong `toolchains`,
  `saved-archives`, `offline-deps`, or fallback-archive roots

## Run The Surface Check First

From the browser repo root:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh
```

Use `--json` when another helper wants the surface-check result as structured
output.

## Fail Fast On The Matching Line

After the route surface passes, run the dedicated matching-line gate before a
broader Linux or WSL readiness rerun trusts the staged toolchains directory:

```bash
bash ./scripts/linux/check_issue3_zig_toolchain_match.sh
```

Use `--json` when another helper wants the staged-candidate result as structured
output.

This helper passes only when at least one staged Zig executable under
`../toolchains` matches the branch's expected `0.15.x` line. When the only
visible input is the attached `0.17` fallback archive, the helper fails fast
and points the run back at the broader recovery route instead of treating that
fallback as honest validation evidence.

## Surface Workspace Roots First When Layout Is Unusual

If the checkout was restored deeper than the default sibling layout, or the next
recovery step would otherwise have to guess shared workspace roots, surface the
resolved paths first:

```bash
bash ./scripts/linux/check_issue3_workspace_context_route_surface.sh
bash ./scripts/linux/show_issue3_workspace_context_route.sh
python ./scripts/check_issue3_workspace_context.py --repo-root .
```

Use the printed workspace-context output to decide whether the next Zig recovery
or archive-restore command should keep its defaults or be rerun with explicit
`--toolchains-root`, `--saved-archives-root`, `--offline-deps-root`, or
`--fallback-zig-archive` overrides.

## Surface Saved Archive Candidates Before Restore

When no matching candidate is staged yet but saved dependency archives are
available, print the saved Zig archive discovery result before choosing a
restore target:

```bash
python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .
```

Use `--json` when another helper wants the saved-archive candidate list, the
preferred `0.15.x` archive choice, or the exact restore commands as structured
output.

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

## Stage The Surfaced Fallback Archive When Needed

When the route can see the attached fallback archive but there is still no
staged Zig candidate under `../toolchains`, keep the fallback restore on its own
branch-local helper surface first:

```bash
bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh --check-only
bash ./scripts/linux/restore_issue3_fallback_zig_toolchain.sh
```

That helper stages the attached `0.17` archive under the shared toolchains area
so the recovery route can probe it consistently on later reruns.

Use `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`,
`bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`, and
`restore_zig_toolchain_archive.sh` instead when a real Zig `0.15.x` archive is
available and the next run wants to stage that matching line under
`../toolchains` before rerunning recovery.

## What The Route Surfaces

The helper prints:

1. a fail-fast surface check command for
   `scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
2. a dedicated matching-line gate for
   `scripts/linux/check_issue3_zig_toolchain_match.sh`
3. a saved-archive candidate discovery command for
   `scripts/check_issue3_saved_zig_archive_candidates.py`
4. a fail-fast archive-restore surface check command for
   `scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
5. the branch minimum Zig line from `build.zig.zon`
6. the staged `../toolchains` search root
7. the attached fallback Zig archive location when it is present beside the repo
   workspace
8. a lightweight discovery command for `scripts/check_linux_build_readiness.py`
9. a fallback archive staging section that reuses
   `scripts/linux/restore_issue3_fallback_zig_toolchain.sh` when the attached
   archive exists but is not staged yet
10. every staged Zig candidate it can probe, including the version line and
    whether that candidate matches the branch's expected major/minor line
11. the preferred saved-archive restore surface-check and restore commands when a
    real `0.15.x` Zig archive is already visible under the saved dependencies
12. the exact full readiness command to rerun once a matching Zig candidate is
    available

## Working Rules

- Run `bash ./scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh`
  first so missing docs or helper drift fails before the route blames the
  fallback Zig bundle.
- Run the workspace-context route first when the checkout sits deeper than the
  default sibling layout or the next recovery helper would otherwise guess the
  wrong `toolchains`, `saved-archives`, `offline-deps`, or fallback-archive
  roots.
- Run `bash ./scripts/linux/check_issue3_zig_toolchain_match.sh` right after the
  route surface check so the staged toolchains directory has to prove a real
  `0.15.x` candidate exists before the broader Linux or WSL readiness helper is
  trusted again.
- Run `python ./scripts/check_issue3_saved_zig_archive_candidates.py --repo-root .`
  before hand-picking a saved Zig archive so the preferred `0.15.x` restore path
  stays on a branch-local helper surface.
- Run `bash ./scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
  before restaging a real Zig archive so route drift fails fast before toolchain
  staging starts.
- Prefer a Zig `0.15.2` or other `0.15.x` toolchain for honest validation on
  this branch.
- Treat the attached Zig `0.17` dev bundle as a surfaced fallback input only.
- If the route still shows no staged candidate but the attached fallback archive
  is present, use `restore_issue3_fallback_zig_toolchain.sh` before rebuilding
  tar extraction commands by hand.
- If a real Zig `0.15.x` archive becomes available, use
  `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`, run the archive-restore
  surface checker, use `check_issue3_saved_zig_archive_candidates.py` to select
  the preferred saved archive, and then use `restore_zig_toolchain_archive.sh`
  to stage it under `../toolchains` before reopening the broader readiness
  helper.
- Do not reopen the direct `Page.zig` plus `win32_backend.zig` runtime patch
  until the matching-line readiness command stops reporting the environment as
  the blocker.
